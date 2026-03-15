import '../force_update/update_policy.dart';
import 'app_whats_new_entry.dart';

class WhatsNewDecision {
  const WhatsNewDecision({
    required this.currentVersion,
    required this.previousVersion,
    required this.lastShownVersion,
    required this.entry,
    required this.shouldShow,
  });

  final String currentVersion;
  final String? previousVersion;
  final String? lastShownVersion;
  final AppWhatsNewEntry? entry;
  final bool shouldShow;
}

class WhatsNewPolicy {
  const WhatsNewPolicy._();

  static WhatsNewDecision evaluate({
    required String currentVersion,
    required String? previousVersion,
    required String? lastShownVersion,
    required AppWhatsNewEntry? entry,
  }) {
    final normalizedCurrentVersion = currentVersion.trim();
    final normalizedPreviousVersion = _normalize(previousVersion);
    final normalizedLastShownVersion = _normalize(lastShownVersion);
    final hasUpgradeFromPreviousVersion =
        normalizedPreviousVersion != null &&
        AppUpdatePolicy.compareVersions(
              normalizedPreviousVersion,
              normalizedCurrentVersion,
            ) <
            0;
    final shouldShow =
        hasUpgradeFromPreviousVersion &&
        entry != null &&
        normalizedLastShownVersion != normalizedCurrentVersion;
    return WhatsNewDecision(
      currentVersion: normalizedCurrentVersion,
      previousVersion: normalizedPreviousVersion,
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
