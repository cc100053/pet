import 'package:pet/l10n/app_localizations.dart';

String localizedStoreItemNameForSku(String sku, AppLocalizations l10n) {
  switch (sku) {
    case 'subscription_premium_monthly':
      return l10n.storeItemNameProMonthly;
    case 'iap_diamond_pack_small':
      return l10n.storeItemNameDiamondPack300;
    case 'return_letter':
      return l10n.storeItemNameReturnLetter;
    case 'background_default':
      return l10n.storeItemNameBackgroundDefault;
    case 'background_test1':
      return l10n.storeItemNameBackgroundMoonlight;
    case 'furniture_emoji_sofa':
      return l10n.storeItemNameFurnitureSofa;
    case 'furniture_emoji_plant':
      return l10n.storeItemNameFurniturePlant;
    case 'furniture_emoji_frame':
      return l10n.storeItemNameFurnitureFrame;
    case 'furniture_emoji_teddy':
      return l10n.storeItemNameFurnitureTeddy;
    case 'furniture_emoji_brick':
      return l10n.storeItemNameFurnitureBricks;
    case 'furniture_emoji_tv':
      return l10n.storeItemNameFurnitureTv;
    case 'furniture_emoji_bath':
      return l10n.storeItemNameFurnitureBath;
    case 'furniture_emoji_ribbon':
      return l10n.storeItemNameFurnitureRibbon;
    default:
      return sku;
  }
}
