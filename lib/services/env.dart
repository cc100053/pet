import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String? get revenueCatApiKeyIos => _optional('REVENUECAT_API_KEY_IOS');
  static String? get revenueCatApiKeyAndroid =>
      _optional('REVENUECAT_API_KEY_ANDROID');
  static String? get adMobIosBannerAdUnitId =>
      _optional('ADMOB_IOS_BANNER_AD_UNIT_ID');
  static String? get adMobIosRewardedAdUnitId =>
      _optional('ADMOB_IOS_REWARDED_AD_UNIT_ID');
  static bool get adMobEnableDebugBannerViews =>
      _optionalBool('ADMOB_ENABLE_DEBUG_BANNER_VIEWS') ?? false;
  static List<String> get adMobTestDeviceIds {
    final raw = _optional('ADMOB_TEST_DEVICE_IDS');
    if (raw == null) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int get adRewardCoins => _optionalInt('AD_REWARD_COINS') ?? 10;
  static String get privacyPolicyUrl => _require('PRIVACY_POLICY_URL');
  static String get termsOfUseUrl =>
      _optional('TERMS_OF_USE_URL') ?? appleStandardEulaUrl;
  static String get feedbackUrlEn =>
      _optional('FEEDBACK_URL_EN') ?? defaultFeedbackUrlEn;
  static String get feedbackUrlJa =>
      _optional('FEEDBACK_URL_JA') ?? defaultFeedbackUrlJa;
  static String get feedbackUrlKo =>
      _optional('FEEDBACK_URL_KO') ?? defaultFeedbackUrlKo;
  static String get feedbackUrlZhTw =>
      _optional('FEEDBACK_URL_ZH_TW') ?? defaultFeedbackUrlZhTw;
  static const String appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String defaultFeedbackUrlEn =
      'https://pet-app-702be.web.app/support.html';
  static const String defaultFeedbackUrlJa =
      'https://pet-app-702be.web.app/support.html';
  static const String defaultFeedbackUrlKo =
      'https://pet-app-702be.web.app/support_ko.html';
  static const String defaultFeedbackUrlZhTw =
      'https://pet-app-702be.web.app/support_zh_TW.html';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env: $key');
    }
    return value;
  }

  static String? _optional(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static int? _optionalInt(String key) {
    final raw = _optional(key);
    if (raw == null) {
      return null;
    }
    return int.tryParse(raw);
  }

  static bool? _optionalBool(String key) {
    final raw = _optional(key);
    if (raw == null) {
      return null;
    }
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'off':
        return false;
      default:
        return null;
    }
  }
}
