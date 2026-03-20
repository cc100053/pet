import '../force_update/update_policy.dart';
import 'app_whats_new_entry.dart';

class WhatsNewDecision {
  const WhatsNewDecision({
    required this.currentVersion,
    required this.currentReleaseSignature,
    required this.previousVersion,
    required this.previousReleaseSignature,
    required this.lastShownVersion,
    required this.entry,
    required this.shouldShow,
  });

  final String currentVersion;
  final String currentReleaseSignature;
  final String? previousVersion;
  final String? previousReleaseSignature;
  final String? lastShownVersion;
  final AppWhatsNewEntry? entry;
  final bool shouldShow;
}

class WhatsNewPolicy {
  const WhatsNewPolicy._();

  static WhatsNewDecision evaluate({
    required String currentVersion,
    required String currentReleaseSignature,
    required String? previousVersion,
    required String? previousReleaseSignature,
    required String? lastShownVersion,
    required AppWhatsNewEntry? entry,
    required bool hadExistingInstallBeforeVersionTracking,
  }) {
    final normalizedCurrentVersion = currentVersion.trim();
    final normalizedCurrentReleaseSignature = _normalize(
      currentReleaseSignature,
    );
    final normalizedPreviousVersion = _normalize(previousVersion);
    final normalizedPreviousReleaseSignature = _normalize(
      previousReleaseSignature,
    );
    final normalizedLastShownVersion = _normalize(lastShownVersion);
    final hasUpgradeFromPreviousVersion =
        normalizedPreviousVersion != null &&
        AppUpdatePolicy.compareVersions(
              normalizedPreviousVersion,
              normalizedCurrentVersion,
            ) <
            0;
    final hasSameVersionBuildUpgrade =
        normalizedPreviousVersion == normalizedCurrentVersion &&
        normalizedPreviousReleaseSignature != null &&
        normalizedCurrentReleaseSignature != null &&
        normalizedPreviousReleaseSignature != normalizedCurrentReleaseSignature;
    final hasLegacyUpgradeWithoutVersionHistory =
        normalizedPreviousVersion == null &&
        hadExistingInstallBeforeVersionTracking;
    final shouldShow =
        (hasUpgradeFromPreviousVersion ||
            hasSameVersionBuildUpgrade ||
            hasLegacyUpgradeWithoutVersionHistory) &&
        entry != null &&
        normalizedLastShownVersion != normalizedCurrentVersion;
    return WhatsNewDecision(
      currentVersion: normalizedCurrentVersion,
      currentReleaseSignature:
          normalizedCurrentReleaseSignature ?? normalizedCurrentVersion,
      previousVersion: normalizedPreviousVersion,
      previousReleaseSignature: normalizedPreviousReleaseSignature,
      lastShownVersion: normalizedLastShownVersion,
      entry: shouldShow ? entry : null,
      shouldShow: shouldShow,
    );
  }

  static String? _normalize(String? version) {
    if (version == null) {
      return null;
    }
    final trimmed = version.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
