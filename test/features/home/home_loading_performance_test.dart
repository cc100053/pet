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
    expect(roomManagerSource, contains('_fetchRoomUnreadCounts(roomIds, userId)'));
    // Equipment stays best-effort and must not block the others.
    expect(roomManagerSource, contains('.catchError((_) => null)'));
  });

  test('Cold start does not refetch or re-tick the room list', () {
    // Pro-plan status (RevenueCat) must not gate first paint.
    expect(homeSource, contains('unawaited(_refreshProPlanStatus());'));
    // Rooms are fetched concurrently with the profile/coins reads.
    expect(homeSource, contains('final roomsFuture = _fetchRooms();'));
    expect(homeSource, contains('await roomsFuture;'));
    // Health is projected client-side, so cold start must NOT run a second full
    // room fetch or a per-pet tick storm just to surface satiety.
    expect(homeSource, isNot(contains('summariesOnly')));
    expect(homeSource, isNot(contains('_patchRoomSelectionPetSummaries')));
  });

  test('Room selection projects decay client-side instead of per-pet ticks', () {
    // The room-selection summaries fetch the decay anchor and project health
    // locally rather than ticking each pet over the network.
    expect(roomManagerSource, contains('projectHealthFromState('));
    expect(roomManagerSource, contains('last_decay_at, mood, poop_at'));
    // The old per-pet `tick_pet_state` storm on the selection screen (its
    // unique `pets` id/room_id fan-out read) is gone.
    expect(homeSource, isNot(contains("select('id, room_id')")));
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
    expect(roomManagerSource, contains('final cachedPetId = _petIdByRoom[roomId];'));
    expect(
      roomManagerSource,
      contains('final cachedPetState = _petStateByRoom[roomId];'),
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
      contains('unawaited(_dispatchNewHungerAlerts(petId: petId, roomId: roomId));'),
    );
  });
}
