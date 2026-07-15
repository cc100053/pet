const String petStatusEffectiveHungerKey = '_effective_hunger';
const String petStatusComputedAtKey = '_status_computed_at';
const String petStatusReceivedAtKey = '_status_received_at';

class PetStatusSnapshot {
  PetStatusSnapshot._({
    required this.roomId,
    required this.petId,
    required this.effectiveHunger,
    required this.computedAt,
    required this.receivedAt,
    required this.petState,
  });

  factory PetStatusSnapshot.fromRpcRow(
    Map<String, dynamic> row, {
    DateTime? receivedAt,
  }) {
    final roomId = row['room_id'] as String?;
    final petId = row['pet_id'] as String?;
    final hunger = (row['effective_hunger'] as num?)?.toInt();
    final computedAt = DateTime.tryParse(row['computed_at'] as String? ?? '');
    final rawState = row['pet_state'];
    if (roomId == null ||
        roomId.isEmpty ||
        petId == null ||
        petId.isEmpty ||
        hunger == null ||
        computedAt == null ||
        rawState is! Map) {
      throw const FormatException('invalid_effective_pet_status');
    }

    final safeHunger = hunger.clamp(0, 100);
    final normalizedComputedAt = computedAt.toUtc();
    final normalizedReceivedAt = (receivedAt ?? DateTime.now()).toUtc();
    final state = <String, dynamic>{
      ...Map<String, dynamic>.from(rawState),
      'pet_id': petId,
      'hunger': safeHunger,
      petStatusEffectiveHungerKey: safeHunger,
      petStatusComputedAtKey: normalizedComputedAt.toIso8601String(),
      petStatusReceivedAtKey: normalizedReceivedAt.toIso8601String(),
    };

    return PetStatusSnapshot._(
      roomId: roomId,
      petId: petId,
      effectiveHunger: safeHunger,
      computedAt: normalizedComputedAt,
      receivedAt: normalizedReceivedAt,
      petState: state,
    );
  }

  final String roomId;
  final String petId;
  final int effectiveHunger;
  final DateTime computedAt;
  final DateTime receivedAt;
  final Map<String, dynamic> petState;

  double get healthValue => effectiveHunger / 100.0;
}

num? petStatusHunger(Map<String, dynamic>? state) {
  if (state == null) {
    return null;
  }
  return state[petStatusEffectiveHungerKey] as num? ?? state['hunger'] as num?;
}

Map<String, dynamic> stampAuthoritativePetState(
  Map<String, dynamic> state, {
  DateTime? receivedAt,
}) {
  final hunger = (state['hunger'] as num?)?.toInt();
  if (hunger == null) {
    return Map<String, dynamic>.from(state);
  }
  final safeHunger = hunger.clamp(0, 100);
  final timestamp = (receivedAt ?? DateTime.now()).toUtc().toIso8601String();
  return <String, dynamic>{
    ...state,
    'hunger': safeHunger,
    petStatusEffectiveHungerKey: safeHunger,
    petStatusComputedAtKey: timestamp,
    petStatusReceivedAtKey: timestamp,
  };
}
