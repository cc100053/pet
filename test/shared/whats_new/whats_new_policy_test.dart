import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/whats_new/app_whats_new_catalog.dart';
import 'package:pet/shared/whats_new/whats_new_policy.dart';

void main() {
  final entry105 = AppWhatsNewCatalog.entryForVersion('1.0.5');

  group('WhatsNewPolicy.evaluate', () {
    test('does not show on fresh install', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: null,
        lastShownVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('does not show on same-version relaunch', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.5',
        lastShownVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('shows on upgrade when current version has an entry', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.4',
        lastShownVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });

    test('does not repeat when the current version was already shown', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.4',
        lastShownVersion: '1.0.5',
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('shows only the current version entry after skipped upgrades', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.2',
        lastShownVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });

    test('does not show when the upgraded version has no local entry', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.6',
        previousVersion: '1.0.5',
        lastShownVersion: null,
        entry: AppWhatsNewCatalog.entryForVersion('1.0.6'),
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('does not show on downgrade or reinstall to an older version', () {
      final decision = WhatsNewPolicy.evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.6',
        lastShownVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });
  });
}
