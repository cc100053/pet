import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/force_update/update_policy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../shop_item_localization.dart';

class ShopItem {
  ShopItem({
    required this.id,
    required this.sku,
    required this.type,
    required this.name,
    required this.priceCoins,
    required this.priceDiamonds,
    required this.priceJpy,
    required this.description,
    required this.iapProductId,
    required this.iapType,
    required this.rcEntitlementId,
    required this.coinAmount,
    required this.diamondAmount,
    required this.iapCurrency,
    required this.catalogCurrencyCode,
    required this.category,
    required this.emoji,
    this.furnitureAssetPath,
    this.backgroundKey,
    this.minAppVersion,
    this.visibilityMode,
    this.shopVisibility,
    this.fallbackBehavior,
    this.fallbackBackgroundKey,
  });

  final String id;
  final String sku;
  final String type;
  final String name;
  final int? priceCoins;
  final int? priceDiamonds;
  final int? priceJpy;
  final String? description;
  final String? iapProductId;
  final String? iapType;
  final String? rcEntitlementId;
  final int? coinAmount;
  final int? diamondAmount;
  final String? iapCurrency;
  final String? catalogCurrencyCode;
  final String? category;
  final String? emoji;
  final String? furnitureAssetPath;
  final String? backgroundKey;
  final String? minAppVersion;
  final String? visibilityMode;
  final String? shopVisibility;
  final String? fallbackBehavior;
  final String? fallbackBackgroundKey;

  bool get isIap => iapProductId != null && iapProductId!.isNotEmpty;
  bool get isBackground => category == 'background';
  bool get isDiamondIap =>
      iapType != 'subscription' &&
      (iapCurrency == 'diamond' || diamondAmount != null);
  bool get isFurniture => category == 'furniture';
  bool get isUtility => category == 'utility';
  bool get isDefaultBackground => sku == 'background_default';
  bool get isVersionGated =>
      (visibilityMode ?? '').trim().toLowerCase() == 'version_gated';
  bool get isHiddenFromShop =>
      (shopVisibility ?? '').trim().toLowerCase() == 'hidden';

  bool isSupportedOnAppVersion(String? appVersion) {
    final requiredVersion = minAppVersion?.trim();
    if (requiredVersion == null || requiredVersion.isEmpty) {
      return true;
    }
    final currentVersion = appVersion?.trim();
    if (currentVersion == null || currentVersion.isEmpty) {
      return false;
    }
    return AppUpdatePolicy.compareVersions(currentVersion, requiredVersion) >=
        0;
  }

  bool get isRecoveryLetter {
    final skuLower = sku.toLowerCase();
    final categoryLower = (category ?? '').toLowerCase();
    return skuLower == 'letter' ||
        skuLower == 'return_letter' ||
        skuLower == 'recovery_letter' ||
        categoryLower == 'utility' ||
        categoryLower == 'letter' ||
        categoryLower == 'recovery_letter';
  }

  String get displayType {
    if (iapType == 'subscription') {
      return 'Subscription';
    }
    switch (type) {
      case 'cosmetic':
        return 'Cosmetic';
      case 'consumable':
        return 'Consumable';
      case 'subscription':
        return 'Subscription';
      default:
        return type;
    }
  }

  String localizedIapPrice(
    Package? package,
    StoreProduct? storeProduct,
    AppLocalizations l10n,
  ) {
    final appStorePrice = package?.storeProduct.priceString;
    if (appStorePrice != null && appStorePrice.isNotEmpty) {
      return appStorePrice;
    }
    final directStorePrice = storeProduct?.priceString;
    if (directStorePrice != null && directStorePrice.isNotEmpty) {
      return directStorePrice;
    }
    if (priceJpy != null && _isCatalogJpy) {
      return l10n.currencyJpy(priceJpy!);
    }
    return l10n.storePriceUnavailable;
  }

  bool get _isCatalogJpy =>
      (catalogCurrencyCode ?? '').trim().toUpperCase() == 'JPY';

  String localizedName(AppLocalizations l10n) {
    final localized = localizedShopItemNameForSku(sku, l10n);
    return localized == sku ? name : localized;
  }

