import 'package:pet/l10n/app_localizations.dart';

String localizedShopItemNameForSku(String sku, AppLocalizations l10n) {
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
    case 'background_sage_frame':
      return l10n.storeItemNameBackgroundSageFrame;
    case 'background_lilac_frame':
      return l10n.storeItemNameBackgroundLilacFrame;
    case 'background_bubble_sky':
      return l10n.storeItemNameBackgroundBubbleSky;
    case 'background_starlit_dream':
      return l10n.storeItemNameBackgroundStarlitDream;
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
    case 'furniture_toilet':
      return l10n.storeItemNameFurnitureToilet;
    case 'furniture_tub':
      return l10n.storeItemNameFurnitureTub;
    case 'equip_straw_hat':
      return l10n.storeItemNameEquipmentStrawHat;
    case 'equip_crown':
      return l10n.storeItemNameEquipmentCrown;
    case 'equip_sunglasses':
      return l10n.storeItemNameEquipmentSunglasses;
    case 'equip_ribbon':
      return l10n.storeItemNameEquipmentRibbon;
    case 'diamond_candy_pack_500':
      return l10n.storeItemNameCandyPack500;
    default:
      return sku;
  }
}
