import '../force_update/update_policy.dart';

class SharedDecorCompatibility {
  const SharedDecorCompatibility._();

  static bool supportsAppVersion({
    required String? minAppVersion,
    required String? appVersion,
  }) {
    final minimum = minAppVersion?.trim();
    if (minimum == null || minimum.isEmpty) {
      return true;
    }
    final current = appVersion?.trim();
    if (current == null || current.isEmpty) {
      return false;
    }
    return AppUpdatePolicy.compareVersions(current, minimum) >= 0;
  }

  static bool canUseShopItem({
    required String? minAppVersion,
    required String? appVersion,
  }) {
    return supportsAppVersion(
      minAppVersion: minAppVersion,
      appVersion: appVersion,
    );
  }

  static bool canRenderBackground({
    required bool isBackground,
    required String? minAppVersion,
    required String? appVersion,
    required bool backgroundKeySupported,
  }) {
    return isBackground &&
        supportsAppVersion(
          minAppVersion: minAppVersion,
          appVersion: appVersion,
        ) &&
        backgroundKeySupported;
  }

  static bool canRenderFurniture({
    required bool isFurniture,
    required String? minAppVersion,
    required String? appVersion,
  }) {
    return isFurniture &&
        supportsAppVersion(
          minAppVersion: minAppVersion,
          appVersion: appVersion,
        );
  }

  static bool canRenderPet({
    required bool petExists,
    required String? minAppVersion,
    required String? appVersion,
  }) {
    return petExists &&
        supportsAppVersion(
          minAppVersion: minAppVersion,
          appVersion: appVersion,
        );
  }

  static SharedDecorCompatibilityPromptState promptState({
    required String? unsupportedPetType,
    required Set<String> unsupportedBackgroundItemIds,
    required String? activeBackgroundItemId,
    required int unsupportedPlacedFurnitureCount,
  }) {
    final hasUnsupportedBackground =
        activeBackgroundItemId != null &&
        unsupportedBackgroundItemIds.contains(activeBackgroundItemId);
    return SharedDecorCompatibilityPromptState(
      hasUnsupportedPet:
          unsupportedPetType != null && unsupportedPetType.trim().isNotEmpty,
      hasUnsupportedBackground: hasUnsupportedBackground,
      hasUnsupportedFurniture: unsupportedPlacedFurnitureCount > 0,
    );
  }
}

class SharedDecorCompatibilityPromptState {
  const SharedDecorCompatibilityPromptState({
    required this.hasUnsupportedPet,
    required this.hasUnsupportedBackground,
    required this.hasUnsupportedFurniture,
  });

  final bool hasUnsupportedPet;
  final bool hasUnsupportedBackground;
  final bool hasUnsupportedFurniture;

  bool get shouldPrompt =>
      hasUnsupportedPet || hasUnsupportedBackground || hasUnsupportedFurniture;

  String keyFor({required String roomId, required String? appVersion}) {
    return '$roomId:${appVersion ?? 'unknown'}:'
        '${hasUnsupportedPet ? 'pet' : 'no-pet'}:'
        '${hasUnsupportedBackground ? 'bg' : 'no-bg'}:'
        '${hasUnsupportedFurniture ? 'furniture' : 'no-furniture'}';
  }
}
