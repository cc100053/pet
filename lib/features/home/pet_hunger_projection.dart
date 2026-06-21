/// Client-side projection of passive hunger decay, mirroring the server
/// `compute_pet_mood` + `tick_pet_state` formulas (latest definitions:
/// `20260216233000_rebalance_mood_decay_and_feed_gain.sql` for mood and
/// `20260521143000_add_room_hunger_freeze_debug_override.sql` for decay).
///
/// Why this exists: the room-selection health bars and (cheap) re-projection no
/// longer need a per-pet `tick_pet_state` round-trip just to show the current
/// satiety. The stored `hunger` + `last_decay_at` anchor are enough to compute
/// the value the next server tick would commit. This is a DISPLAY estimate
/// only; the server tick stays authoritative and reconciles through realtime /
/// refetch (and the 20-minute `hunger_tick_dispatch` cron).
///
/// Known divergences (all self-healing on the next authoritative read):
/// - Night detection uses the device-local hour, not the room timezone.
/// - The admin-only `room_debug_overrides` hunger freeze is invisible to the
///   client (RLS), so a frozen room would still appear to decay here until the
///   next realtime/refetch snapshot lands.
library;

import '../../shared/utils/date_parsing.dart';

/// Effective mood ('sad' | 'mid' | 'high'), mirroring `compute_pet_mood`.
String projectPetMood({
  required int hunger,
  required DateTime? poopAt,
  required DateTime nowUtc,
  required bool isNight,
  required int moodBoost,
}) {
  var base = hunger <= 0 ? 0 : 1;
  var penalty = 0;
  if (poopAt != null && !isNight) {
    final elapsedHours = nowUtc.difference(poopAt).inMilliseconds / 3600000.0;
    if (elapsedHours >= 2) {
      penalty = ((elapsedHours - 2) / 2).floor() + 1;
    }
  }
  base = base - penalty;
  if (base < 0) base = 0;
  final boost = moodBoost < 0 ? 0 : (moodBoost > 1 ? 1 : moodBoost);
  var effective = base + boost;
  if (effective > 2) effective = 2;
  return switch (effective) {
    0 => 'sad',
    1 => 'mid',
    _ => 'high',
  };
}

/// Projects `storedHunger` forward from its `lastDecayAt` anchor to `nowUtc`
/// using the same single-rate decay a server tick applies.
int projectDecayedHunger({
  required int storedHunger,
  required DateTime lastDecayAt,
  required DateTime nowUtc,
  required DateTime? poopAt,
  required int moodBoost,
  required DateTime? moodBoostExpiresAt,
  required bool isNight,
}) {
  if (storedHunger <= 0) {
    return 0;
  }
  if (!nowUtc.isAfter(lastDecayAt)) {
    return storedHunger;
  }
  var effectiveBoost = moodBoost;
  if (moodBoostExpiresAt != null && !moodBoostExpiresAt.isAfter(nowUtc)) {
    effectiveBoost = 0;
  }
  final mood = projectPetMood(
    hunger: storedHunger,
    poopAt: poopAt,
    nowUtc: nowUtc,
    isNight: isNight,
    moodBoost: effectiveBoost,
  );
  var rate = switch (mood) {
    'high' => 2.0,
    'sad' => 4.0,
    _ => 3.0,
  };
  if (isNight) {
    rate *= 0.5;
  }
  final hours = nowUtc.difference(lastDecayAt).inMilliseconds / 3600000.0;
  final decay = (hours * rate).floor();
  final projected = storedHunger - decay;
  return projected < 0 ? 0 : projected;
}

/// True when the device-local hour falls in the server's night window (0–7),
/// where decay runs at half rate.
bool isLocalNightHour([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  return hour >= 0 && hour <= 7;
}

/// Projects the satiety/health value (0.0–1.0) for a `pet_state`-shaped map.
/// Falls back to the raw stored hunger when the decay anchor is missing.
double projectHealthFromState(Map<String, dynamic>? state, {DateTime? now}) {
  if (state == null) {
    return 0.0;
  }
  final hunger = (state['hunger'] as num?)?.toInt();
  if (hunger == null) {
    return 0.0;
  }
  final nowUtc = (now ?? DateTime.now()).toUtc();
  final lastDecayAt = parseOptionalDate(state['last_decay_at'])?.toUtc();
  final projected = lastDecayAt == null
      ? hunger
      : projectDecayedHunger(
          storedHunger: hunger,
          lastDecayAt: lastDecayAt,
          nowUtc: nowUtc,
          poopAt: parseOptionalDate(state['poop_at'])?.toUtc(),
          moodBoost: (state['mood_boost'] as num?)?.toInt() ?? 0,
          moodBoostExpiresAt: parseOptionalDate(
            state['mood_boost_expires_at'],
          )?.toUtc(),
          isNight: isLocalNightHour(now),
        );
  final value = projected / 100.0;
  return value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
}
