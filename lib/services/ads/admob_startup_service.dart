import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../privacy/tracking_consent_service.dart';
import 'admob_ids.dart';

class AdMobStartupResult {
  const AdMobStartupResult({
    required this.initialized,
    required this.useNonPersonalizedAds,
  });

  final bool initialized;
  final bool useNonPersonalizedAds;

  AdRequest createAdRequest() =>
      AdRequest(nonPersonalizedAds: useNonPersonalizedAds);
}

class AdMobStartupService {
  AdMobStartupService({
    Future<bool> Function()? allowPersonalizedAdsResolver,
    Future<void> Function()? mobileAdsInitializer,
    Future<void> Function()? requestConfigurationUpdater,
    bool? adsSupported,
  }) : _allowPersonalizedAdsResolver =
           allowPersonalizedAdsResolver ??
           TrackingConsentService.instance.ensureTrackingAuthorization,
       _mobileAdsInitializer =
           mobileAdsInitializer ?? (() => MobileAds.instance.initialize()),
       _requestConfigurationUpdater =
           requestConfigurationUpdater ??
           (() => MobileAds.instance.updateRequestConfiguration(
             RequestConfiguration(testDeviceIds: AdMobIds.testDeviceIds),
           )),
       _adsSupported = adsSupported ?? AdMobIds.isSupported;

  AdMobStartupService._() : this();

  static final AdMobStartupService instance = AdMobStartupService._();

  final Future<bool> Function() _allowPersonalizedAdsResolver;
  final Future<void> Function() _mobileAdsInitializer;
  final Future<void> Function() _requestConfigurationUpdater;
  final bool _adsSupported;

  Future<AdMobStartupResult>? _inFlightInitialization;
  AdMobStartupResult? _cachedResult;

  Future<AdMobStartupResult> initialize() {
    final existing = _inFlightInitialization;
    if (existing != null) {
      return existing;
    }

    if (!_adsSupported) {
      return Future<AdMobStartupResult>.value(
        const AdMobStartupResult(
          initialized: false,
          useNonPersonalizedAds: false,
        ),
      );
    }

    final cached = _cachedResult;
    if (cached != null) {
      return Future<AdMobStartupResult>.value(cached);
    }

    final initializeFuture = _initializeInternal();
    _inFlightInitialization = initializeFuture;
    return initializeFuture.whenComplete(() {
      if (identical(_inFlightInitialization, initializeFuture)) {
        _inFlightInitialization = null;
      }
    });
  }

  AdRequest createAdRequest() {
    final result = _cachedResult;
    if (result == null) {
      return const AdRequest();
    }
    return result.createAdRequest();
  }

  Future<AdMobStartupResult> _initializeInternal() async {
    try {
      final allowPersonalizedAds = await _allowPersonalizedAdsResolver();
      await _requestConfigurationUpdater();
      await _mobileAdsInitializer();
      final result = AdMobStartupResult(
        initialized: true,
        useNonPersonalizedAds: !allowPersonalizedAds,
      );
      _cachedResult = result;
      return result;
    } catch (_) {
      _cachedResult = null;
      rethrow;
    }
  }
}
