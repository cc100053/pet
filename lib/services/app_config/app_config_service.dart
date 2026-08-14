import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/force_update/update_policy.dart';
import 'app_store_lookup_service.dart';

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
  AppConfigService({
    SupabaseClient? client,
    Future<dynamic> Function(String key)? configValueLoader,
    AppStoreVersionLookupService? appStoreVersionLookupService,
  }) : _client = client,
       _configValueLoader = configValueLoader,
       _appStoreVersionLookupService =
           appStoreVersionLookupService ??
           AppStoreVersionLookupService(fallbackStoreUrl: iosAppStoreUrl);

  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/id6757725650';
  static const String _softOnlyMinimumRequiredVersion = '0.0.0';

  final SupabaseClient? _client;
  final Future<dynamic> Function(String key)? _configValueLoader;
  final AppStoreVersionLookupService _appStoreVersionLookupService;

  /// Reads a boolean rollout flag from `app_config`. Returns [defaultValue]
  /// when the key is absent or unparseable, so a missing row keeps a feature
  /// fully off. Accepts native bools as well as `"true"/"false"/"1"/"0"`.
  Future<bool> fetchBoolFlag(String key, {bool defaultValue = false}) async {
    final value = await _safeFetchConfigValue(key);
    final resolved = value is Map ? _valueForPlatform(value) : value;
    if (resolved == null) {
      return defaultValue;
    }
    if (resolved is bool) {
      return resolved;
    }
    switch (resolved.toString().trim().toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
      default:
        return defaultValue;
    }
  }

  Future<ForceUpdateConfig?> fetchForceUpdateConfig() async {
    if (kIsWeb) {
      return null;
    }

    final rawMinVersion = await _safeFetchFirstConfigValue([
      'minimum_required_version',
      'min_version',
    ]);
    final minimumRequiredVersion = _valueForPlatform(rawMinVersion);

    final rawLatestVersion = await _safeFetchFirstConfigValue([
      'latest_available_version',
      'latest_version',
    ]);
    final configuredLatestVersion = _valueForPlatform(rawLatestVersion);

    final appStoreVersion = _isIOSPlatform()
        ? await _appStoreVersionLookupService.fetchLatestVersion()
        : null;

    final latestAvailableVersion = _highestVersion([
      configuredLatestVersion,
      appStoreVersion?.version,
      minimumRequiredVersion,
    ]);
    if (latestAvailableVersion == null || latestAvailableVersion.isEmpty) {
      return null;
    }
    final effectiveMinimumRequiredVersion =
        minimumRequiredVersion == null || minimumRequiredVersion.isEmpty
        ? _softOnlyMinimumRequiredVersion
        : minimumRequiredVersion;

    final rawStoreUrl = await _safeFetchConfigValue('store_url');
    final configuredStoreUrl = _valueForPlatform(rawStoreUrl);
    final storeUrl = _isIOSPlatform()
        ? (appStoreVersion != null && appStoreVersion.storeUrl.isNotEmpty
              ? appStoreVersion.storeUrl
              : configuredStoreUrl ?? iosAppStoreUrl)
        : (configuredStoreUrl ?? _defaultStoreUrlForPlatform());
    if (storeUrl == null || storeUrl.isEmpty) {
      return null;
    }

    final rawHardMessage = await _safeFetchFirstConfigValue([
      'hard_update_message',
      'force_update_message',
    ]);
    final hardUpdateMessage = _valueForPlatform(rawHardMessage);
    final rawSoftMessage = await _safeFetchConfigValue('soft_update_message');
    final softUpdateMessage = _valueForPlatform(rawSoftMessage);

    return ForceUpdateConfig(
      minimumRequiredVersion: effectiveMinimumRequiredVersion,
      latestAvailableVersion: latestAvailableVersion,
      storeUrl: storeUrl,
      hardUpdateMessage: hardUpdateMessage,
      softUpdateMessage: softUpdateMessage,
    );
  }

  Future<dynamic> _safeFetchFirstConfigValue(List<String> keys) async {
    for (final key in keys) {
      final value = await _safeFetchConfigValue(key);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  Future<dynamic> _safeFetchConfigValue(String key) async {
    try {
      return await _fetchConfigValue(key);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _fetchConfigValue(String key) async {
    final configValueLoader = _configValueLoader;
    if (configValueLoader != null) {
      return configValueLoader(key);
    }
    final client = _client ?? Supabase.instance.client;
    final row = await client
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

  String? _highestVersion(List<String?> versions) {
    String? highest;
    for (final version in versions) {
      if (version == null || version.isEmpty) {
        continue;
      }
      if (highest == null ||
          AppUpdatePolicy.compareVersions(highest, version) < 0) {
        highest = version;
      }
    }
    return highest;
  }
}
