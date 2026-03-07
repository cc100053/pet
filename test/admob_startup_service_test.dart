import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/ads/admob_startup_service.dart';

void main() {
  test(
    'initializes AdMob and uses non-personalized ads when ATT is denied',
    () async {
      var initializeCalls = 0;
      final service = AdMobStartupService(
        allowPersonalizedAdsResolver: () async => false,
        mobileAdsInitializer: () async {
          initializeCalls += 1;
        },
        adsSupported: true,
      );

      final result = await service.initialize();

      expect(result.initialized, isTrue);
      expect(result.useNonPersonalizedAds, isTrue);
      expect(service.createAdRequest().nonPersonalizedAds, isTrue);
      expect(initializeCalls, 1);
    },
  );

  test('uses personalized ads when ATT is authorized', () async {
    final service = AdMobStartupService(
      allowPersonalizedAdsResolver: () async => true,
      mobileAdsInitializer: () async {},
      adsSupported: true,
    );

    final result = await service.initialize();

    expect(result.initialized, isTrue);
    expect(result.useNonPersonalizedAds, isFalse);
    expect(service.createAdRequest().nonPersonalizedAds, isFalse);
  });

  test('caches initialization result across repeated calls', () async {
    var initializeCalls = 0;
    var trackingCalls = 0;
    final service = AdMobStartupService(
      allowPersonalizedAdsResolver: () async {
        trackingCalls += 1;
        return false;
      },
      mobileAdsInitializer: () async {
        initializeCalls += 1;
      },
      adsSupported: true,
    );

    await service.initialize();
    await service.initialize();

    expect(trackingCalls, 1);
    expect(initializeCalls, 1);
    expect(service.createAdRequest().nonPersonalizedAds, isTrue);
  });
}
