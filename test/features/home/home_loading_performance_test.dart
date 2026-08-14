import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These tests assert on the *text* of the source they guard, so that an
/// intended structure (parallel fetches, fire-and-forget dispatch, a warm-entry
/// branch) cannot be quietly refactored away. That makes them sensitive to
/// something they should not care about: how the formatter happens to break
/// lines. A `dart format` pass is semantically null, but reflowing one of these
/// snippets across two lines used to turn a test red.
///
/// Collapsing every run of whitespace to a single space — in the source and in
/// the snippet alike — keeps the assertions about the code's shape while making
/// them indifferent to its layout.
String _squash(String source) => source.replaceAll(RegExp(r'\s+'), ' ').trim();

Matcher _containsCode(String snippet) => contains(_squash(snippet));

void main() {
  // Raw text, for the one assertion that needs real line structure.
  final homeSourceRaw = File(
    'lib/features/home/home_view.dart',
  ).readAsStringSync();

  final homeSource = _squash(homeSourceRaw);
  final roomManagerSource = _squash(
    File(
      'lib/features/home/controllers/home_room_manager.dart',
    ).readAsStringSync(),
  );

  test('Room selection fetches per-room summaries concurrently', () {
    // The five independent per-room queries must run in parallel instead of
    // five serial round-trips.
    expect(roomManagerSource, _containsCode('await Future.wait<Object?>(['));
    expect(roomManagerSource, _containsCode('_fetchRoomPetSummaries(roomIds)'));
    expect(roomManagerSource, _containsCode('_fetchRoomLatestFeeds(roomIds)'));
    expect(roomManagerSource, _containsCode('_fetchRoomMemberCounts(roomIds)'));
    expect(
      roomManagerSource,
      _containsCode('_fetchRoomUnreadCounts(roomIds, userId)'),
    );
    // Equipment stays best-effort and must not block the others.
    expect(roomManagerSource, _containsCode('.catchError((_) => null)'));
  });

  test('Cold start does not refetch or re-tick the room list', () {
    // Pro-plan status (RevenueCat) must not gate first paint.
    expect(homeSource, _containsCode('unawaited(_refreshProPlanStatus());'));
    // Rooms are fetched concurrently with the profile/coins reads.
    expect(homeSource, _containsCode('final roomsFuture = _fetchRooms();'));
    expect(homeSource, _containsCode('await roomsFuture;'));
    // The room list receives effective health in its existing parallel summary
    // load, so cold start must NOT run a second full fetch or per-pet tick storm.
    expect(homeSource, isNot(_containsCode('summariesOnly')));
    expect(homeSource, isNot(_containsCode('_patchRoomSelectionPetSummaries')));
  });

  test('Room selection loads effective health in one server request', () {
    expect(roomManagerSource, _containsCode('get_effective_room_pet_statuses'));
    expect(roomManagerSource, _containsCode('PetStatusSnapshot.fromRpcRow'));
    // Local projection remains only as a rollout fallback when an older backend
    // has not received the additive RPC yet.
    expect(roomManagerSource, _containsCode('projectHealthFromState('));
    expect(homeSource, isNot(_containsCode("select('id, room_id')")));
  });

  test('Periodic room-list health refresh is status-only', () {
    final refreshBody = RegExp(
      r'Future<void> _refreshRoomSelectionHealthBars\(\) async \{([\s\S]*?)\n  \}',
    ).firstMatch(homeSourceRaw)!.group(1)!;

    expect(refreshBody, _containsCode('_refreshEffectivePetStatusForRooms'));
    expect(refreshBody, isNot(_containsCode('_fetchRooms')));
  });

  test('Returning to Pet Home refreshes effective status immediately', () {
    expect(
      homeSource,
      _containsCode('_refreshEffectivePetStatusForRooms([activeRoomId])'),
    );
  });

  test('Cold room entry seeds the known pet id to skip a round-trip', () {
    expect(
      roomManagerSource,
      _containsCode(
        "final snapshotPetId = roomSnapshot?['pet_id'] as String?;",
      ),
    );
    expect(
      roomManagerSource,
      _containsCode('final knownPetId = cachedPetId ?? snapshotPetId;'),
    );
    expect(
      roomManagerSource,
      _containsCode('_petId = warmEntry ? cachedPetId : knownPetId;'),
    );
  });

  test('Room entry defers picker-only decor loads past first paint', () {
    expect(
      roomManagerSource,
      _containsCode('_scheduleDeferredRoomDecorLoads(roomId)'),
    );
    expect(roomManagerSource, _containsCode('addPostFrameCallback'));
  });

  test('Entering a previously-visited room paints instantly (warm entry)', () {
    // `var` (not `final`): the warm cache is nullable here so room entry can
    // evict a stale / cross-room cached pet id before painting it.
    expect(
      roomManagerSource,
      _containsCode('var cachedPetId = _petIdByRoom[roomId];'),
    );
    expect(
      roomManagerSource,
      _containsCode('var cachedPetState = _petStateByRoom[roomId];'),
    );
    expect(roomManagerSource, _containsCode('final warmEntry ='));
    // Warm entry skips the loading overlay and the artificial min-duration.
    expect(
      roomManagerSource,
      _containsCode('_roomEntryLoading = showEntryLoading && !warmEntry;'),
    );
    expect(
      roomManagerSource,
      _containsCode('if (showEntryLoading && !warmEntry) {'),
    );
  });

  test('Room entry does not block first paint on hunger alert dispatch', () {
    // Decay tick still awaited (health read depends on it), but alert dispatch
    // is fire-and-forget.
    expect(homeSource, _containsCode('await _tickPetStateRpc(petId);'));
    expect(
      homeSource,
      _containsCode(
        'unawaited(_dispatchNewHungerAlerts(petId: petId, roomId: roomId));',
      ),
    );
  });

  test(
    'Profile ensure and coins read share a round-trip for returning users',
    () {
      // First launch must stay serial: _ensureProfile inserts the row _loadCoins
      // reads, so parallelising it there can leave nickname/avatar blank.
      expect(homeSource, _containsCode('if (_myNickname == null) {'));
      expect(
        homeSource,
        _containsCode(
          'await Future.wait<void>([profileFuture, _loadCoins()]);',
        ),
      );
    },
  );

  test('Cold room entry paints the last known background', () {
    // Resolving the real background needs both room_background_state and the
    // owned-background list, and the latter is deferred past first paint.
    expect(
      homeSource,
      _containsCode(
        "_restoreCachedBackgroundKeys(snapshot['background_keys'])",
      ),
    );
    expect(homeSource, _containsCode("'background_keys': backgroundKeys,"));
    // Unknown/removed keys must not be resurrected as the default.
    expect(
      homeSource,
      _containsCode('RoomBackgrounds.supportsKey(backgroundKey)'),
    );

    final decorSource = _squash(
      File('lib/features/home/home_view_room_decor.dart').readAsStringSync(),
    );
    // "Not loaded yet" falls back to the cache; "explicitly none" must not.
    expect(
      decorSource,
      _containsCode('_activeBackgroundByRoom.containsKey(roomId)'),
    );
    expect(
      decorSource,
      _containsCode(
        'RoomBackgrounds.resolve(_cachedBackgroundKeyByRoom[roomId])',
      ),
    );
  });

  test(
    'Entry overlay is revealed on a delay rather than held to a minimum',
    () {
      // A fast cold entry should never blank the room; only an overlay the user
      // actually saw is held long enough not to flash.
      expect(homeSource, _containsCode('_roomEntryOverlayRevealDelay'));
      expect(
        roomManagerSource,
        _containsCode('_scheduleRoomEntryOverlayReveal(roomEntryToken);'),
      );
      expect(
        roomManagerSource,
        _containsCode(
          '_roomEntryOverlayVisible ? _roomEntryOverlayShownAt : null',
        ),
      );
      // The overlay gate must key off visibility, not the raw loading flag.
      expect(homeSource, _containsCode('if (_roomEntryOverlayVisible &&'));
    },
  );

  group('Room list cannot be lost by a silent fetch failure', () {
    test('A failed or session-less fetch retries instead of giving up', () {
      // The OAuth deep-link handoff can mount Home before the session lands,
      // and bootstrap only runs once per mount.
      expect(
        roomManagerSource,
        _containsCode("_noteRoomsFetchFailed('no_session')"),
      );
      expect(
        roomManagerSource,
        isNot(_containsCode('} catch (_) {\n    } finally {')),
      );
      expect(
        roomManagerSource,
        _containsCode('_noteRoomsFetchFailed(\'\$error\');'),
      );
      expect(
        roomManagerSource,
        _containsCode('_roomsRetryTimer = Timer(delay,'),
      );
      expect(homeSource, _containsCode('_roomsMaxRetryAttempts'));
    });

    test('An arriving session and app resume both re-run the fetch', () {
      expect(homeSource, _containsCode('onAuthStateChange'));
      expect(
        homeSource,
        _containsCode("_recoverRoomsIfNeeded('auth_state_change')"),
      );
      expect(homeSource, _containsCode("_recoverRoomsIfNeeded('app_resume')"));
      expect(
        roomManagerSource,
        _containsCode('Future<void> _recoverRoomsIfNeeded('),
      );
    });

    test('An unfetched room list is never persisted', () {
      // _loadCoins reaches the snapshot before _fetchRooms finishes; caching
      // the still-empty list is what made one failure survive restarts.
      expect(homeSource, _containsCode('if (!_roomsLoadedFromNetwork) {'));
    });

    test('Summary failures degrade badges instead of hiding the rooms', () {
      // The room list is already fetched by this point; a timeout on any
      // enrichment query must not abort into the outer catch.
      expect(roomManagerSource, _containsCode('Future<T?> degradable<T>('));
      expect(
        roomManagerSource,
        _containsCode("_logRoomsDiagnostic('summary_failed'"),
      );
      // Losing the unread query must not silently mark rooms as read.
      expect(
        roomManagerSource,
        _containsCode('previousUnreadByRoom[roomId] ?? 0'),
      );
    });

    test('One failed summary query does not discard the others', () {
      // Each query degrades on its own, and the fields it owns fall back to
      // their last known values — "0 members" and a blank health bar would
      // otherwise read as fresh data.
      expect(
        roomManagerSource,
        _containsCode(
          'final petSummaries = results[0] as Map<String, _RoomPetSummary>?;',
        ),
      );
      expect(
        roomManagerSource,
        _containsCode(
          '_carryOverRoomFields(room, previousRoom, _petSummaryRoomFields)',
        ),
      );
      expect(
        roomManagerSource,
        _containsCode(
          '_carryOverRoomFields(room, previousRoom, _latestFeedRoomFields)',
        ),
      );
      expect(
        roomManagerSource,
        _containsCode("(previousRoom?['member_count'] ?? 0)"),
      );
    });
  });
}
