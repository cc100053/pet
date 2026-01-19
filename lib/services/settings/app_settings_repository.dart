import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsRepository {
  AppSettingsRepository._();

  static final AppSettingsRepository instance = AppSettingsRepository._();

  static const String _boxName = 'app_settings';
  static const String _preferredLocaleKey = 'preferred_locale_tag';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  /// Stored as a BCP-47 language tag (e.g. "en", "ja", "zh-TW").
  String? get preferredLocaleTag => _box?.get(_preferredLocaleKey) as String?;

  Future<void> setPreferredLocaleTag(String? tag) async {
    if (tag == null) {
      await _box?.delete(_preferredLocaleKey);
    } else {
      await _box?.put(_preferredLocaleKey, tag);
    }
  }
}
