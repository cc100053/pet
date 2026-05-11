import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/models/shop_item.dart';

void main() {
  ShopItem buildItem({String? minAppVersion, String? shopVisibility}) {
    return ShopItem(
      id: 'item-1',
      sku: 'background_sage_frame',
      type: 'cosmetic',
      name: 'Sage Frame Background',
      priceCoins: 0,
      priceDiamonds: 0,
      priceJpy: 0,
      description: 'Test item',
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'background',
      emoji: null,
      backgroundKey: 'sage_frame',
      minAppVersion: minAppVersion,
      visibilityMode: minAppVersion == null ? 'public' : 'version_gated',
      shopVisibility: shopVisibility,
      fallbackBehavior: 'default_background',
      fallbackBackgroundKey: 'default',
    );
  }

  test('supports ungated items on any app version', () {
    final item = buildItem();

    expect(item.isSupportedOnAppVersion(null), isTrue);
    expect(item.isSupportedOnAppVersion('1.0.0'), isTrue);
  });

  test('hides gated items from older app versions', () {
    final item = buildItem(minAppVersion: '1.1.0');

    expect(item.isSupportedOnAppVersion(null), isFalse);
    expect(item.isSupportedOnAppVersion('1.0.9'), isFalse);
    expect(item.isSupportedOnAppVersion('1.1.0'), isTrue);
    expect(item.isSupportedOnAppVersion('1.2.0'), isTrue);
  });

  test('can mark shared items as hidden from the shop catalog surface', () {
    final item = buildItem(shopVisibility: 'hidden');

    expect(item.isHiddenFromShop, isTrue);
  });

  test('parses hidden free rollout backgrounds from metadata', () {
    final item = ShopItem.fromJson({
      'id': 'item-free-1',
      'sku': 'background_sage_frame',
      'type': 'cosmetic',
      'name': 'Sage Frame Background',
      'price_coins': 0,
      'price_diamonds': 0,
      'metadata': {
        'currency': 'JPY',
        'category': 'background',
        'background_key': 'sage_frame',
        'shop_visibility': 'hidden',
        'visibility_mode': 'version_gated',
        'min_app_version': '1.1.0',
      },
    });

    expect(item.isBackground, isTrue);
    expect(item.isHiddenFromShop, isTrue);
    expect(item.backgroundKey, 'sage_frame');
  });

  test('parses paid backgrounds as coin-only catalog items', () {
    final item = ShopItem.fromJson({
      'id': 'item-paid-1',
      'sku': 'background_starlit_dream',
      'type': 'cosmetic',
      'name': 'Starlit Dream Background',
      'price_coins': 220,
      'price_diamonds': null,
      'metadata': {
        'currency': 'JPY',
        'price_jpy': 220,
        'category': 'background',
        'background_key': 'starlit_dream',
      },
    });

    expect(item.isBackground, isTrue);
    expect(item.priceCoins, 220);
    expect(item.priceDiamonds, isNull);
    expect(item.backgroundKey, 'starlit_dream');
  });

  test('parses image-backed furniture rollout metadata', () {
    final item = ShopItem.fromJson({
      'id': 'item-furniture-1',
      'sku': 'furniture_toilet',
      'type': 'cosmetic',
      'name': 'Toilet',
      'price_coins': 150,
      'price_diamonds': null,
      'metadata': {
        'category': 'furniture',
        'asset_path': 'assets/furniture/toilet.png',
        'visibility_mode': 'version_gated',
        'min_app_version': '1.1.2',
        'fallback_behavior': 'skip',
      },
    });

    expect(item.isFurniture, isTrue);
    expect(item.priceCoins, 150);
    expect(item.furnitureAssetPath, 'assets/furniture/toilet.png');
    expect(item.isSupportedOnAppVersion('1.1.1'), isFalse);
    expect(item.isSupportedOnAppVersion('1.1.2'), isTrue);
  });

  test('parses V1.4.0 version-gated equipment metadata', () {
    final cases = <({String sku, String slot, String assetPath})>[
      (
        sku: 'equip_crown',
        slot: 'head',
        assetPath: 'assets/equipment/hats/crown.png',
      ),
      (
        sku: 'equip_sunglasses',
        slot: 'face',
        assetPath: 'assets/equipment/sunglasses.png',
      ),
      (
        sku: 'equip_ribbon',
        slot: 'body',
        assetPath: 'assets/equipment/ribbon.png',
      ),
    ];

    for (final entry in cases) {
      final item = ShopItem.fromJson({
        'id': 'item-${entry.sku}',
        'sku': entry.sku,
        'type': 'cosmetic',
        'name': entry.sku,
        'price_coins': 160,
        'price_diamonds': null,
        'metadata': {
          'category': 'equipment',
          'equipment_slot': entry.slot,
          'asset_path': entry.assetPath,
          'price_jpy': 160,
          'visibility_mode': 'version_gated',
          'min_app_version': '1.4.0',
        },
      });

      expect(item.isEquipment, isTrue);
      expect(item.priceCoins, 160);
      expect(item.priceJpy, 160);
      expect(item.equipmentSlot, entry.slot);
      expect(item.equipmentAssetPath, entry.assetPath);
      expect(item.isSupportedOnAppVersion('1.3.9'), isFalse);
      expect(item.isSupportedOnAppVersion('1.4.0'), isTrue);
    }
  });
}
