part of '../home_view.dart';

extension _HomeRoomManager on _HomeViewState {
  DateTime? _parseLatestFeedCreatedAt(dynamic raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Future<void> _fetchRooms() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _setStateForRoomManager(() => _loadingRoom = false);
        return;
      }
      final previousUnreadByRoom = <String, int>{
        for (final room in _myRooms)
          if (room['id'] is String)
            room['id'] as String: resolveRoomUnreadCount(room),
      };

      final responses = await _withNetworkTimeout(
        Supabase.instance.client
            .from('room_members')
            .select('room_id, role, rooms(invite_code, created_at)')
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('joined_at', ascending: true),
      );

      final List<Map<String, dynamic>> rooms = [];
      for (final r in responses) {
        final roomData = r['rooms'] as Map<String, dynamic>?;
        if (roomData != null) {
          final roomId = r['room_id'] as String?;
          rooms.add({
            'id': roomId,
            'invite_code': roomData['invite_code'],
            'role': r['role'],
            'room_created_at': roomData['created_at'],
            'unread_count': roomId != null
                ? (previousUnreadByRoom[roomId] ?? 0)
                : 0,
          });
        }
      }

      final roomIds = rooms
          .map((room) => room['id'])
          .whereType<String>()
          .toList(growable: false);
      final unreadCountsByRoom = <String, int>{};
      final senderIds = <String>{};
      if (roomIds.isNotEmpty) {
        final petSummaries = await _withNetworkTimeout(
          _fetchRoomPetSummaries(roomIds),
        );
        final feeds = await _withNetworkTimeout(_fetchRoomLatestFeeds(roomIds));
        final memberCounts = await _withNetworkTimeout(
          _fetchRoomMemberCounts(roomIds),
        );
        final unreadCounts = await _withNetworkTimeout(
          _fetchRoomUnreadCounts(roomIds, userId),
        );
        unreadCountsByRoom.addAll(unreadCounts);
        for (final room in rooms) {
          final roomId = room['id'] as String?;
          if (roomId != null) {
            room['member_count'] = memberCounts[roomId] ?? 0;
            room['unread_count'] = unreadCountsByRoom[roomId] ?? 0;
          }
          final summary = roomId == null ? null : petSummaries[roomId];
          if (summary != null) {
            room['pet_type'] = summary.petType;
            room['pet_health'] = summary.healthValue;
            room['pet_name'] = summary.petName;
            room['pet_level'] = summary.petLevel;
          }
          if (roomId != null && feeds.containsKey(roomId)) {
            final latest = feeds[roomId]!;
            if (latest.imageUrls.isNotEmpty) {
              room['latest_photo'] = latest.latestImageUrl;
              room['latest_photos'] = latest.imageUrls;
              room['latest_photo_captions'] = latest.imageCaptions;
              room['latest_photo_sender_ids'] = latest.imageSenderIds;
              room['latest_photo_message_ids'] = latest.imageMessageIds;
              room['latest_photo_created_ats'] = latest.imageSentAts
                  .map((entry) => entry?.toUtc().toIso8601String())
                  .toList(growable: false);
              room['latest_caption'] = latest.latestCaption;
              room['latest_sender_id'] = latest.latestSenderId;
              for (final senderId in latest.imageSenderIds) {
                if (senderId != null && senderId.isNotEmpty) {
                  senderIds.add(senderId);
                }
              }
            }
          }
        }
      }

      _syncMessageSubscriptions(roomIds);
      final sortedRooms = _applyLegacyRoomLocking(rooms);

      _setStateForRoomManager(() {
        _myRooms = sortedRooms;
        if (rooms.isEmpty) {
          _showRoomSelection = true;
          _roomSelectionId = null;
        } else {
          _roomSelectionId ??= _roomId ?? sortedRooms.first['id'] as String?;
        }
      });
      _evaluateBasicOnboardingAgainstCurrentData();
      _syncUnreadCountsProvider(sortedRooms);
      _syncAppIconBadge(rooms: sortedRooms);
      for (final senderId in senderIds) {
        unawaited(_ensureProfileSummary(senderId));
      }

