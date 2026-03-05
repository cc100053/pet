import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/store/models/store_item.dart';
import 'package:pet/l10n/app_localizations_en.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test(
    'uses package localized price string even when catalog currency is JPY',
    () {
      final item = _buildStoreItem(priceJpy: 300, catalogCurrencyCode: 'JPY');
      final package = Package(
        'monthly',
        PackageType.monthly,
        _storeProduct(priceString: 'A\$2.99', currencyCode: 'AUD'),
        const PresentedOfferingContext('default', null, null),
      );

      final price = item.localizedIapPrice(
        package,
        _storeProduct(priceString: 'JPY 300', currencyCode: 'JPY'),
        l10n,
      );

      expect(price, 'A\$2.99');
    },
  );

  test(
    'uses direct localized store price for non-JPY storefront currencies',
    () {
      final item = _buildStoreItem(priceJpy: 300, catalogCurrencyCode: 'JPY');

      final price = item.localizedIapPrice(
        null,
        _storeProduct(priceString: 'HK\$23.00', currencyCode: 'HKD'),
        l10n,
      );

      expect(price, 'HK\$23.00');
    },
  );

  test(
    'falls back to catalog JPY price only when store price is unavailable',
    () {
      final item = _buildStoreItem(priceJpy: 300, catalogCurrencyCode: 'JPY');

      final price = item.localizedIapPrice(null, null, l10n);

      expect(price, 'JPY 300');
    },
  );

  test(
    'returns unavailable when no store price and no JPY fallback is available',
    () {
      final item = _buildStoreItem(priceJpy: null, catalogCurrencyCode: 'USD');

      final price = item.localizedIapPrice(null, null, l10n);

      expect(price, l10n.storePriceUnavailable);
    },
  );
}

StoreItem _buildStoreItem({
  required int? priceJpy,
  required String? catalogCurrencyCode,
}) {
  return StoreItem(
    id: '1',
    sku: 'iap_diamond_pack_small',
    type: 'consumable',
    name: 'Diamond Pack',
    priceCoins: null,
    priceDiamonds: null,
    priceJpy: priceJpy,
    description: null,
    iapProductId: 'com.pet.diamond.small',
    iapType: 'consumable',
    rcEntitlementId: null,
    coinAmount: null,
    diamondAmount: 300,
    iapCurrency: 'real',
    catalogCurrencyCode: catalogCurrencyCode,
    category: null,
    emoji: null,
    backgroundKey: null,
  );
}

StoreProduct _storeProduct({
  required String priceString,
  required String currencyCode,
}) {
  return StoreProduct(
    'com.pet.diamond.small',
    'A diamond pack',
    'Diamond Pack',
    2.99,
    priceString,
    currencyCode,
  );
}
