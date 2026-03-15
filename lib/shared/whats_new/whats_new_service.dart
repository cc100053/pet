import '../../services/settings/app_settings_repository.dart';
import 'app_whats_new_catalog.dart';
import 'whats_new_policy.dart';

abstract class WhatsNewSettingsStore {
  String? get lastLaunchedAppVersion;
  Future<void> setLastLaunchedAppVersion(String? version);
  String? get lastShownWhatsNewVersion;
  Future<void> setLastShownWhatsNewVersion(String? version);
}

class AppSettingsWhatsNewStore implements WhatsNewSettingsStore {
  AppSettingsWhatsNewStore({AppSettingsRepository? settings})
    : _settings = settings ?? AppSettingsRepository.instance;

  final AppSettingsRepository _settings;

  @override
  String? get lastLaunchedAppVersion => _settings.lastLaunchedAppVersion;

  @override
  Future<void> setLastLaunchedAppVersion(String? version) {
    return _settings.setLastLaunchedAppVersion(version);
  }

  @override
  String? get lastShownWhatsNewVersion => _settings.lastShownWhatsNewVersion;

  @override
  Future<void> setLastShownWhatsNewVersion(String? version) {
    return _settings.setLastShownWhatsNewVersion(version);
  }
}

class WhatsNewService {
  WhatsNewService({WhatsNewSettingsStore? settingsStore})
    : _settingsStore = settingsStore ?? AppSettingsWhatsNewStore();

  final WhatsNewSettingsStore _settingsStore;

  Future<WhatsNewDecision> prepareForLaunch({
    required String currentVersion,
  }) async {
    final normalizedCurrentVersion = currentVersion.trim();
    final decision = WhatsNewPolicy.evaluate(
      currentVersion: normalizedCurrentVersion,
      previousVersion: _settingsStore.lastLaunchedAppVersion,
      lastShownVersion: _settingsStore.lastShownWhatsNewVersion,
      entry: AppWhatsNewCatalog.entryForVersion(normalizedCurrentVersion),
    );
    await _settingsStore.setLastLaunchedAppVersion(normalizedCurrentVersion);
    return decision;
  }

  Future<void> markShown(String version) {
    return _settingsStore.setLastShownWhatsNewVersion(version.trim());
  }
}