      if (sortedRooms.isNotEmpty) {
        if (_roomId == null || !sortedRooms.any((r) => r['id'] == _roomId)) {
          _switchRoom(sortedRooms.first['id'] as String);
        }
      }
      await _cacheHomeBootstrapSnapshot();
      _processPendingNotificationIntent();
    } catch (_) {
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _loadingRoom = false);
      }
      _processPendingNotificationIntent();
    }
  }

  int _memberCountForRoom(String roomId) {
    for (final room in _myRooms) {
      if (room['id'] == roomId) {
        final raw = room['member_count'];
        if (raw is int) {
          return raw;
        }
        if (raw is num) {
          return raw.round();
        }
        break;
      }
    }
    return 0;
  }

  bool get _isSoloRoom {
    final roomId = _roomId;
    if (roomId == null) {
      return false;
    }
    return _memberCountForRoom(roomId) <= 1;
  }

  DateTime _legacyRoomSortTimestamp(Map<String, dynamic> room) {
    final createdAt = DateTime.tryParse(
      room['room_created_at'] as String? ?? '',
    );
    return createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  List<Map<String, dynamic>> _applyLegacyRoomLocking(
    List<Map<String, dynamic>> rooms,
  ) {
    final sorted = rooms.map((room) => {...room}).toList(growable: false)
      ..sort((a, b) {
        final aTime = _legacyRoomSortTimestamp(a);
        final bTime = _legacyRoomSortTimestamp(b);
        final byTime = aTime.compareTo(bTime);
        if (byTime != 0) {
          return byTime;
        }
        final aId = a['id'] as String? ?? '';
        final bId = b['id'] as String? ?? '';
        return aId.compareTo(bId);
      });

    for (var i = 0; i < sorted.length; i++) {
      sorted[i]['legacy_order_index'] = i;
      sorted[i]['is_locked'] =
          !_hasProPlanAccess && i >= _HomeViewState._freePlanRoomLimit;
    }
    return sorted;
  }

  bool _isRoomLocked(String? roomId) {
    if (roomId == null || _hasProPlanAccess) {
      return false;
    }
    for (final room in _myRooms) {
      if (room['id'] == roomId) {
        return room['is_locked'] == true;
      }
    }
    return false;
  }

  bool get _isCurrentRoomLocked => _isRoomLocked(_roomId);

  void _switchRoom(
    String roomId, {
    String? petType,
    bool showEntryLoading = false,
  }) {
    _syncCrashContextFromHome(lastAction: 'switch_room');
    unawaited(
      _captureHomeMemorySnapshot(
        source: 'home_room_switch_start',
        roomId: roomId,
        note: showEntryLoading ? 'entry_loading' : null,
      ),
    );
    _feedingAnimationToken++;
    final roomEntryToken = showEntryLoading ? ++_roomEntryLoadingToken : -1;
    final roomEntryStartedAt = DateTime.now();
    final previousRoom = _roomId;
    final roomSnapshot = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
      (room) => room?['id'] == roomId,
      orElse: () => null,
    );
    final roomPetType = roomSnapshot?['pet_type'] as String?;
    final nextPetType = PetCatalog.resolveIdForAppVersion(
      petType ?? roomPetType,
      appVersion: _currentAppVersion,
    );
    final likelyDeparted = _isRoomLikelyDeparted(roomId);
    _setStateForRoomManager(() {
      _roomId = roomId;
      _petState = null;
      _petId = null;
      _petStateReady = false;
      _lastOverfedAt = null;
      _overfedFeedEventArmedAt = null;
      _showOverfedBubble = false;
      _petDeparted = likelyDeparted;
      _petDeparturePrompted = false;
      _lastDeparturePetId = null;
      _petName = null;
      _petLevel = null;
      _petExp = null;
      _petType = nextPetType;
      _roomEntryLoading = showEntryLoading;
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
      _photoFoodImageSource = null;
      _photoFoodNormalizedPosition = null;
      _photoFoodDropping = false;
      _photoFoodBiteStage = 0;
      _petEating = false;
      _applyLatestFeedData(
        PetHomeGalleryFeedData.fromRoomSnapshot(roomSnapshot),
      );
    });
    _overfedBubbleTimer?.cancel();
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
    final previousPetStateChannel = _petStateChannel;
    _petStateChannel = null;
    unawaited(_removeRealtimeChannel(previousPetStateChannel));
    _petSubscriptionPetId = null;
    final previousFurnitureChannel = _furnitureChannel;
    _furnitureChannel = null;
    unawaited(_removeRealtimeChannel(previousFurnitureChannel));
    _furnitureSubscriptionRoomId = null;
    final previousBackgroundStateChannel = _backgroundStateChannel;
    _backgroundStateChannel = null;
    unawaited(_removeRealtimeChannel(previousBackgroundStateChannel));
    final previousBackgroundInventoryChannel = _backgroundInventoryChannel;
    _backgroundInventoryChannel = null;
    unawaited(_removeRealtimeChannel(previousBackgroundInventoryChannel));
    _backgroundSubscriptionRoomId = null;
    unawaited(
      _captureHomeMemorySnapshot(
        source: 'home_room_switch_channels_removed',
        roomId: roomId,
      ),
    );
    if (showEntryLoading) {
      unawaited(
        _loadRoomEntryCore(
          roomEntryToken: roomEntryToken,
          roomEntryStartedAt: roomEntryStartedAt,
        ),
      );
    } else {
      unawaited(_refreshPetState(tick: true));
    }
    unawaited(_refreshLatestFeed(roomId));
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
    _subscribeToFurniture(roomId);
    unawaited(_loadRoomBackgrounds(roomId));
    unawaited(_loadRoomBackgroundState(roomId));
    _subscribeToBackgrounds(roomId);
    if (previousRoom != roomId) {
      AnalyticsService.instance.logEvent('room_switch');
    }
    unawaited(
      _captureHomeMemorySnapshot(
        source: 'home_room_switch_ready',
        roomId: roomId,
        note: previousRoom == roomId ? 'same_room' : 'new_room',
      ),
    );
    _syncCrashContextFromHome(lastAction: 'switch_room_ready');
  }

  Future<void> _loadRoomEntryCore({
    required int roomEntryToken,
    required DateTime roomEntryStartedAt,
  }) async {
    var canCompleteEntry = true;
    try {
      await _refreshPetState(tick: true);
    } finally {
      final elapsed = DateTime.now().difference(roomEntryStartedAt);
      final minimum = _HomeViewState._roomEntryLoadingMinDuration;
      if (elapsed < minimum) {
        await Future<void>.delayed(minimum - elapsed);
      }
      if (!mounted || _roomEntryLoadingToken != roomEntryToken) {
        canCompleteEntry = false;
      }
      if (canCompleteEntry) {
        _setStateForRoomManager(() {
          _roomEntryLoading = false;
          _roomEntryFadeVersion++;
        });
      }
      _processPendingNotificationIntent();
    }
  }

  void _enterRoomFromSelection(String roomId, {String? petType}) {
    if (!_showRoomSelection) {
      _switchRoom(roomId, petType: petType, showEntryLoading: true);
      return;
    }
    _setStateForRoomManager(() {
      _showRoomSelection = false;
      _roomSelectionId = roomId;
    });
    _switchRoom(roomId, petType: petType, showEntryLoading: true);
  }

  Future<void> _createRoom() async {
    _syncCrashContextFromHome(lastAction: 'create_room_start');
    if (_creatingRoom) {
      return;
    }
    final reachedFreePlanLimit =
        !_hasProPlanAccess &&
        _myRooms.length >= _HomeViewState._freePlanRoomLimit;
    if (reachedFreePlanLimit) {
      _showRoomLimitReachedJuiceCard();
      return;
    }

    await Navigator.of(context).push<PetSelectionResult>(
      PetSelectionPage.route(
        maxPetNameLength: _HomeViewState._petNameMaxLength,
        onSubmitSelection: _submitCreateRoomFromPetSelection,
      ),
    );
  }

  void _showRoomLimitReachedJuiceCard() {
    final l10n = AppLocalizations.of(context)!;
    showJuiceToast(
      context: context,
      message: l10n.roomLimitReached,
      tone: AppDialogTone.warning,
      actionLabel: l10n.shopTitle,
      onActionPressed: () {
        final firstRoomId = _myRooms.isNotEmpty
            ? _myRooms.first['id'] as String?
            : null;
        final departedInfo = firstRoomId != null
            ? _departedPetsByRoom[firstRoomId]
            : null;

        Navigator.of(context).push<ShopRouteResult>(
          MaterialPageRoute(
            builder: (_) => ShopView(
              roomId: firstRoomId,
              isProUser: _hasProPlanAccess,
              departedPets: departedInfo != null ? [departedInfo] : const [],
              onReturnPet: _returnDepartedPet,
            ),
          ),
        );
      },
    );
  }

  Future<String?> _submitCreateRoomFromPetSelection(
    PetSelectionResult selection,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (_creatingRoom) {
      return l10n.roomSelectionCreating;
    }
    final selectedPet = selection.pet;
    final petName = selection.petName.trim();

    _setStateForRoomManager(() => _creatingRoom = true);
    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': petName})
          .single();

      final newId = response['room_id'] as String?;
      if (newId == null) {
        throw Exception('room_id_missing');
      }

      await _fetchRooms();
      if (!mounted) {
        return l10n.commonTryAgain;
      }

      final applied = await _applyPetSelection(newId, selectedPet);
      await _applyInitialPetName(newId, petName);
      if (!mounted) {
        return l10n.commonTryAgain;
      }
      _setStateForRoomManager(() {
        _newRoomInviteRoomId = newId;
        _showNewRoomInvitePrompt = true;
      });
      if (applied) {
        _enterRoomFromSelection(newId, petType: selectedPet.id);
      } else {
        _enterRoomFromSelection(newId);
      }
      unawaited(_markCreatePetOnboardingStepCompleted());
      AnalyticsService.instance.logEvent(
        'room_create',
        parameters: {'result': 'success'},
      );
      _syncCrashContextFromHome(lastAction: 'create_room_success');
      if (mounted) {
        showJuiceSnackbar(context: context, message: l10n.roomCreatedSuccess);
      }
      return null;
    } catch (error) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: StackTrace.current,
          source: 'home_create_room',
          fatal: false,
        ),
      );
      if (!mounted) {
        return l10n.commonTryAgain;
      }
      return l10n.roomCreateFailed(userFacingError(context, error));
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _creatingRoom = false);
      }
    }
  }

  Future<bool> _applyPetSelection(
    String roomId,
    PetDefinition selectedPet,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final petId = await _loadPetId(roomId);
      if (petId == null) {
        if (mounted) {
          showJuiceToast(context: context, message: l10n.petNotFound, tone: AppDialogTone.danger);
        }
        return false;
      }

      await Supabase.instance.client
          .from('pets')
          .update({
            'color_dna': {PetCatalog.colorDnaTypeKey: selectedPet.id},
          })
          .eq('id', petId);

      _updatePetType(selectedPet.id);
      unawaited(_loadPetInfo(petId, roomId: roomId));
      return true;
    } catch (error) {
      if (mounted) {
        showJuiceToast(
          context: context,
          message: l10n.petSelectionFailed(userFacingError(context, error)),
          tone: AppDialogTone.danger,
        );
      }
      return false;
    }
  }

  Future<void> _applyInitialPetName(String roomId, String petName) async {
    final trimmed = petName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    try {
      final petId = await _loadPetId(roomId);
      if (petId == null) {
        if (mounted) {
          showJuiceToast(context: context, message: l10n.petNotFound, tone: AppDialogTone.danger);
        }
        return;
      }

      await Supabase.instance.client
          .from('pets')
          .update({'name': trimmed})
          .eq('id', petId);

      if (!mounted) {
        return;
      }
      _setStateForRoomManager(() {
        if (_petId == petId) {
          _petName = trimmed;
        }
        _myRooms = _myRooms
            .map(
              (entry) => entry['id'] == roomId
                  ? {...entry, 'pet_name': trimmed}
                  : entry,
            )
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: l10n.petNameUpdateFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  Future<void> _joinRoomByCode() async {
    _syncCrashContextFromHome(lastAction: 'join_room_start');
    if (_joiningRoom) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String? errorText;

    final code = await showJuiceToast<String>(
      context: context,
      message: l10n.roomJoinTitle,
      position: JuicePosition.center,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.roomJoinHelper,
                textAlign: TextAlign.center,
                style: GoogleFonts.mPlusRounded1c(
                  color: const Color(0xFF5A4A42),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(16),
              TextField(
                controller: controller,
                onTapOutside: dismissKeyboardOnTapOutside,
                autofocus: true,
                style: GoogleFonts.mPlusRounded1c(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: l10n.roomJoinHint,
                  errorText: errorText,
                  errorStyle: GoogleFonts.mPlusRounded1c(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                ],
                onSubmitted: (value) {
                  final val = value.trim().toUpperCase();
                  if (val.length < 6) {
                    setState(() {
                      errorText = l10n.roomJoinHint;
                    });
                    return;
                  }
                  Navigator.pop(context, val);
                },
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () {
                        final value = controller.text.trim().toUpperCase();
                        if (value.length < 6) {
                          setState(() {
                            errorText = l10n.roomJoinHint;
                          });
                          return;
                        }
                        Navigator.pop(context, value);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonJoin,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (code == null || code.isEmpty) {
      return;
    }

    _setStateForRoomManager(() => _joiningRoom = true);
    try {
      await Supabase.instance.client.rpc(
        'join_room_by_invite_code',
        params: {'p_invite_code': code},
      );
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      AnalyticsService.instance.logEvent(
        'room_join',
        parameters: {'method': 'invite_code', 'result': 'success'},
      );
      _syncCrashContextFromHome(lastAction: 'join_room_success');
      showJuiceSnackbar(context: context, message: l10n.roomJoinSuccess);
    } catch (error) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: StackTrace.current,
          source: 'home_join_room',
          fatal: false,
        ),
      );
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: l10n.roomJoinFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _joiningRoom = false);
      }
    }
  }

  Future<void> _confirmLeaveRoom(String roomId) async {
    if (_leavingRoom) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final room = _myRooms.firstWhere(
      (entry) => entry['id'] == roomId,
      orElse: () => const {},
    );
    final petName = (room['pet_name'] as String?)?.trim();
    final petType = room['pet_type'] as String?;
    final fallbackName = PetCatalog.byId(petType).name(l10n);
    final confirmed = await showJuiceToast<bool>(
      context: context,
      message: l10n.roomLeaveTitle,
      position: JuicePosition.center,
      tone: AppDialogTone.danger,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.roomLeaveMessage(
              petName == null || petName.isEmpty ? fallbackName : petName,
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              color: const Color(0xFF5A4A42),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.roomLeaveConfirm,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveRoom(roomId);
    }
  }

  Future<void> _leaveRoom(String roomId) async {
    _syncCrashContextFromHome(lastAction: 'leave_room_start');
    if (_leavingRoom) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _setStateForRoomManager(() {
      _leavingRoom = true;
      _showRoomSelection = true;
      if (_roomId == roomId) {
        _roomId = null;
        _roomSelectionId = null;
        _petState = null;
        _petId = null;
      }
    });
    try {
      await Supabase.instance.client.rpc(
        'leave_room',
        params: {'p_room_id': roomId},
      );
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      showJuiceSnackbar(context: context, message: l10n.roomLeaveSuccess);
      _syncCrashContextFromHome(lastAction: 'leave_room_success');
    } catch (error) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: StackTrace.current,
          source: 'home_leave_room',
          fatal: false,
        ),
      );
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: l10n.roomLeaveFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _leavingRoom = false);
      }
    }
  }

  Future<Map<String, _RoomPetSummary>> _fetchRoomPetSummaries(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('pets')
        .select('room_id, name, level, color_dna, pet_state(hunger)')
        .inFilter('room_id', roomIds);

    final summaries = <String, _RoomPetSummary>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      final state = row['pet_state'];
      num? hunger;
      if (state is Map) {
        hunger = state['hunger'] as num?;
      } else if (state is List && state.isNotEmpty) {
        final first = state.first;
        if (first is Map) {
          hunger = first['hunger'] as num?;
        }
      }
      final petType = PetCatalog.resolveIdForAppVersion(
        PetCatalog.typeFromColorDna(row['color_dna']),
        appVersion: _currentAppVersion,
      );
      summaries[roomId] = _RoomPetSummary(
        petType: petType,
        healthValue: _healthValueFromHunger(hunger),
        petName: (row['name'] as String?)?.trim(),
        petLevel: row['level'] as int?,
      );
    }
    return summaries;
  }

  Future<Map<String, _RoomLatestFeed>> _fetchRoomLatestFeeds(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('messages')
        .select('id, room_id, image_url, caption, sender_id, created_at')
        .inFilter('room_id', roomIds)
        .eq('type', 'image_feed')
        .not('image_url', 'is', null)
        .order('created_at', ascending: false)
        .limit(roomIds.length * kPetHomeGalleryMaxPhotos * 3);

    final feeds = <String, _RoomLatestFeed>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      final imageUrl = row['image_url'] as String?;
      if (roomId == null || imageUrl == null || imageUrl.isEmpty) {
        continue;
      }

      final existing = feeds[roomId];
      if (existing == null) {
        feeds[roomId] = _RoomLatestFeed(
          latestImageUrl: imageUrl,
          latestCaption: row['caption'] as String?,
          latestSenderId: row['sender_id'] as String?,
          imageUrls: [imageUrl],
          imageCaptions: [row['caption'] as String?],
          imageSenderIds: [row['sender_id'] as String?],
          imageSentAts: [_parseLatestFeedCreatedAt(row['created_at'])],
          imageMessageIds: [row['id'] as String?],
        );
        continue;
      }
      if (existing.imageUrls.length >= kPetHomeGalleryMaxPhotos ||
          existing.imageUrls.contains(imageUrl)) {
        continue;
      }
      existing.imageUrls.add(imageUrl);
      existing.imageCaptions.add(row['caption'] as String?);
      existing.imageSenderIds.add(row['sender_id'] as String?);
      existing.imageSentAts.add(_parseLatestFeedCreatedAt(row['created_at']));
      existing.imageMessageIds.add(row['id'] as String?);
    }
    return feeds;
  }

  Future<Map<String, int>> _fetchRoomMemberCounts(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('room_members')
        .select('room_id')
        .inFilter('room_id', roomIds)
        .eq('is_active', true);
    final counts = <String, int>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      counts[roomId] = (counts[roomId] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String, int>> _fetchRoomUnreadCounts(
    List<String> roomIds,
    String userId,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final response = await Supabase.instance.client.rpc(
      'get_unread_message_counts_for_user',
      params: {'p_user_id': userId},
    );
    final rows = response is List ? response : const [];
    final counts = <String, int>{};
    final roomIdSet = roomIds.toSet();
    for (final row in rows) {
      if (row is! Map) {
        continue;
      }
      final map = row.cast<String, dynamic>();
      final roomId = map['room_id'] as String?;
      if (roomId == null || !roomIdSet.contains(roomId)) {
        continue;
      }
      final unreadRaw = map['unread_count'];
      final unread = unreadRaw is int
          ? unreadRaw
          : (unreadRaw is num ? unreadRaw.toInt() : 0);
      counts[roomId] = unread < 0 ? 0 : unread;
    }
    return counts;
  }
}
