enum AppUpdateRequirement { none, soft, hard }

class AppUpdatePolicy {
  const AppUpdatePolicy._();

  static AppUpdateRequirement evaluate({
    required String currentVersion,
    required String minimumRequiredVersion,
    required String latestAvailableVersion,
  }) {
    if (compareVersions(currentVersion, minimumRequiredVersion) < 0) {
      return AppUpdateRequirement.hard;
    }
    if (compareVersions(currentVersion, latestAvailableVersion) < 0) {
      return AppUpdateRequirement.soft;
    }
    return AppUpdateRequirement.none;
  }

  static int compareVersions(String current, String target) {
    final currentParts = _parseVersion(current);
    final targetParts = _parseVersion(target);
    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;
    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final targetValue = i < targetParts.length ? targetParts[i] : 0;
      if (currentValue < targetValue) {
        return -1;
      }
      if (currentValue > targetValue) {
        return 1;
      }
    }
    return 0;
  }

  static List<int> _parseVersion(String version) {
    final normalized = version.split('+').first;
    final parts = normalized.split('.');
    return parts.map((part) {
      final match = RegExp(r'\d+').firstMatch(part);
      if (match == null) {
        return 0;
      }
      return int.tryParse(match.group(0) ?? '0') ?? 0;
    }).toList();
  }
}
