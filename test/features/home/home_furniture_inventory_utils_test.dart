import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_furniture_inventory_utils.dart';
import 'package:pet/features/shop/models/shop_item.dart';

void main() {
  ShopItem furnitureItem({
    required String id,
    String? minAppVersion,
    String sku = 'furniture_toilet',
  }) {
    return ShopItem(
      id: id,
      sku: sku,
      type: 'cosmetic',
      name: sku,
      priceCoins: 150,
      priceDiamonds: null,
      priceJpy: null,
      description: null,
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: null,
      category: 'furniture',
      emoji: null,
      furnitureAssetPath: 'assets/furniture/toilet.png',
      minAppVersion: minAppVersion,
      visibilityMode: minAppVersion == null ? null : 'version_gated',
    );
  }

  test('hydrates owned furniture missing from visible shop catalog', () {
    final ownedItem = furnitureItem(id: 'owned-toilet', minAppVersion: '1.1.2');

    final catalog = buildRoomFurnitureCatalog(
      visibleShopItems: const [],
      inventoryItemDetails: [ownedItem],
      inventory: {'owned-toilet': 1},
      appVersion: '1.1.2',
    );

    expect(catalog.keys, contains('owned-toilet'));
    expect(
      catalog['owned-toilet']?.furnitureAssetPath,
      ownedItem.furnitureAssetPath,
    );
  });

  test('does not expose owned furniture before its supported app version', () {
    final ownedItem = furnitureItem(
      id: 'owned-tub',
      sku: 'furniture_tub',
      minAppVersion: '1.1.2',
    );

    final catalog = buildRoomFurnitureCatalog(
      visibleShopItems: const [],
      inventoryItemDetails: [ownedItem],
      inventory: {'owned-tub': 1},
      appVersion: '1.1.1',
    );

    expect(catalog, isEmpty);
  });
}
