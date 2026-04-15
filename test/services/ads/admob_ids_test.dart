import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/ads/admob_ids.dart';

void main() {
  group('AdMobIds.shouldEnableBannerViews', () {
    test('disables banner platform views when ads are unsupported', () {
      expect(
        AdMobIds.shouldEnableBannerViews(
          adsSupported: false,
          isDebugMode: false,
          debugOverrideEnabled: true,
        ),
        isFalse,
      );
    });

    test('keeps production banner platform views enabled', () {
      expect(
        AdMobIds.shouldEnableBannerViews(
          adsSupported: true,
          isDebugMode: false,
          debugOverrideEnabled: false,
        ),
        isTrue,
      );
    });

    test('disables debug banner platform views by default', () {
      expect(
        AdMobIds.shouldEnableBannerViews(
          adsSupported: true,
          isDebugMode: true,
          debugOverrideEnabled: false,
        ),
        isFalse,
      );
    });

    test('allows debug banner platform views with explicit override', () {
      expect(
        AdMobIds.shouldEnableBannerViews(
          adsSupported: true,
          isDebugMode: true,
          debugOverrideEnabled: true,
        ),
        isTrue,
      );
    });
  });
}
