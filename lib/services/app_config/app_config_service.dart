import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForceUpdateConfig {
  ForceUpdateConfig({
    required this.minVersion,
    required this.storeUrl,
    this.message,
    this.rawMinVersion,
  });

  /// Parsed min version used for comparison.
  final String minVersion;
  final String storeUrl;
  final String? message;

  /// Original config value (transformed into [minVersion]).
  final String? rawMinVersion;
}

class AppConfigService {
  AppConfigService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ForceUpdateConfig?> fetchForceUpdateConfig() async {
    if (kIsWeb) {
      return null;
    }

    final rawMinVersion = await _fetchConfigValue('min_version');
    if (rawMinVersion == null) {
      return null;
    }

    final minVersion = _valueForPlatform(rawMinVersion);
    if (minVersion == null || minVersion.isEmpty) {
      return null;
    }

    final rawStoreUrl = await _fetchConfigValue('store_url');
    final storeUrl = _valueForPlatform(rawStoreUrl);
    if (storeUrl == null || storeUrl.isEmpty) {
      return null;
    }

    final rawMessage = await _fetchConfigValue('force_update_message');
    final message = _valueForPlatform(rawMessage);

    final rawMinVersionString =
        rawMinVersion is String ? rawMinVersion : null;

    return ForceUpdateConfig(
      minVersion: minVersion,
      storeUrl: storeUrl,
      message: message,
      rawMinVersion: rawMinVersionString,
    );
  }

  Future<dynamic> _fetchConfigValue(String key) async {
    final row = await _client
        .from('app_config')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return row['value'];
  }

  String? _valueForPlatform(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is Map) {
      final platformKey = _platformKey();
      final dynamic selected =
          value[platformKey] ?? value['default'] ?? value['all'];
      return selected?.toString();
    }
    return value.toString();
  }

  String _platformKey() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
