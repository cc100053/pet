import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String? get revenueCatApiKeyIos => _optional('REVENUECAT_API_KEY_IOS');
  static String? get revenueCatApiKeyAndroid =>
      _optional('REVENUECAT_API_KEY_ANDROID');

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
}