  String? localizedDescription(AppLocalizations l10n) {
    switch (sku) {
      case 'subscription_premium_monthly':
        return l10n.storeItemDescProMonthly;
      case 'iap_diamond_pack_small':
        return null;
      case 'diamond_candy_pack_500':
        return l10n.storeItemDescCandyPack500;
      case 'return_letter':
        return l10n.storeItemDescReturnLetter;
      case 'background_default':
        return l10n.storeItemDescBackgroundDefault;
      case 'background_test1':
        return l10n.storeItemDescBackgroundMoonlight;
      case 'background_sage_frame':
        return l10n.storeItemDescBackgroundSageFrame;
      case 'background_lilac_frame':
        return l10n.storeItemDescBackgroundLilacFrame;
      case 'background_bubble_sky':
        return l10n.storeItemDescBackgroundBubbleSky;
      case 'background_starlit_dream':
        return l10n.storeItemDescBackgroundStarlitDream;
      case 'furniture_emoji_sofa':
        return l10n.storeItemDescFurnitureSofa;
      case 'furniture_emoji_plant':
        return l10n.storeItemDescFurniturePlant;
      case 'furniture_emoji_frame':
        return l10n.storeItemDescFurnitureFrame;
      case 'furniture_emoji_teddy':
        return l10n.storeItemDescFurnitureTeddy;
      case 'furniture_emoji_brick':
        return l10n.storeItemDescFurnitureBricks;
      case 'furniture_emoji_tv':
        return l10n.storeItemDescFurnitureTv;
      case 'furniture_emoji_bath':
        return l10n.storeItemDescFurnitureBath;
      case 'furniture_emoji_ribbon':
        return l10n.storeItemDescFurnitureRibbon;
      case 'furniture_toilet':
        return l10n.storeItemDescFurnitureToilet;
      case 'furniture_tub':
        return l10n.storeItemDescFurnitureTub;
      default:
        return description;
    }
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final priceJpyRaw = metadata['price_jpy'];
    final description = metadata['description'] as String?;
    final iapProductId = metadata['iap_product_id'] as String?;
    final iapType = metadata['iap_type'] as String?;
    final rcEntitlementId = metadata['rc_entitlement_id'] as String?;
    final coinAmountRaw = metadata['coin_amount'];
    final diamondAmountRaw = metadata['diamond_amount'];
    final iapCurrency = metadata['iap_currency'] as String?;
    final catalogCurrencyCode = metadata['currency'] as String?;
    final category = metadata['category'] as String?;
    final emoji = metadata['emoji'] as String?;
    final furnitureAssetPath = metadata['asset_path'] as String?;
    final backgroundKey = metadata['background_key'] as String?;
    final minAppVersion = metadata['min_app_version'] as String?;
    final visibilityMode = metadata['visibility_mode'] as String?;
    final shopVisibility = metadata['shop_visibility'] as String?;
    final fallbackBehavior = metadata['fallback_behavior'] as String?;
    final fallbackBackgroundKey =
        metadata['fallback_background_key'] as String?;

    int? priceJpy;
    if (priceJpyRaw is int) {
      priceJpy = priceJpyRaw;
    } else if (priceJpyRaw is double) {
      priceJpy = priceJpyRaw.round();
    } else if (priceJpyRaw is String) {
      priceJpy = int.tryParse(priceJpyRaw);
    }

    int? coinAmount;
    if (coinAmountRaw is int) {
      coinAmount = coinAmountRaw;
    } else if (coinAmountRaw is double) {
      coinAmount = coinAmountRaw.round();
    } else if (coinAmountRaw is String) {
      coinAmount = int.tryParse(coinAmountRaw);
    }

    int? diamondAmount;
    if (diamondAmountRaw is int) {
      diamondAmount = diamondAmountRaw;
    } else if (diamondAmountRaw is double) {
      diamondAmount = diamondAmountRaw.round();
    } else if (diamondAmountRaw is String) {
      diamondAmount = int.tryParse(diamondAmountRaw);
    }

    return ShopItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      type: json['type'] as String? ?? 'consumable',
      name: json['name'] as String? ?? 'Item',
      priceCoins: json['price_coins'] as int?,
      priceDiamonds: json['price_diamonds'] as int?,
      priceJpy: priceJpy,
      description: description,
      iapProductId: iapProductId,
      iapType: iapType,
      rcEntitlementId: rcEntitlementId,
      coinAmount: coinAmount,
      diamondAmount: diamondAmount,
      iapCurrency: iapCurrency,
      catalogCurrencyCode: catalogCurrencyCode,
      category: category,
      emoji: emoji,
      furnitureAssetPath: furnitureAssetPath,
      backgroundKey: backgroundKey,
      minAppVersion: minAppVersion,
      visibilityMode: visibilityMode,
      shopVisibility: shopVisibility,
      fallbackBehavior: fallbackBehavior,
      fallbackBackgroundKey: fallbackBackgroundKey,
    );
  }
}
