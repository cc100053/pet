import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/whats_new/app_whats_new_catalog.dart';
import 'package:pet/shared/whats_new/app_whats_new_entry.dart';
import 'package:pet/shared/whats_new/whats_new_policy.dart';

void main() {
  final entry230 = AppWhatsNewCatalog.entryForVersion('2.3.0');
  final entry110 = AppWhatsNewCatalog.entryForVersion('1.1.0');
  final entry105 = AppWhatsNewCatalog.entryForVersion('1.0.5');

  group('AppWhatsNewCatalog', () {
    test('contains 2.3.0 entry with two meaningful bullets', () {
      expect(entry230, isNotNull);
      expect(entry230?.version, '2.3.0');
      expect(entry230?.bulletBuilders.length, 2);
    });

    test('contains 1.1.0 entry', () {
      expect(entry110, isNotNull);
      expect(entry110?.version, '1.1.0');
      expect(entry110?.bulletBuilders.length, 3);
    });
  });

  group('WhatsNewPolicy.evaluate', () {
    test('does not show on fresh install', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: null,
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('does not show on same-version relaunch', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.5',
        previousReleaseSignature: '1.0.5+1',
        currentReleaseSignature: '1.0.5+1',
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('shows on upgrade when current version has an entry', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.4',
        previousReleaseSignature: '1.0.4+9',
        currentReleaseSignature: '1.0.5+1',
        entry: entry105,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });

    test('does not repeat when the current version was already shown', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.4',
        previousReleaseSignature: '1.0.4+9',
        currentReleaseSignature: '1.0.5+1',
        lastShownVersion: '1.0.5',
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('shows only the current version entry after skipped upgrades', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.2',
        previousReleaseSignature: '1.0.2+1',
        currentReleaseSignature: '1.0.5+1',
        entry: entry105,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });

    test('does not show when the upgraded version has no local entry', () {
      final decision = _evaluate(
        currentVersion: '1.0.7',
        previousVersion: '1.0.6',
        previousReleaseSignature: '1.0.6+1',
        currentReleaseSignature: '1.0.7+1',
        entry: AppWhatsNewCatalog.entryForVersion('1.0.7'),
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('does not show on downgrade or reinstall to an older version', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.6',
        previousReleaseSignature: '1.0.6+1',
        currentReleaseSignature: '1.0.5+1',
        entry: entry105,
      );

      expect(decision.shouldShow, isFalse);
      expect(decision.entry, isNull);
    });

    test('shows on same-version build upgrade when not shown before', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: '1.0.5',
        previousReleaseSignature: '1.0.5+1',
        currentReleaseSignature: '1.0.5+2',
        entry: entry105,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });

    test('shows for existing installs that predate version tracking', () {
      final decision = _evaluate(
        currentVersion: '1.0.5',
        previousVersion: null,
        currentReleaseSignature: '1.0.5+1',
        entry: entry105,
        hadExistingInstallBeforeVersionTracking: true,
      );

      expect(decision.shouldShow, isTrue);
      expect(decision.entry?.version, '1.0.5');
    });
  });
}

WhatsNewDecision _evaluate({
  required String currentVersion,
  required AppWhatsNewEntry? entry,
  String currentReleaseSignature = '1.0.5+1',
  String? previousVersion,
  String? previousReleaseSignature,
  String? lastShownVersion,
  bool hadExistingInstallBeforeVersionTracking = false,
}) {
  return WhatsNewPolicy.evaluate(
    currentVersion: currentVersion,
    currentReleaseSignature: currentReleaseSignature,
    previousVersion: previousVersion,
    previousReleaseSignature: previousReleaseSignature,
    lastShownVersion: lastShownVersion,
    entry: entry,
    hadExistingInstallBeforeVersionTracking:
        hadExistingInstallBeforeVersionTracking,
  );
}
