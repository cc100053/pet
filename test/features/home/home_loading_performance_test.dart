import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final homeSource = File(
    'lib/features/home/home_view.dart',
  ).readAsStringSync();
  final roomManagerSource = File(
    'lib/features/home/controllers/home_room_manager.dart',
  ).readAsStringSync();

  test('Room selection fetches per-room summaries concurrently', () {
    // The five independent per-room queries must run in parallel instead of
    // five serial round-trips.
    expect(roomManagerSource, contains('await Future.wait<Object?>(['));
    expect(roomManagerSource, contains('_fetchRoomPetSummaries(roomIds)'));
    expect(roomManagerSource, contains('_fetchRoomLatestFeeds(roomIds)'));
    expect(roomManagerSource, contains('_fetchRoomMemberCounts(roomIds)'));
    expect(
      roomManagerSource,
      contains('_fetchRoomUnreadCounts(roomIds, userId)'),
    );
    // Equipment stays best-effort and must not block the others.
    expect(roomManagerSource, contains('.catchError((_) => null)'));
  });

  test('Cold start does not refetch or re-tick the room list', () {
    // Pro-plan status (RevenueCat) must not gate first paint.
    expect(homeSource, contains('unawaited(_refreshProPlanStatus());'));
    // Rooms are fetched concurrently with the profile/coins reads.
    expect(homeSource, contains('final roomsFuture = _fetchRooms();'));
    expect(homeSource, contains('await roomsFuture;'));
    // The room list receives effective health in its existing parallel summary
    // load, so cold start must NOT run a second full fetch or per-pet tick storm.
    expect(homeSource, isNot(contains('summariesOnly')));
    expect(homeSource, isNot(contains('_patchRoomSelectionPetSummaries')));
  });

  test('Room selection loads effective health in one server request', () {
    expect(roomManagerSource, contains('get_effective_room_pet_statuses'));
    expect(roomManagerSource, contains('PetStatusSnapshot.fromRpcRow'));
    // Local projection remains only as a rollout fallback when an older backend
    // has not received the additive RPC yet.
    expect(roomManagerSource, contains('projectHealthFromState('));
    expect(homeSource, isNot(contains("select('id, room_id')")));
  });

  test('Periodic room-list health refresh is status-only', () {
    final refreshBody = RegExp(
      r'Future<void> _refreshRoomSelectionHealthBars\(\) async \{([\s\S]*?)\n  \}',
    ).firstMatch(homeSource)!.group(1)!;

    expect(refreshBody, contains('_refreshEffectivePetStatusForRooms'));
    expect(refreshBody, isNot(contains('_fetchRooms')));
  });

  test('Returning to Pet Home refreshes effective status immediately', () {
    expect(
      homeSource,
      contains('_refreshEffectivePetStatusForRooms([activeRoomId])'),
    );
  });

  test('Cold room entry seeds the known pet id to skip a round-trip', () {
    expect(
      roomManagerSource,
      contains("final snapshotPetId = roomSnapshot?['pet_id'] as String?;"),
    );
    expect(
      roomManagerSource,
      contains('final knownPetId = cachedPetId ?? snapshotPetId;'),
    );
    expect(
      roomManagerSource,
      contains('_petId = warmEntry ? cachedPetId : knownPetId;'),
    );
  });

  test('Room entry defers picker-only decor loads past first paint', () {
    expect(
      roomManagerSource,
      contains('_scheduleDeferredRoomDecorLoads(roomId)'),
    );
    expect(roomManagerSource, contains('addPostFrameCallback'));
  });

  test('Entering a previously-visited room paints instantly (warm entry)', () {
    // `var` (not `final`): the warm cache is nullable here so room entry can
    // evict a stale / cross-room cached pet id before painting it.
    expect(
      roomManagerSource,
      contains('var cachedPetId = _petIdByRoom[roomId];'),
    );
    expect(
      roomManagerSource,
      contains('var cachedPetState = _petStateByRoom[roomId];'),
    );
    expect(roomManagerSource, contains('final warmEntry ='));
    // Warm entry skips the loading overlay and the artificial min-duration.
    expect(
      roomManagerSource,
      contains('_roomEntryLoading = showEntryLoading && !warmEntry;'),
    );
    expect(
      roomManagerSource,
      contains('if (showEntryLoading && !warmEntry) {'),
    );
  });

  test('Room entry does not block first paint on hunger alert dispatch', () {
    // Decay tick still awaited (health read depends on it), but alert dispatch
    // is fire-and-forget.
    expect(homeSource, contains('await _tickPetStateRpc(petId);'));
    expect(
      homeSource,
      contains(
        'unawaited(_dispatchNewHungerAlerts(petId: petId, roomId: roomId));',
      ),
    );
  });

  test('Profile ensure and coins read share a round-trip for returning users', () {
    // First launch must stay serial: _ensureProfile inserts the row _loadCoins
    // reads, so parallelising it there can leave nickname/avatar blank.
    expect(homeSource, contains('if (_myNickname == null) {'));
    expect(
      homeSource,
      contains('await Future.wait<void>([profileFuture, _loadCoins()]);'),
    );
  });

  test('Cold room entry paints the last known background', () {
    // Resolving the real background needs both room_background_state and the
    // owned-background list, and the latter is deferred past first paint.
    expect(homeSource, contains("_restoreCachedBackgroundKeys(snapshot['background_keys'])"));
    expect(homeSource, contains("'background_keys': backgroundKeys,"));
    // Unknown/removed keys must not be resurrected as the default.
    expect(homeSource, contains('RoomBackgrounds.supportsKey(backgroundKey)'));

    final decorSource = File(
      'lib/features/home/home_view_room_decor.dart',
    ).readAsStringSync();
    // "Not loaded yet" falls back to the cache; "explicitly none" must not.
    expect(
      decorSource,
      contains('_activeBackgroundByRoom.containsKey(roomId)'),
    );
    expect(
      decorSource,
      contains('RoomBackgrounds.resolve(_cachedBackgroundKeyByRoom[roomId])'),
    );
  });

  test('Entry overlay is revealed on a delay rather than held to a minimum', () {
    // A fast cold entry should never blank the room; only an overlay the user
    // actually saw is held long enough not to flash.
    expect(homeSource, contains('_roomEntryOverlayRevealDelay'));
    expect(
      roomManagerSource,
      contains('_scheduleRoomEntryOverlayReveal(roomEntryToken);'),
    );
    expect(
      roomManagerSource,
      contains('_roomEntryOverlayVisible ? _roomEntryOverlayShownAt : null'),
    );
    // The overlay gate must key off visibility, not the raw loading flag.
    expect(homeSource, contains('if (_roomEntryOverlayVisible &&'));
  });

  group('Room list cannot be lost by a silent fetch failure', () {
    test('A failed or session-less fetch retries instead of giving up', () {
      // The OAuth deep-link handoff can mount Home before the session lands,
      // and bootstrap only runs once per mount.
      expect(roomManagerSource, contains("_noteRoomsFetchFailed('no_session')"));
      expect(roomManagerSource, isNot(contains('} catch (_) {\n    } finally {')));
      expect(roomManagerSource, contains('_noteRoomsFetchFailed(\'\$error\');'));
      expect(roomManagerSource, contains('_roomsRetryTimer = Timer(delay,'));
      expect(homeSource, contains('_roomsMaxRetryAttempts'));
    });

    test('An arriving session and app resume both re-run the fetch', () {
      expect(homeSource, contains('onAuthStateChange'));
      expect(
        homeSource,
        contains("_recoverRoomsIfNeeded('auth_state_change')"),
      );
      expect(homeSource, contains("_recoverRoomsIfNeeded('app_resume')"));
      expect(roomManagerSource, contains('Future<void> _recoverRoomsIfNeeded('));
    });

    test('An unfetched room list is never persisted', () {
      // _loadCoins reaches the snapshot before _fetchRooms finishes; caching
      // the still-empty list is what made one failure survive restarts.
      expect(homeSource, contains('if (!_roomsLoadedFromNetwork) {'));
    });

    test('Summary failures degrade badges instead of hiding the rooms', () {
      // The room list is already fetched by this point; a timeout on any
      // enrichment query must not abort into the outer catch.
      expect(roomManagerSource, contains('Future<T?> degradable<T>('));
      expect(roomManagerSource, contains("_logRoomsDiagnostic('summary_failed'"));
      // Losing the unread query must not silently mark rooms as read.
      expect(roomManagerSource, contains('previousUnreadByRoom[roomId] ?? 0'));
    });

    test('One failed summary query does not discard the others', () {
      // Each query degrades on its own, and the fields it owns fall back to
      // their last known values — "0 members" and a blank health bar would
      // otherwise read as fresh data.
      expect(roomManagerSource, contains('final petSummaries = results[0] as Map<String, _RoomPetSummary>?;'));
      expect(roomManagerSource, contains('_carryOverRoomFields(room, previousRoom, _petSummaryRoomFields)'));
      expect(roomManagerSource, contains('_carryOverRoomFields(room, previousRoom, _latestFeedRoomFields)'));
      expect(roomManagerSource, contains("(previousRoom?['member_count'] ?? 0)"));
    });
  });
}
