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

  test('Cold start does not fetch the room list twice', () {
    // Pro-plan status (RevenueCat) must not gate first paint.
    expect(homeSource, contains('unawaited(_refreshProPlanStatus());'));
    // Rooms are fetched concurrently with the profile/coins reads.
    expect(homeSource, contains('final roomsFuture = _fetchRooms();'));
    expect(homeSource, contains('await roomsFuture;'));
    // Health-bar refresh on cold start only patches summaries; it must not run
    // a second full _fetchRooms.
    expect(
      homeSource,
      contains('_refreshRoomSelectionHealthBars(summariesOnly: true)'),
    );
    expect(homeSource, contains('_patchRoomSelectionPetSummaries'));
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
