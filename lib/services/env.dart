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
  static int get adRewardCoins => _optionalInt('AD_REWARD_COINS') ?? 10;
  static String get privacyPolicyUrl => _require('PRIVACY_POLICY_URL');
  static String get termsOfUseUrl =>
      _optional('TERMS_OF_USE_URL') ?? appleStandardEulaUrl;
  static const String appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

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
}
