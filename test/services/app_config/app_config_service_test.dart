import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/app_config/app_config_service.dart';
import 'package:pet/services/app_config/app_store_lookup_service.dart';

void main() {
  late TargetPlatform? previousPlatform;

  setUp(() {
    previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test(
    'falls back to App Store lookup when Supabase config is unavailable',
    () async {
      final service = AppConfigService(
        configValueLoader: (_) async => null,
        appStoreVersionLookupService: _FakeAppStoreVersionLookupService(
          const AppStoreVersionLookupResult(
            version: '1.0.3',
            storeUrl: 'https://apps.apple.com/app/id6757725650',
          ),
        ),
      );

      final config = await service.fetchForceUpdateConfig();

      expect(config, isNotNull);
      expect(config!.minimumRequiredVersion, '0.0.0');
      expect(config.latestAvailableVersion, '1.0.3');
      expect(config.storeUrl, 'https://apps.apple.com/app/id6757725650');
    },
  );

  test(
    'uses the highest available version across config and App Store data',
    () async {
      final values = <String, dynamic>{
        'minimum_required_version': {'ios': '1.0.0'},
        'latest_available_version': {'ios': '1.0.2'},
        'store_url': {'ios': 'https://apps.apple.com/app/id6757725650'},
      };
      final service = AppConfigService(
        configValueLoader: (key) async => values[key],
        appStoreVersionLookupService: _FakeAppStoreVersionLookupService(
          const AppStoreVersionLookupResult(
            version: '1.0.4',
            storeUrl: 'https://apps.apple.com/app/id6757725650?mt=8',
          ),
        ),
      );

      final config = await service.fetchForceUpdateConfig();

      expect(config, isNotNull);
      expect(config!.minimumRequiredVersion, '1.0.0');
      expect(config.latestAvailableVersion, '1.0.4');
      expect(config.storeUrl, 'https://apps.apple.com/app/id6757725650?mt=8');
    },
  );
}

class _FakeAppStoreVersionLookupService extends AppStoreVersionLookupService {
  _FakeAppStoreVersionLookupService(this.result);

  final AppStoreVersionLookupResult? result;

  @override
  Future<AppStoreVersionLookupResult?> fetchLatestVersion() async => result;
}
