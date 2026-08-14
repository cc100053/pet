import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/pet_hunger_projection.dart';

void main() {
  final now = DateTime.utc(2026, 6, 21, 12, 0, 0); // noon UTC, not "night"

  group('projectPetMood', () {
    test('hunger > 0 with no poop/boost is mid', () {
      expect(
        projectPetMood(
          hunger: 50,
          poopAt: null,
          nowUtc: now,
          isNight: false,
          moodBoost: 0,
        ),
        'mid',
      );
    });

    test('mood boost raises mid to high', () {
      expect(
        projectPetMood(
          hunger: 50,
          poopAt: null,
          nowUtc: now,
          isNight: false,
          moodBoost: 1,
        ),
        'high',
      );
    });

    test('zero hunger is sad', () {
      expect(
        projectPetMood(
          hunger: 0,
          poopAt: null,
          nowUtc: now,
          isNight: false,
          moodBoost: 0,
        ),
        'sad',
      );
    });

    test('long-standing poop penalty drops mood to sad (daytime only)', () {
      // elapsed 6h => penalty floor((6-2)/2)+1 = 3 => base 1-3 clamps to 0.
      final poopAt = now.subtract(const Duration(hours: 6));
      expect(
        projectPetMood(
          hunger: 80,
          poopAt: poopAt,
          nowUtc: now,
          isNight: false,
          moodBoost: 0,
        ),
        'sad',
      );
      // At night the poop penalty does not apply.
      expect(
        projectPetMood(
          hunger: 80,
          poopAt: poopAt,
          nowUtc: now,
          isNight: true,
          moodBoost: 0,
        ),
        'mid',
      );
    });
  });

  group('projectDecayedHunger', () {
    test('no elapsed time leaves hunger unchanged', () {
      expect(
        projectDecayedHunger(
          storedHunger: 88,
          lastDecayAt: now,
          nowUtc: now,
          poopAt: null,
          moodBoost: 0,
          moodBoostExpiresAt: null,
          isNight: false,
        ),
        88,
      );
    });

    test('mid mood decays at 3/hour (floored)', () {
      // 5h * 3 = 15 => 100 - 15 = 85.
      expect(
        projectDecayedHunger(
          storedHunger: 100,
          lastDecayAt: now.subtract(const Duration(hours: 5)),
          nowUtc: now,
          poopAt: null,
          moodBoost: 0,
          moodBoostExpiresAt: null,
          isNight: false,
        ),
        85,
      );
    });

    test('high mood (boost) decays at 2/hour', () {
      // 5h * 2 = 10 => 90.
      expect(
        projectDecayedHunger(
          storedHunger: 100,
          lastDecayAt: now.subtract(const Duration(hours: 5)),
          nowUtc: now,
          poopAt: null,
          moodBoost: 1,
          moodBoostExpiresAt: null,
          isNight: false,
        ),
        90,
      );
    });

    test('night halves the decay rate', () {
      // mid rate 3 * 0.5 = 1.5; 5h => floor(7.5) = 7 => 93.
      expect(
        projectDecayedHunger(
          storedHunger: 100,
          lastDecayAt: now.subtract(const Duration(hours: 5)),
          nowUtc: now,
          poopAt: null,
          moodBoost: 0,
          moodBoostExpiresAt: null,
          isNight: true,
        ),
        93,
      );
    });

    test('sad mood (poop penalty) decays at 4/hour', () {
      // poop elapsed 6h => sad; rate 4; 5h => 20 => 80.
      expect(
        projectDecayedHunger(
          storedHunger: 100,
          lastDecayAt: now.subtract(const Duration(hours: 5)),
          nowUtc: now,
          poopAt: now.subtract(const Duration(hours: 6)),
          moodBoost: 0,
          moodBoostExpiresAt: null,
          isNight: false,
        ),
        80,
      );
    });

    test('expired mood boost no longer keeps mood high', () {
      // Boost expired => mid (rate 3). 2h => 6 => 94.
      expect(
        projectDecayedHunger(
          storedHunger: 100,
          lastDecayAt: now.subtract(const Duration(hours: 2)),
          nowUtc: now,
          poopAt: null,
          moodBoost: 1,
          moodBoostExpiresAt: now.subtract(const Duration(minutes: 1)),
          isNight: false,
        ),
        94,
      );
    });

    test('decay clamps at zero', () {
      expect(
        projectDecayedHunger(
          storedHunger: 5,
          lastDecayAt: now.subtract(const Duration(hours: 50)),
          nowUtc: now,
          poopAt: null,
          moodBoost: 0,
          moodBoostExpiresAt: null,
          isNight: false,
        ),
        0,
      );
    });
  });

  group('projectHealthFromState', () {
    test('projects health (0..1) from a pet_state map', () {
      final state = <String, dynamic>{
        'hunger': 100,
        'last_decay_at': now
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'mood': 'mid',
        'poop_at': null,
        'mood_boost': 0,
        'mood_boost_expires_at': null,
      };
      // 5h mid => 85 => 0.85.
      expect(projectHealthFromState(state, now: now), closeTo(0.85, 1e-9));
    });

    test('falls back to raw hunger when anchor is missing', () {
      final state = <String, dynamic>{'hunger': 70};
      expect(projectHealthFromState(state, now: now), closeTo(0.70, 1e-9));
    });

    test('null state is zero', () {
      expect(projectHealthFromState(null, now: now), 0.0);
    });
  });
}
