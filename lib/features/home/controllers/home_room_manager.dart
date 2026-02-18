part of '../home_view.dart';

extension _HomeRoomManager on _HomeViewState {
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
    } catch (_) {
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _loadingRoom = false);
      }
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
    _feedingAnimationToken++;
    final roomEntryToken = showEntryLoading ? ++_roomEntryLoadingToken : -1;
    final roomEntryStartedAt = DateTime.now();
    final previousRoom = _roomId;
    final roomSnapshot = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
      (room) => room?['id'] == roomId,
      orElse: () => null,
    );
    final roomPetType = roomSnapshot?['pet_type'] as String?;
    final nextPetType = petType ?? roomPetType ?? PetCatalog.defaultPetId;
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
      _latestFeedImageUrl = roomSnapshot?['latest_photo'] as String?;
      _latestFeedImageUrls =
          ((roomSnapshot?['latest_photos'] as List?)
                      ?.whereType<String>()
                      .where((url) => url.isNotEmpty)
                      .take(3)
                      .toList() ??
                  const <String>[])
              .toList(growable: false);
      final snapshotCaptions =
          ((roomSnapshot?['latest_photo_captions'] as List?)
                      ?.map((entry) => entry as String?)
                      .take(3)
                      .toList() ??
                  const <String?>[])
              .toList(growable: false);
      if (snapshotCaptions.isEmpty) {
        _latestFeedCaptions = _latestFeedImageUrls.isEmpty
            ? <String?>[]
            : <String?>[
                roomSnapshot?['latest_caption'] as String?,
                ...List<String?>.filled(_latestFeedImageUrls.length - 1, null),
              ];
      } else {
        _latestFeedCaptions = List<String?>.generate(
          _latestFeedImageUrls.length,
          (index) =>
              index < snapshotCaptions.length ? snapshotCaptions[index] : null,
        );
      }
      final snapshotSenderIds =
          ((roomSnapshot?['latest_photo_sender_ids'] as List?)
                      ?.map((entry) => entry as String?)
                      .take(3)
                      .toList() ??
                  const <String?>[])
              .toList(growable: false);
      final latestSenderId = roomSnapshot?['latest_sender_id'] as String?;
      if (snapshotSenderIds.isEmpty) {
        _latestFeedSenderIds = _latestFeedImageUrls.isEmpty
            ? <String?>[]
            : <String?>[
                latestSenderId,
                ...List<String?>.filled(_latestFeedImageUrls.length - 1, null),
              ];
      } else {
        _latestFeedSenderIds = List<String?>.generate(
          _latestFeedImageUrls.length,
          (index) => index < snapshotSenderIds.length
              ? snapshotSenderIds[index]
              : null,
        );
      }
      _latestFeedSenderId = roomSnapshot?['latest_sender_id'] as String?;
      _latestFeedCaption = roomSnapshot?['latest_caption'] as String?;
    });
    _overfedBubbleTimer?.cancel();
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
    _petStateChannel?.unsubscribe();
    _petStateChannel = null;
    _petSubscriptionPetId = null;
    _furnitureChannel?.unsubscribe();
    _furnitureChannel = null;
    _furnitureSubscriptionRoomId = null;
    _backgroundStateChannel?.unsubscribe();
    _backgroundStateChannel = null;
    _backgroundInventoryChannel?.unsubscribe();
    _backgroundInventoryChannel = null;
    _backgroundSubscriptionRoomId = null;
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
    final l10n = AppLocalizations.of(context)!;
    final reachedFreePlanLimit =
        !_hasProPlanAccess &&
        _myRooms.length >= _HomeViewState._freePlanRoomLimit;
    if (reachedFreePlanLimit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomLimitReached)));
      return;
    }

    final selectedPet = await Navigator.of(
      context,
    ).push<PetDefinition>(PetSelectionPage.route());
    if (!mounted || selectedPet == null) {
      return;
    }

    final creation = await _promptRoomCreationDetails();
    if (!mounted || creation == null) {
      return;
    }

    _setStateForRoomManager(() => _creatingRoom = true);
    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': creation.petName.trim()})
          .single();

      final newId = response['room_id'] as String?;
      if (newId == null) {
        throw Exception('room_id_missing');
      }

      await _fetchRooms();
      if (!mounted) {
        return;
      }

      final applied = await _applyPetSelection(newId, selectedPet);
      await _applyInitialPetName(newId, creation.petName);
      if (!mounted) {
        return;
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
      AnalyticsService.instance.logEvent(
        'room_create',
        parameters: {'result': 'success'},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomCreatedSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.roomCreateFailed(userFacingError(context, error))),
        ),
      );
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.petNotFound)));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.petSelectionFailed(userFacingError(context, error)),
            ),
          ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.petNotFound)));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.petNameUpdateFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<_RoomCreationDetails?> _promptRoomCreationDetails() async {
    return showAppDialog<_RoomCreationDetails>(
      context: context,
      builder: (context) => const _RoomCreationDialog(
        maxPetNameLength: _HomeViewState._petNameMaxLength,
      ),
    );
  }

  Future<void> _joinRoomByCode() async {
    if (_joiningRoom) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomJoinTitle,
        message: l10n.roomJoinHelper,
        body: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.roomJoinHint),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          ],
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogAction.primary(
            label: l10n.commonJoin,
            onPressed: () {
              final value = controller.text.trim().toUpperCase();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) {
      return;
    }

    _setStateForRoomManager(() => _joiningRoom = true);
    try {
      final response = await Supabase.instance.client.rpc(
        'join_room_by_code',
        params: {'code': code},
      );

      String? roomId;
      if (response is String) {
        roomId = response;
      } else if (response is Map) {
        final value = response.values.isNotEmpty ? response.values.first : null;
        if (value is String) {
          roomId = value;
        }
      } else if (response is List && response.isNotEmpty) {
        final value = response.first;
        if (value is String) {
          roomId = value;
        } else if (value is Map) {
          final inner = value.values.isNotEmpty ? value.values.first : null;
          if (inner is String) {
            roomId = inner;
          }
        }
      }

      await _fetchRooms();
      if (!mounted) {
        return;
      }
      if (roomId != null) {
        _enterRoomFromSelection(roomId);
      }

      AnalyticsService.instance.logEvent(
        'room_join',
        parameters: {'method': 'invite_code', 'result': 'success'},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomJoinSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.roomJoinFailed(userFacingError(context, error))),
        ),
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.warning,
        title: l10n.roomLeaveTitle,
        message: l10n.roomLeaveMessage(
          petName == null || petName.isEmpty ? fallbackName : petName,
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppDialogAction.destructive(
            label: l10n.roomLeaveConfirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveRoom(roomId);
    }
  }

  Future<void> _leaveRoom(String roomId, {bool showSnackBar = true}) async {
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
      if (showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.roomLeaveSuccess)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.roomLeaveFailed(userFacingError(context, error)),
            ),
          ),
        );
      }
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
      final petType = PetCatalog.resolveId(
        PetCatalog.typeFromColorDna(row['color_dna']),
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
        .select('room_id, image_url, caption, sender_id, created_at')
        .inFilter('room_id', roomIds)
        .eq('type', 'image_feed')
        .not('image_url', 'is', null)
        .order('created_at', ascending: false)
        .limit(roomIds.length * 12);

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
        );
        continue;
      }
      if (existing.imageUrls.length >= 3 ||
          existing.imageUrls.contains(imageUrl)) {
        continue;
      }
      existing.imageUrls.add(imageUrl);
      existing.imageCaptions.add(row['caption'] as String?);
      existing.imageSenderIds.add(row['sender_id'] as String?);
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
