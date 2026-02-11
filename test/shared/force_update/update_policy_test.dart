import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/force_update/update_policy.dart';

void main() {
  group('AppUpdatePolicy.compareVersions', () {
    test('returns -1 when current is lower', () {
      expect(AppUpdatePolicy.compareVersions('1.2.3', '1.3.0'), -1);
    });

    test('returns 1 when current is higher', () {
      expect(AppUpdatePolicy.compareVersions('2.0.0', '1.9.9'), 1);
    });

    test('returns 0 for equivalent versions with build metadata', () {
      expect(AppUpdatePolicy.compareVersions('1.2.3+45', '1.2.3'), 0);
    });

    test('parses prerelease suffixes safely', () {
      expect(AppUpdatePolicy.compareVersions('1.2.3-beta', '1.2.3'), 0);
    });
  });

  group('AppUpdatePolicy.evaluate', () {
    test('returns hard when below minimum required version', () {
      final requirement = AppUpdatePolicy.evaluate(
        currentVersion: '1.1.0',
        minimumRequiredVersion: '1.2.0',
        latestAvailableVersion: '1.3.0',
      );
      expect(requirement, AppUpdateRequirement.hard);
    });

    test('returns soft when above minimum but below latest', () {
      final requirement = AppUpdatePolicy.evaluate(
        currentVersion: '1.2.0',
        minimumRequiredVersion: '1.2.0',
        latestAvailableVersion: '1.4.0',
      );
      expect(requirement, AppUpdateRequirement.soft);
    });

    test('returns none when on latest', () {
      final requirement = AppUpdatePolicy.evaluate(
        currentVersion: '1.4.0',
        minimumRequiredVersion: '1.2.0',
        latestAvailableVersion: '1.4.0',
      );
      expect(requirement, AppUpdateRequirement.none);
    });
  });
}
