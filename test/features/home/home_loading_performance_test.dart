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
    expect(roomManagerSource, contains('await Future.wait<Object>(['));
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
}
