import '../../shared/compatibility/shared_decor_compatibility.dart';
import '../shop/models/shop_item.dart';

Map<String, ShopItem> buildRoomFurnitureCatalog({
  required Iterable<ShopItem> visibleShopItems,
  required Iterable<ShopItem> inventoryItemDetails,
  required Map<String, int> inventory,
  required String? appVersion,
}) {
  final catalog = <String, ShopItem>{};

  void addIfUsable(ShopItem item, {required bool requireOwned}) {
    if (!SharedDecorCompatibility.canRenderFurniture(
      isFurniture: item.isFurniture,
      minAppVersion: item.minAppVersion,
      appVersion: appVersion,
    )) {
      return;
    }
    if (requireOwned && (inventory[item.id] ?? 0) <= 0) {
      return;
    }
    catalog[item.id] = item;
  }

  for (final item in visibleShopItems) {
    addIfUsable(item, requireOwned: false);
  }
  for (final item in inventoryItemDetails) {
    addIfUsable(item, requireOwned: true);
  }

  return catalog;
}
