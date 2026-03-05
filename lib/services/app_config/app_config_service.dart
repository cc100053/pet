import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForceUpdateConfig {
  ForceUpdateConfig({
    required this.minimumRequiredVersion,
    required this.latestAvailableVersion,
    required this.storeUrl,
    this.hardUpdateMessage,
    this.softUpdateMessage,
  });

  final String minimumRequiredVersion;
  final String latestAvailableVersion;
  final String storeUrl;
  final String? hardUpdateMessage;
  final String? softUpdateMessage;
}

class AppConfigService {
  AppConfigService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/id6757725650';

  final SupabaseClient _client;

  Future<ForceUpdateConfig?> fetchForceUpdateConfig() async {
    if (kIsWeb) {
      return null;
    }

    final rawMinVersion = await _fetchFirstConfigValue([
      'minimum_required_version',
      'min_version',
    ]);
    final minimumRequiredVersion = _valueForPlatform(rawMinVersion);
    if (minimumRequiredVersion == null || minimumRequiredVersion.isEmpty) {
      return null;
    }

    final rawLatestVersion = await _fetchFirstConfigValue([
      'latest_available_version',
      'latest_version',
    ]);
    final latestAvailableVersion =
        _valueForPlatform(rawLatestVersion) ?? minimumRequiredVersion;
    if (latestAvailableVersion.isEmpty) {
      return null;
    }

    final rawStoreUrl = await _fetchConfigValue('store_url');
    final configuredStoreUrl = _valueForPlatform(rawStoreUrl);
    final storeUrl = _isIOSPlatform()
        ? iosAppStoreUrl
        : (configuredStoreUrl ?? _defaultStoreUrlForPlatform());
    if (storeUrl == null || storeUrl.isEmpty) {
      return null;
    }

    final rawHardMessage = await _fetchFirstConfigValue([
      'hard_update_message',
      'force_update_message',
    ]);
    final hardUpdateMessage = _valueForPlatform(rawHardMessage);
    final rawSoftMessage = await _fetchConfigValue('soft_update_message');
    final softUpdateMessage = _valueForPlatform(rawSoftMessage);

    return ForceUpdateConfig(
      minimumRequiredVersion: minimumRequiredVersion,
      latestAvailableVersion: latestAvailableVersion,
      storeUrl: storeUrl,
      hardUpdateMessage: hardUpdateMessage,
      softUpdateMessage: softUpdateMessage,
    );
  }

  Future<dynamic> _fetchFirstConfigValue(List<String> keys) async {
    for (final key in keys) {
      final value = await _fetchConfigValue(key);
      if (value != null) {
        return value;
      }
    }
    return null;
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

  String? _defaultStoreUrlForPlatform() {
    if (kIsWeb) {
      return null;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return iosAppStoreUrl;
      case TargetPlatform.android:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  bool _isIOSPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
