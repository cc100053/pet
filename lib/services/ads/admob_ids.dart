import 'dart:io';

import 'package:flutter/foundation.dart';

import '../env.dart';

class AdMobIds {
  AdMobIds._();

  // Google official iOS test IDs.
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get isSupported => !kIsWeb && Platform.isIOS;

  static String get bannerAdUnitId {
    final configured = Env.adMobIosBannerAdUnitId;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return _iosTestBannerAdUnitId;
  }

  static String get rewardedAdUnitId {
    final configured = Env.adMobIosRewardedAdUnitId;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return _iosTestRewardedAdUnitId;
  }
}
