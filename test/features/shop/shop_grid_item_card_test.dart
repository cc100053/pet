import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/features/shop/shop_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  ShopItem buildItem({
    required String id,
    required String sku,
    int? priceCoins,
    int? priceDiamonds,
  }) {
    return ShopItem(
      id: id,
      sku: sku,
      type: 'consumable',
      name: 'Test Item',
      priceCoins: priceCoins,
      priceDiamonds: priceDiamonds,
      priceJpy: null,
      description: null,
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'utility',
      emoji: '🎁',
      backgroundKey: null,
    );
  }

  Widget buildHarness({
    required Locale locale,
    required Widget Function(BuildContext context, AppLocalizations l10n) child,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: SizedBox(
                width: 220,
                height: 240,
                child: child(context, l10n),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('shows candy shortage feedback when buy stays tappable', (
    tester,
  ) async {
    final item = buildItem(
      id: 'coin-1',
      sku: 'coin_shortage_item',
      priceCoins: 200,
    );

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: false,
          isIap: false,
          priceString: '',
          canAffordCoins: false,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.storeNotEnoughCoins)));
          },
          onBuyDiamonds: () {},
          onHandleLetter: () {},
        ),
      ),
    );

    await tester.tap(find.text('Buy').last);
    await tester.pump();

    expect(find.text('Not enough candy.'), findsOneWidget);
  });

  testWidgets('shows diamond shortage feedback when buy stays tappable', (
    tester,
  ) async {
    final item = buildItem(
      id: 'diamond-1',
      sku: 'diamond_shortage_item',
      priceDiamonds: 80,
    );

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: false,
          isIap: false,
          priceString: '',
          canAffordCoins: false,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () {},
          onBuyDiamonds: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.storeNotEnoughDiamonds)),
            );
          },
          onHandleLetter: () {},
        ),
      ),
    );

    await tester.tap(find.text('Buy').last);
    await tester.pump();

    expect(find.text('Not enough diamonds.'), findsOneWidget);
  });

  testWidgets('keeps owned items non-interactive', (tester) async {
    final item = buildItem(id: 'owned-1', sku: 'owned_item', priceCoins: 30);
    var buyCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          isIap: false,
          priceString: '',
          canAffordCoins: true,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () => buyCount++,
          onBuyCoins: () => buyCount++,
          onBuyDiamonds: () => buyCount++,
          onHandleLetter: () => buyCount++,
        ),
      ),
    );

    await tester.tap(find.text('Owned').last);
    await tester.pump();

    expect(buyCount, 0);
    expect(find.byType(SnackBar), findsNothing);
  });
}
