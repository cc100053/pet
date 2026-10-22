import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/l10n/app_localizations_en.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  test('reads pro_only from catalog metadata', () {
    ShopItem parse(Map<String, dynamic> metadata) => ShopItem.fromJson({
      'id': 'id',
      'sku': 'background_ghost_sky',
      'metadata': {'category': 'background', ...metadata},
    });

    expect(parse({'pro_only': true}).isProOnly, isTrue);
    expect(parse({}).isProOnly, isFalse);
  });

  final l10n = AppLocalizationsEn();

  test(
    'festive furniture uses localized names and descriptions in every locale',
    () {
      const items = {
        'candle': 'Candle',
        'candy_cane': 'CandyCane',
        'sunflower': 'Sunflower',
        'gift': 'Gift',
        'christmas_tree': 'ChristmasTree',
      };
      for (final locale in AppLocalizations.supportedLocales) {
        final suffix = locale.countryCode == null
            ? locale.languageCode
            : '${locale.languageCode}_${locale.countryCode}';
        final arb =
            jsonDecode(File('lib/l10n/app_$suffix.arb').readAsStringSync())
                as Map<String, dynamic>;
        final strings = lookupAppLocalizations(
          Locale(locale.languageCode, locale.countryCode),
        );
        for (final entry in items.entries) {
          final item = ShopItem.fromJson({
            'id': entry.key,
            'sku': 'furniture_${entry.key}',
            'name': 'fallback name',
            'metadata': {'description': 'fallback description'},
          });
          expect(
            item.localizedName(strings),
            arb['storeItemNameFurniture${entry.value}'],
          );
          expect(
            item.localizedDescription(strings),
            arb['storeItemDescFurniture${entry.value}'],
          );
        }
      }
    },
  );

  test(
    'uses package localized price string even when catalog currency is JPY',
    () {
      final item = _buildShopItem(priceJpy: 300, catalogCurrencyCode: 'JPY');
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
      final item = _buildShopItem(priceJpy: 300, catalogCurrencyCode: 'JPY');

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
      final item = _buildShopItem(priceJpy: 300, catalogCurrencyCode: 'JPY');

      final price = item.localizedIapPrice(null, null, l10n);

      expect(price, 'JPY 300');
    },
  );

  test(
    'returns unavailable when no store price and no JPY fallback is available',
    () {
      final item = _buildShopItem(priceJpy: null, catalogCurrencyCode: 'USD');

      final price = item.localizedIapPrice(null, null, l10n);

      expect(price, l10n.storePriceUnavailable);
    },
  );
}

ShopItem _buildShopItem({
  required int? priceJpy,
  required String? catalogCurrencyCode,
}) {
  return ShopItem(
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
