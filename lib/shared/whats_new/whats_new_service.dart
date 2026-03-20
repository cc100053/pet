import '../../services/settings/app_settings_repository.dart';
import 'app_whats_new_catalog.dart';
import 'whats_new_policy.dart';

abstract class WhatsNewSettingsStore {
  String? get lastLaunchedAppVersion;
  Future<void> setLastLaunchedAppVersion(String? version);
  String? get lastLaunchedAppReleaseSignature;
  Future<void> setLastLaunchedAppReleaseSignature(String? signature);
  String? get lastShownWhatsNewVersion;
  Future<void> setLastShownWhatsNewVersion(String? version);
  bool get hadExistingInstallBeforeVersionTracking;
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
  String? get lastLaunchedAppReleaseSignature =>
      _settings.lastLaunchedAppReleaseSignature;

  @override
  Future<void> setLastLaunchedAppReleaseSignature(String? signature) {
    return _settings.setLastLaunchedAppReleaseSignature(signature);
  }

  @override
  String? get lastShownWhatsNewVersion => _settings.lastShownWhatsNewVersion;

  @override
  Future<void> setLastShownWhatsNewVersion(String? version) {
    return _settings.setLastShownWhatsNewVersion(version);
  }

  @override
  bool get hadExistingInstallBeforeVersionTracking =>
      _settings.hadExistingBoxAtInit;
}

class WhatsNewService {
  WhatsNewService({WhatsNewSettingsStore? settingsStore})
    : _settingsStore = settingsStore ?? AppSettingsWhatsNewStore();

  final WhatsNewSettingsStore _settingsStore;

  Future<WhatsNewDecision> prepareForLaunch({
    required String currentVersion,
    required String currentReleaseSignature,
  }) async {
    final normalizedCurrentVersion = currentVersion.trim();
    final normalizedCurrentReleaseSignature =
        currentReleaseSignature.trim().isEmpty
        ? normalizedCurrentVersion
        : currentReleaseSignature.trim();
    final decision = WhatsNewPolicy.evaluate(
      currentVersion: normalizedCurrentVersion,
      currentReleaseSignature: normalizedCurrentReleaseSignature,
      previousVersion: _settingsStore.lastLaunchedAppVersion,
      previousReleaseSignature: _settingsStore.lastLaunchedAppReleaseSignature,
      lastShownVersion: _settingsStore.lastShownWhatsNewVersion,
      entry: AppWhatsNewCatalog.entryForVersion(normalizedCurrentVersion),
      hadExistingInstallBeforeVersionTracking:
          _settingsStore.hadExistingInstallBeforeVersionTracking,
    );
    if (!decision.shouldShow) {
      await _persistLaunch(
        version: normalizedCurrentVersion,
        releaseSignature: normalizedCurrentReleaseSignature,
      );
    }
    return decision;
  }

  Future<void> markShown({
    required String version,
    required String currentReleaseSignature,
  }) async {
    final normalizedVersion = version.trim();
    final normalizedCurrentReleaseSignature =
        currentReleaseSignature.trim().isEmpty
        ? normalizedVersion
        : currentReleaseSignature.trim();
    await _settingsStore.setLastShownWhatsNewVersion(normalizedVersion);
    await _persistLaunch(
      version: normalizedVersion,
      releaseSignature: normalizedCurrentReleaseSignature,
    );
  }

  Future<void> _persistLaunch({
    required String version,
    required String releaseSignature,
  }) async {
    await _settingsStore.setLastLaunchedAppVersion(version);
    await _settingsStore.setLastLaunchedAppReleaseSignature(releaseSignature);
  }
}
