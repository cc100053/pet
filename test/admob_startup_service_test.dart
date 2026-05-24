import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/ads/admob_startup_service.dart';

AdMobStartupService _makeService({
  Future<bool> Function()? allowPersonalizedAdsResolver,
  Future<void> Function()? mobileAdsInitializer,
  Future<void> Function()? requestConfigurationUpdater,
}) {
  return AdMobStartupService(
    allowPersonalizedAdsResolver:
        allowPersonalizedAdsResolver ?? () async => false,
    mobileAdsInitializer: mobileAdsInitializer ?? () async {},
    requestConfigurationUpdater: requestConfigurationUpdater ?? () async {},
    adsSupported: true,
  );
}

void main() {
  test(
    'initializes AdMob and uses non-personalized ads when ATT is denied',
    () async {
      var initializeCalls = 0;
      final service = _makeService(
        allowPersonalizedAdsResolver: () async => false,
        mobileAdsInitializer: () async {
          initializeCalls += 1;
        },
      );

      final result = await service.initialize();

      expect(result.initialized, isTrue);
      expect(result.useNonPersonalizedAds, isTrue);
      expect(service.createAdRequest().nonPersonalizedAds, isTrue);
      expect(initializeCalls, 1);
    },
  );

  test('uses personalized ads when ATT is authorized', () async {
    final service = _makeService(allowPersonalizedAdsResolver: () async => true);

    final result = await service.initialize();

    expect(result.initialized, isTrue);
    expect(result.useNonPersonalizedAds, isFalse);
    expect(service.createAdRequest().nonPersonalizedAds, isFalse);
  });

  test('caches initialization result across repeated calls', () async {
    var initializeCalls = 0;
    var trackingCalls = 0;
    final service = _makeService(
      allowPersonalizedAdsResolver: () async {
        trackingCalls += 1;
        return false;
      },
      mobileAdsInitializer: () async {
        initializeCalls += 1;
      },
    );

    await service.initialize();
    await service.initialize();

    expect(trackingCalls, 1);
    expect(initializeCalls, 1);
    expect(service.createAdRequest().nonPersonalizedAds, isTrue);
  });

  test('updates request configuration before initializing', () async {
    var configCallOrder = 0;
    var initCallOrder = 0;
    var callCounter = 0;

    final service = _makeService(
      requestConfigurationUpdater: () async {
        configCallOrder = ++callCounter;
      },
      mobileAdsInitializer: () async {
        initCallOrder = ++callCounter;
      },
    );

    await service.initialize();

    expect(configCallOrder, lessThan(initCallOrder));
  });
}
