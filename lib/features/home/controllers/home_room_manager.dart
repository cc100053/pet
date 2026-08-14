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
    if (_roomsFetchInFlight) {
      return;
    }
    _roomsFetchInFlight = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // The OAuth deep-link handoff can mount Home before the session lands
        // on the client. Bootstrap is once-only, so giving up here without a
        // retry is what leaves the room list permanently empty until the user
        // signs out and back in.
        _noteRoomsFetchFailed('no_session');
        _setStateForRoomManager(() => _loadingRoom = false);
        return;
      }
      final previousUnreadByRoom = <String, int>{
        for (final room in _myRooms)
          if (room['id'] is String)
            room['id'] as String: resolveRoomUnreadCount(room),
      };
      // Last known enrichment, keyed by room. A summary query that fails falls
      // back to these rather than to an empty value: "0 members" and a blank
      // health bar read as fresh data, not as a missing read.
      final previousRoomById = <String, Map<String, dynamic>>{
        for (final room in _myRooms)
          if (room['id'] is String) room['id'] as String: room,
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
      final equippedSkusByRoom = <String, Map<String, String>>{};
      var equippedSkusFetched = false;
      final senderIds = <String>{};
      if (roomIds.isNotEmpty) {
        // Equipment is best-effort: never let it fail or block the others.
        final equippedSkusFuture =
            _withNetworkTimeout(_fetchRoomEquippedSkus(roomIds))
                .then<Map<String, Map<String, String>>?>((value) => value)
                .catchError((_) => null);
        // Fetch the independent per-room summaries concurrently instead of in
        // five serial round-trips.
        // Enrichment must not be able to hide the rooms themselves: the room
        // list has already been fetched successfully at this point, so a
        // timeout on any summary query degrades that badge instead of aborting
        // into the outer catch with `_myRooms` never assigned. Each query also
        // degrades independently — discarding three successful reads because a
        // fourth timed out would repaint every room as empty.
        Future<T?> degradable<T>(Future<T> query, String stage) =>
            query.then<T?>((value) => value).catchError((Object error) {
              _logRoomsDiagnostic('summary_failed', '$stage: $error');
              return null;
            });

        final results = await Future.wait<Object?>([
          degradable(
            _withNetworkTimeout(_fetchRoomPetSummaries(roomIds)),
            'pet_summaries',
          ),
          degradable(
            _withNetworkTimeout(_fetchRoomLatestFeeds(roomIds)),
            'latest_feeds',
          ),
          degradable(
            _withNetworkTimeout(_fetchRoomMemberCounts(roomIds)),
            'member_counts',
          ),
          degradable(
            _withNetworkTimeout(_fetchRoomUnreadCounts(roomIds, userId)),
            'unread_counts',
          ),
        ]);
        final petSummaries = results[0] as Map<String, _RoomPetSummary>?;
        final feeds = results[1] as Map<String, _RoomLatestFeed>?;
        final memberCounts = results[2] as Map<String, int>?;
        final unreadCounts = results[3] as Map<String, int>?;
        final equippedSkus = await equippedSkusFuture;
        if (equippedSkus != null) {
          equippedSkusByRoom.addAll(equippedSkus);
          equippedSkusFetched = true;
        }
        if (unreadCounts != null) {
          unreadCountsByRoom.addAll(unreadCounts);
        }
        for (final room in rooms) {
          final roomId = room['id'] as String?;
          final previousRoom = roomId == null ? null : previousRoomById[roomId];
          if (roomId != null) {
            room['member_count'] = memberCounts != null
                ? (memberCounts[roomId] ?? 0)
                : (previousRoom?['member_count'] ?? 0);
            // Keep the last known unread badge when the counts query failed;
            // zeroing it would silently mark rooms as read.
            room['unread_count'] = unreadCounts != null
                ? (unreadCountsByRoom[roomId] ?? 0)
                : (previousUnreadByRoom[roomId] ?? 0);
          }
          if (petSummaries == null && previousRoom != null) {
            _carryOverRoomFields(room, previousRoom, _petSummaryRoomFields);
          }
          if (feeds == null && previousRoom != null) {
            _carryOverRoomFields(room, previousRoom, _latestFeedRoomFields);
          }
          final summary = roomId == null ? null : petSummaries?[roomId];
          if (summary != null) {
            room['pet_type'] = summary.petType;
            room['pet_health'] = summary.healthValue;
            room['pet_name'] = summary.petName;
            room['pet_level'] = summary.petLevel;
            if (summary.petId != null) {
              room['pet_id'] = summary.petId;
            }
            final petId = summary.petId;
            final petState = summary.petState;
            if (petId != null && petState != null) {
              _noteAppliedPetStateClock(petId, petState);
              _cachePetState(roomId!, petId, petState);
            }
          }
          if (roomId != null && feeds != null && feeds.containsKey(roomId)) {
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
      _syncRoomSelectionEquipmentSubscription(roomIds);
      final sortedRooms = _applyLegacyRoomLocking(rooms);

      _setStateForRoomManager(() {
        _myRooms = sortedRooms;
        if (equippedSkusFetched) {
          _roomEquippedSkusBySlot
            ..clear()
            ..addAll(equippedSkusByRoom);
        }
        if (rooms.isEmpty) {
          _showRoomSelection = true;
          _roomSelectionId = null;
          _roomEquippedSkusBySlot.clear();
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
      // Only now is the room list authoritative: everything that persists or
      // recovers state keys off this flag.
      _roomsLoadedFromNetwork = true;
      _roomsRetryAttempt = 0;
      _roomsRetryTimer?.cancel();
      _roomsRetryTimer = null;
      await _cacheHomeBootstrapSnapshot();
      _processPendingNotificationIntent();
    } catch (error) {
      _noteRoomsFetchFailed('$error');
    } finally {
      _roomsFetchInFlight = false;
      if (mounted) {
        _setStateForRoomManager(() => _loadingRoom = false);
      }
      _processPendingNotificationIntent();
    }
  }

  /// Fields owned by `_fetchRoomPetSummaries`.
  static const List<String> _petSummaryRoomFields = <String>[
    'pet_type',
    'pet_health',
    'pet_name',
    'pet_level',
    'pet_id',
  ];

  /// Fields owned by `_fetchRoomLatestFeeds`.
  static const List<String> _latestFeedRoomFields = <String>[
    'latest_photo',
    'latest_photos',
    'latest_photo_captions',
    'latest_photo_sender_ids',
    'latest_photo_message_ids',
    'latest_photo_created_ats',
    'latest_caption',
    'latest_sender_id',
  ];

  /// Copies the last known value of [fields] onto a freshly built room map.
  /// Used when the query that owns those fields failed: the room row is rebuilt
  /// from scratch on every fetch, so leaving them unset would drop a health bar
  /// or a latest photo that is still perfectly valid.
  void _carryOverRoomFields(
    Map<String, dynamic> room,
    Map<String, dynamic> previousRoom,
    List<String> fields,
  ) {
    for (final field in fields) {
      final value = previousRoom[field];
      if (value != null) {
        room[field] = value;
      }
    }
  }

  void _logRoomsDiagnostic(String stage, String detail) {
    // Deliberately loud: the previous `catch (_) {}` made a blank room list
    // indistinguishable from "this account has no rooms".
    debugPrint('[home_rooms] $stage: $detail');
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'home_view',
        lastAction: 'rooms_$stage',
      ),
    );
  }

  /// Records a failed room fetch and schedules a bounded retry. Home bootstrap
  /// runs once per mount, so without this a single failure leaves the room
  /// selection empty until the user signs out and back in.
  void _noteRoomsFetchFailed(String reason) {
    _logRoomsDiagnostic('fetch_failed', reason);
    if (_roomsLoadedFromNetwork || !mounted) {
      return;
    }
    if (_roomsRetryAttempt >= _HomeViewState._roomsMaxRetryAttempts) {
      _logRoomsDiagnostic('retry_exhausted', 'attempts=$_roomsRetryAttempt');
      return;
    }
    _roomsRetryAttempt += 1;
    final delay = Duration(milliseconds: 400 * (1 << (_roomsRetryAttempt - 1)));
    _roomsRetryTimer?.cancel();
    _roomsRetryTimer = Timer(delay, () {
      if (!mounted || _roomsLoadedFromNetwork) {
        return;
      }
      unawaited(_fetchRooms());
    });
  }

  /// Re-runs the room fetch once a session is available. Covers the OAuth
  /// deep-link handoff, where Home can mount before the client has the session
  /// and the original bootstrap fetch bails with no user id.
  Future<void> _recoverRoomsIfNeeded(String source) async {
    if (!mounted || _roomsLoadedFromNetwork || _roomsFetchInFlight) {
      return;
    }
    // The auth stream replays `initialSession` during `initState`, before the
    // post-frame callback starts bootstrap. Recovering there would pre-empt
    // `_restoreHomeBootstrapCache` and cost the warm start its instant paint.
    if (!_roomsBootstrapAttempted) {
      return;
    }
    if (Supabase.instance.client.auth.currentUser?.id == null) {
      return;
    }
    _logRoomsDiagnostic('recover', source);
    _roomsRetryAttempt = 0;
    _roomsRetryTimer?.cancel();
    _roomsRetryTimer = null;
    await _fetchRooms();
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
    final previousRoom = _roomId;
    final roomCount = _myRooms.length;
    final targetRoomIndex = _myRooms.indexWhere((room) => room['id'] == roomId);
    _syncCrashContextFromHome(lastAction: 'switch_room');
    unawaited(
      CrashReportingService.instance.setCustomKeys(<String, Object?>{
        'room_count': roomCount,
        'selected_room_index': targetRoomIndex >= 0 ? targetRoomIndex : null,
        'room_switch_from': previousRoom ?? 'none',
        'room_switch_to': roomId,
        'room_switch_entry_loading': showEntryLoading,
      }),
    );
    unawaited(
      _captureHomeMemorySnapshot(
        source: 'home_room_switch_start',
        roomId: roomId,
        note:
            'count=$roomCount index=${targetRoomIndex < 0 ? 'unknown' : targetRoomIndex}'
            '${showEntryLoading ? ' entry_loading' : ''}',
      ),
    );
    unawaited(
      MemoryDiagnosticsService.instance.trimImageCacheIfNeeded(
        source: 'home_room_switch_cache_trim',
        route: 'home_view',
        roomId: roomId,
        note:
            'from=${previousRoom ?? 'none'}'
            ',to=$roomId'
            ',count=$roomCount'
            ',index=${targetRoomIndex < 0 ? 'unknown' : targetRoomIndex}',
      ),
    );
    _feedingAnimationToken++;
    final roomEntryToken = showEntryLoading ? ++_roomEntryLoadingToken : -1;
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
    // Warm entry: a room visited earlier this session (or restored from the
    // bootstrap cache) still has its pet id and last state cached, so we can
    // paint it instantly and refresh in the background instead of holding the
    // entry-loading overlay.
    var cachedPetId = _petIdByRoom[roomId];
    var cachedPetState = _petStateByRoom[roomId];
    // Even on a cold entry the room-selection fetch already knows the room's
    // main pet id, so seed it to skip the `_loadPetId` round-trip in
    // `_refreshPetState`.
    final snapshotPetId = roomSnapshot?['pet_id'] as String?;
    // Self-heal a stale / cross-room warm cache. The room snapshot's pet id is
    // this room's authoritative main pet; a cached id that disagrees means a
    // *different* room's pet leaked into this room's cache (e.g. persisted from
    // an older build). Trusting it would paint the wrong pet's name and load
    // equipment for a pet that isn't in this room — `get_pet_equipment` then
    // raises `pet_not_found`. Evict the poisoned cache and fall back to the
    // snapshot so `_refreshPetState`/`_loadPetId` re-resolve the real main pet.
    if (cachedPetId != null &&
        snapshotPetId != null &&
        cachedPetId != snapshotPetId) {
      _petIdByRoom.remove(roomId);
      _petStateByRoom.remove(roomId);
      cachedPetId = null;
      cachedPetState = null;
    }
    final knownPetId = cachedPetId ?? snapshotPetId;
    final warmEntry =
        showEntryLoading &&
        !likelyDeparted &&
        cachedPetId != null &&
        cachedPetState != null;
    _setStateForRoomManager(() {
      _roomId = roomId;
      _petState = warmEntry ? cachedPetState : null;
      _petId = warmEntry ? cachedPetId : knownPetId;
      _equippedItemsBySlot.clear();
      _ownedEquipmentItems.clear();
      _equipmentError = null;
      _equipmentLoading = false;
      _petStateReady = warmEntry;
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
      _roomEntryLoading = showEntryLoading && !warmEntry;
      _roomEntryOverlayVisible = false;
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
    // Seed the freshness clock with the warm value we just painted so a stale
    // refetch/realtime snapshot cannot regress the satiety bar after re-entry.
    final warmPetId = warmEntry ? cachedPetId : null;
    final warmPetState = warmEntry ? cachedPetState : null;
    if (warmPetId != null && warmPetState != null) {
      _noteAppliedPetStateClock(warmPetId, warmPetState);
    }
    _overfedBubbleTimer?.cancel();
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
    final previousPetStateChannel = _petStateChannel;
    final previousPetEquipmentChannel = _petEquipmentChannel;
    _petStateChannel = null;
    _petEquipmentChannel = null;
    unawaited(_removeRealtimeChannel(previousPetStateChannel));
    unawaited(_removeRealtimeChannel(previousPetEquipmentChannel));
    _petSubscriptionPetId = null;
    _petEquipmentSubscriptionRoomId = null;
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
    if (showEntryLoading && !warmEntry) {
      _scheduleRoomEntryOverlayReveal(roomEntryToken);
      unawaited(_loadRoomEntryCore(roomEntryToken: roomEntryToken));
    } else {
      // Cold non-loading switches and warm entries both just refresh in the
      // background; the room is already (or about to be) visible.
      unawaited(_refreshPetState(tick: true));
    }
    unawaited(_refreshLatestFeed(roomId));
    unawaited(_loadRoomFurniture(roomId));
    _subscribeToFurniture(roomId);
    // Active background is visual-critical (which background to paint); load it
    // now. The owned-backgrounds list and furniture inventory only feed the
    // picker panels, so defer them past first paint to free the connection for
    // the entry-critical reads (pet state + placed furniture + active bg).
    unawaited(_loadRoomBackgroundState(roomId));
    _subscribeToBackgrounds(roomId);
    _scheduleDeferredRoomDecorLoads(roomId);
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

  /// Reveals the full-screen entry overlay only if the entry is still running
  /// after [_HomeViewState._roomEntryOverlayRevealDelay]. A fast entry finishes
  /// first and never blanks the room.
  void _scheduleRoomEntryOverlayReveal(int roomEntryToken) {
    _roomEntryOverlayRevealTimer?.cancel();
    _roomEntryOverlayRevealTimer = Timer(
      _HomeViewState._roomEntryOverlayRevealDelay,
      () {
        if (!mounted ||
            _roomEntryLoadingToken != roomEntryToken ||
            !_roomEntryLoading) {
          return;
        }
        _roomEntryOverlayShownAt = DateTime.now();
        _setStateForRoomManager(() => _roomEntryOverlayVisible = true);
      },
    );
  }

  Future<void> _loadRoomEntryCore({required int roomEntryToken}) async {
    var canCompleteEntry = true;
    try {
      await _refreshPetState(tick: true);
    } finally {
      _roomEntryOverlayRevealTimer?.cancel();
      _roomEntryOverlayRevealTimer = null;
      // Only an overlay the user actually saw needs to be held; padding an
      // entry that never revealed one just makes a fast room slower.
      final shownAt = _roomEntryOverlayVisible
          ? _roomEntryOverlayShownAt
          : null;
      if (shownAt != null) {
        final elapsed = DateTime.now().difference(shownAt);
        final minimum = _HomeViewState._roomEntryLoadingMinDuration;
        if (elapsed < minimum) {
          await Future<void>.delayed(minimum - elapsed);
        }
      }
      if (!mounted || _roomEntryLoadingToken != roomEntryToken) {
        canCompleteEntry = false;
      }
      if (canCompleteEntry) {
        _setStateForRoomManager(() {
          _roomEntryLoading = false;
          _roomEntryOverlayVisible = false;
          _roomEntryOverlayShownAt = null;
          _roomEntryFadeVersion++;
        });
      }
      _processPendingNotificationIntent();
    }
  }

  /// Loads the picker-only decor inventories (owned furniture + owned
  /// backgrounds) after the current frame paints, so they don't contend with
  /// the entry-critical reads. Guarded by the still-current room id.
  void _scheduleDeferredRoomDecorLoads(String roomId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _roomId != roomId) {
        return;
      }
      unawaited(_loadFurnitureInventory());
      unawaited(_loadRoomBackgrounds(roomId));
    });
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
          showJuiceToast(
            context: context,
            message: l10n.petNotFound,
            tone: AppDialogTone.danger,
          );
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
          showJuiceToast(
            context: context,
            message: l10n.petNotFound,
            tone: AppDialogTone.danger,
          );
        }
        return;
      }

      // Via RPC, not a direct column write: the table's RLS lets any room member
      // update `pets` freely, so a direct update validated nothing. Naming was
      // the one path into `pets.name` with no server-side rules at all.
      await Supabase.instance.client.rpc(
        'set_initial_pet_name',
        params: {'p_pet_id': petId, 'p_name': trimmed},
      );

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

  Future<void> _processPendingInviteLink() async {
    if (!mounted || !_homeBootstrapCompleted || _pendingInviteJoinRunning) {
      return;
    }
    final pendingCode = AppInviteLinkService.instance.pendingInviteCode;
    if (pendingCode == null || pendingCode.isEmpty) {
      return;
    }
    _pendingInviteJoinRunning = true;
    try {
      await _joinRoomWithInviteCode(
        pendingCode,
        method: 'invite_link',
        clearPendingInviteCode: true,
      );
    } finally {
      _pendingInviteJoinRunning = false;
    }
  }

  Future<bool> _joinRoomWithInviteCode(
    String rawCode, {
    required String method,
    bool clearPendingInviteCode = false,
  }) async {
    _syncCrashContextFromHome(lastAction: 'join_room_start');
    if (_joiningRoom) {
      return false;
    }
    final code = AppInviteLinkService.normalizeInviteCode(rawCode);
    if (code == null) {
      if (clearPendingInviteCode) {
        await AppInviteLinkService.instance.clearPendingInviteCode();
      }
      return false;
    }

    final l10n = AppLocalizations.of(context)!;
    _setStateForRoomManager(() => _joiningRoom = true);
    try {
      if (method == 'invite_link') {
        showJuiceSnackbar(
          context: context,
          message: l10n.roomInviteLinkJoining,
        );
      }
      final response = await Supabase.instance.client.rpc(
        'join_room_by_code',
        params: {'code': code},
      );
      final joinedRoomId = response is String ? response : null;
      await _fetchRooms();
      if (!mounted) {
        return true;
      }
      if (clearPendingInviteCode) {
        await AppInviteLinkService.instance.clearPendingInviteCode();
        if (!mounted) {
          return true;
        }
      }
      if (joinedRoomId != null && joinedRoomId.isNotEmpty) {
        if (_isRoomLocked(joinedRoomId)) {
          await _showRoomLockedDialog();
          if (!mounted) {
            return true;
          }
        } else {
          _enterRoomFromSelection(joinedRoomId);
        }
      }
      AnalyticsService.instance.logEvent(
        'room_join',
        parameters: {'method': method, 'result': 'success'},
      );
      _syncCrashContextFromHome(lastAction: 'join_room_success');
      showJuiceSnackbar(context: context, message: l10n.roomJoinSuccess);
      return true;
    } catch (error) {
      if (clearPendingInviteCode) {
        await AppInviteLinkService.instance.clearPendingInviteCode();
      }
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: StackTrace.current,
          source: 'home_join_room',
          fatal: false,
        ),
      );
      if (!mounted) {
        return false;
      }
      showJuiceToast(
        context: context,
        message: l10n.roomJoinFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
      return false;
    } finally {
      if (mounted) {
        _setStateForRoomManager(() => _joiningRoom = false);
      }
    }
  }

  Future<void> _joinRoomByCode() async {
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
                            textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
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

    await _joinRoomWithInviteCode(code, method: 'invite_code');
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
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        textAlign: TextAlign.center,
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
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.roomLeaveConfirm,
                        textAlign: TextAlign.center,
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
        _equippedItemsBySlot.clear();
        _ownedEquipmentItems.clear();
        _equipmentError = null;
        _equipmentLoading = false;
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
    final statusesFuture = _fetchEffectivePetStatuses(
      roomIds,
    ).catchError((_) => <String, PetStatusSnapshot>{});
    final rows = await Supabase.instance.client
        .from('pets')
        .select(
          'id, room_id, name, level, color_dna, '
          'pet_state(hunger, last_decay_at, mood, poop_at, '
          'mood_boost, mood_boost_expires_at)',
        )
        .inFilter('room_id', roomIds);
    final statuses = await statusesFuture;

    final summaries = <String, _RoomPetSummary>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      final state = row['pet_state'];
      Map<String, dynamic>? stateMap;
      if (state is Map) {
        stateMap = state.cast<String, dynamic>();
      } else if (state is List && state.isNotEmpty) {
        final first = state.first;
        if (first is Map) {
          stateMap = first.cast<String, dynamic>();
        }
      }
      final petType = PetCatalog.resolveIdForAppVersion(
        PetCatalog.typeFromColorDna(row['color_dna']),
        appVersion: _currentAppVersion,
      );
      final effectiveStatus = statuses[roomId];
      // The additive RPC is authoritative for display time, room timezone, and
      // mood rules. Keep the old projection only as a compatibility fallback
      // if the server migration is temporarily unavailable during rollout.
      final healthValue =
          effectiveStatus?.healthValue ??
          (stateMap == null
              ? _healthValueFromHunger(null)
              : projectHealthFromState(stateMap));
      summaries[roomId] = _RoomPetSummary(
        petType: petType,
        healthValue: healthValue,
        petName: (row['name'] as String?)?.trim(),
        petLevel: row['level'] as int?,
        petId: effectiveStatus?.petId ?? row['id'] as String?,
        petState: effectiveStatus?.petState,
      );
    }
    return summaries;
  }

  Future<Map<String, PetStatusSnapshot>> _fetchEffectivePetStatuses(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return const <String, PetStatusSnapshot>{};
    }
    final response = await Supabase.instance.client.rpc(
      'get_effective_room_pet_statuses',
      params: {'p_room_ids': roomIds},
    );
    final rows = response is List ? response : const <dynamic>[];
    final statuses = <String, PetStatusSnapshot>{};
    final receivedAt = DateTime.now().toUtc();
    for (final row in rows) {
      if (row is! Map) {
        continue;
      }
      try {
        final status = PetStatusSnapshot.fromRpcRow(
          Map<String, dynamic>.from(row),
          receivedAt: receivedAt,
        );
        statuses[status.roomId] = status;
      } on FormatException {
        // Ignore malformed rows without discarding valid room statuses.
      }
    }
    return statuses;
  }

  Future<Map<String, _RoomLatestFeed>> _fetchRoomLatestFeeds(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    // Server-side per-room top-N (see `get_room_latest_feeds`). The old direct
    // query used a single global LIMIT across all rooms, so a chatty room could
    // starve the others of their latest photos; the RPC dedupes by image and
    // limits independently per room.
    final response = await Supabase.instance.client.rpc(
      'get_room_latest_feeds',
      params: {
        'p_room_ids': roomIds,
        'p_per_room_limit': kPetHomeGalleryMaxPhotos,
      },
    );
    final rows = response is List ? response : const [];

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

  Future<Map<String, Map<String, String>>> _fetchRoomEquippedSkus(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    // The room-selection preview renders the room's MAIN pet, so scope the
    // equipped skus to each room's main_pet_id. A room can hold several pets
    // with their own gear; without this filter the preview shows a mix of
    // whichever rows came last and goes stale after a main-pet switch.
    final roomRows = await Supabase.instance.client
        .from('rooms')
        .select('id, main_pet_id')
        .inFilter('id', roomIds);
    final mainPetIdByRoom = <String, String>{};
    for (final row in roomRows) {
      final roomId = row['id'] as String?;
      final mainPetId = row['main_pet_id'] as String?;
      if (roomId != null && mainPetId != null) {
        mainPetIdByRoom[roomId] = mainPetId;
      }
    }
    if (mainPetIdByRoom.isEmpty) {
      return {};
    }

    final rows = await Supabase.instance.client
        .from('pet_equipment')
        .select('room_id, pet_id, slot, items(sku)')
        .inFilter('room_id', roomIds);

    final result = <String, Map<String, String>>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      final petId = row['pet_id'] as String?;
      final slot = row['slot'] as String?;
      final sku = _skuFromEquipmentRow(row);
      if (roomId == null ||
          roomId.isEmpty ||
          petId == null ||
          petId != mainPetIdByRoom[roomId] ||
          slot == null ||
          slot.isEmpty ||
          sku == null ||
          EquipmentCatalog.bySku(sku) == null) {
        continue;
      }
      (result[roomId] ??= <String, String>{})[slot] = sku;
    }
    return result;
  }

  String? _skuFromEquipmentRow(Map<String, dynamic> row) {
    final item = row['items'];
    if (item is Map) {
      return item['sku'] as String?;
    }
    if (item is List && item.isNotEmpty) {
      final first = item.first;
      if (first is Map) {
        return first['sku'] as String?;
      }
    }
    return null;
  }

  Future<Map<String, int>> _fetchRoomMemberCounts(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return {};
    }
    // Aggregated server-side (see `get_room_member_counts`) instead of pulling
    // every active member row back just to count them.
    final response = await Supabase.instance.client.rpc(
      'get_room_member_counts',
      params: {'p_room_ids': roomIds},
    );
    final rows = response is List ? response : const [];
    final counts = <String, int>{};
    for (final row in rows) {
      if (row is! Map) {
        continue;
      }
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      final raw = row['member_count'];
      final count = raw is int ? raw : (raw is num ? raw.toInt() : 0);
      counts[roomId] = count < 0 ? 0 : count;
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
