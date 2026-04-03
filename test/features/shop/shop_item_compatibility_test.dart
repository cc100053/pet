import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/models/shop_item.dart';

void main() {
  ShopItem buildItem({String? minAppVersion}) {
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
}
