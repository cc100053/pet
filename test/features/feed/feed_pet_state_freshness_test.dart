import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/feed/feed_pet_state_freshness.dart';
import 'package:pet/features/feed/feed_upload_models.dart';

/// Regression coverage for the intermittent "fed but the satiety bar didn't
/// move" bug. Root cause: the feed reward response carried no hunger, so the
/// client learned the new value out-of-band (realtime / refetch) with no
/// ordering guard, and a slow upload let a stale pre-feed snapshot win.
void main() {
  group('petStateSnapshotIsFresh (ordering guard)', () {
    final feedAnchor = DateTime.utc(2026, 6, 18, 5, 54, 33);
    final preFeedAnchor = DateTime.utc(2026, 6, 18, 5, 54, 7);
    final laterDecayAnchor = DateTime.utc(2026, 6, 18, 6, 30);

    test('drops a strictly older snapshot (the stale pre-feed tick)', () {
      // After applying the fed value (anchor = feed time), a pre-feed decay tick
      // read arriving late must NOT overwrite it.
      expect(
        petStateSnapshotIsFresh(held: feedAnchor, incoming: preFeedAnchor),
        isFalse,
      );
    });

    test('applies the fed value over a pre-feed baseline', () {
      expect(
        petStateSnapshotIsFresh(held: preFeedAnchor, incoming: feedAnchor),
        isTrue,
      );
    });

    test('applies a genuinely newer decay snapshot', () {
      expect(
        petStateSnapshotIsFresh(held: feedAnchor, incoming: laterDecayAnchor),
        isTrue,
      );
    });

    test(
      'applies an equal-anchor snapshot (clean/touch/overfed keep anchor)',
      () {
        expect(
          petStateSnapshotIsFresh(held: feedAnchor, incoming: feedAnchor),
          isTrue,
        );
      },
    );

    test('accepts snapshots that cannot be ordered (null anchors)', () {
      expect(petStateSnapshotIsFresh(held: null, incoming: feedAnchor), isTrue);
      expect(petStateSnapshotIsFresh(held: feedAnchor, incoming: null), isTrue);
      expect(petStateSnapshotIsFresh(held: null, incoming: null), isTrue);
    });
  });

  group('FeedUploadResult authoritative pet state', () {
    test('carries petState + overfed in memory and via copyWith', () {
      const result = FeedUploadResult(
        tempId: 't1',
        coinsAwarded: 10,
        petState: {'hunger': 75, 'last_decay_at': '2026-06-18T05:54:33Z'},
        overfed: false,
      );
      expect(result.petState?['hunger'], 75);
      expect(result.overfed, isFalse);

      final reconciled = result.copyWith(reconciled: true);
      expect(reconciled.petState?['hunger'], 75, reason: 'copyWith preserves');
      expect(reconciled.reconciled, isTrue);
    });

    test('petState/overfed are NOT persisted (durable queue shape stable)', () {
      const result = FeedUploadResult(
        tempId: 't1',
        coinsAwarded: 10,
        messageId: 'm1',
        petState: {'hunger': 75},
        overfed: true,
      );
      final json = result.toJson();
      expect(json.containsKey('pet_state'), isFalse);
      expect(json.containsKey('overfed'), isFalse);
      // Old persisted fields stay intact for backward compatibility.
      expect(json['coins_awarded'], 10);
      expect(json['message_id'], 'm1');

      // Reloading a previously persisted job must default the transient fields.
      final reloaded = FeedUploadResult.fromJson(json);
      expect(reloaded.petState, isNull);
      expect(reloaded.overfed, isFalse);
      expect(reloaded.coinsAwarded, 10);
    });
  });

  group('client + home wiring (source contracts)', () {
    String read(String path) => File(path).readAsStringSync();

    test('upload client parses pet_state + overfed from feed_validate', () {
      final src = read('lib/features/feed/feed_upload_client.dart');
      expect(src, contains("data['pet_state']"));
      expect(src, contains("overfed: data['overfed'] == true"));
    });

    test(
      'home applies authoritative pet state + optimistic gain under guard',
      () {
        final home = read('lib/features/home/home_view.dart');
        expect(home, contains('petStateSnapshotIsFresh'));
        expect(home, contains('_applyAuthoritativeFeedPetState'));
        expect(home, contains('_petStateDecayClockByPetId'));

        final orchestrator = read(
          'lib/features/home/controllers/home_feed_orchestrator.dart',
        );
        expect(orchestrator, contains('_applyAuthoritativeFeedPetState'));
        expect(orchestrator, contains('_applyOptimisticFeedHunger'));
      },
    );
  });
}
