import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/pet_status_snapshot.dart';

void main() {
  test(
    'RPC snapshot normalizes effective hunger for every client consumer',
    () {
      final snapshot = PetStatusSnapshot.fromRpcRow({
        'room_id': 'room-1',
        'pet_id': 'pet-1',
        'effective_hunger': 61,
        'computed_at': '2026-07-16T03:00:00Z',
        'pet_state': {
          'hunger': 70,
          'last_decay_at': '2026-07-16T00:00:00Z',
          'mood': 'mid',
        },
      }, receivedAt: DateTime.utc(2026, 7, 16, 3, 0, 1));

      expect(snapshot.roomId, 'room-1');
      expect(snapshot.petId, 'pet-1');
      expect(snapshot.effectiveHunger, 61);
      expect(snapshot.petState['hunger'], 61);
      expect(snapshot.petState['last_decay_at'], '2026-07-16T00:00:00Z');
      expect(
        snapshot.petState[petStatusComputedAtKey],
        '2026-07-16T03:00:00.000Z',
      );
      expect(
        snapshot.petState[petStatusReceivedAtKey],
        '2026-07-16T03:00:01.000Z',
      );
      expect(petStatusHunger(snapshot.petState), 61);
      expect(snapshot.healthValue, 0.61);
    },
  );

  test('authoritative rows replace stale effective-status metadata', () {
    final normalized = stampAuthoritativePetState({
      'hunger': 86,
      petStatusEffectiveHungerKey: 61,
      petStatusComputedAtKey: '2026-07-16T03:00:00Z',
    }, receivedAt: DateTime.utc(2026, 7, 16, 4));

    expect(petStatusHunger(normalized), 86);
    expect(normalized[petStatusEffectiveHungerKey], 86);
    expect(normalized[petStatusComputedAtKey], '2026-07-16T04:00:00.000Z');
  });

  test('invalid RPC rows are rejected at the boundary', () {
    expect(
      () => PetStatusSnapshot.fromRpcRow({
        'room_id': 'room-1',
        'effective_hunger': 50,
        'computed_at': '2026-07-16T03:00:00Z',
        'pet_state': {'hunger': 50},
      }),
      throwsFormatException,
    );
  });
}
