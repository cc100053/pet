import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../privacy/tracking_consent_service.dart';
import 'admob_ids.dart';

class AdMobStartupService {
  AdMobStartupService._();

  static final AdMobStartupService instance = AdMobStartupService._();

  Future<void>? _inFlightInitialization;

  Future<bool> initializeIfAuthorized() async {
    if (!AdMobIds.isSupported) {
      return false;
    }

    final allowTracking = await TrackingConsentService.instance
        .ensureTrackingAuthorization();
    if (!allowTracking) {
      return false;
    }

    await _initializeMobileAds();
    return true;
  }

  Future<void> _initializeMobileAds() {
    final existing = _inFlightInitialization;
    if (existing != null) {
      return existing;
    }
    final initializeFuture = _initializeMobileAdsInternal();
    _inFlightInitialization = initializeFuture;
    return initializeFuture;
  }

  Future<void> _initializeMobileAdsInternal() async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      _inFlightInitialization = null;
      rethrow;
    }
  }
}
