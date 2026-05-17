import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/features/shop/shop_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  ShopItem buildItem({
    required String id,
    required String sku,
    String type = 'consumable',
    String category = 'utility',
    int? priceCoins,
    int? priceDiamonds,
  }) {
    return ShopItem(
      id: id,
      sku: sku,
      type: type,
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
      category: category,
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
          ownedQuantity: 0,
          maxOwnedQuantity: 1,
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
          onUsePetTicket: () {},
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
          ownedQuantity: 0,
          maxOwnedQuantity: 1,
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
          onUsePetTicket: () {},
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
          ownedQuantity: 1,
          maxOwnedQuantity: 1,
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
          onUsePetTicket: () => buyCount++,
        ),
      ),
    );

    await tester.tap(find.text('Owned').last);
    await tester.pump();

    expect(buyCount, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('owned furniture stays purchasable and shows room quantity', (
    tester,
  ) async {
    final item = buildItem(
      id: 'furniture-1',
      sku: 'furniture_emoji_sofa',
      type: 'cosmetic',
      category: 'furniture',
      priceCoins: 30,
    );
    var buyCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          ownedQuantity: 2,
          maxOwnedQuantity: 999999,
          isIap: false,
          priceString: '',
          canAffordCoins: true,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () => buyCount++,
          onBuyDiamonds: () {},
          onHandleLetter: () {},
          onUsePetTicket: () {},
        ),
      ),
    );

    expect(find.text('Owned x2'), findsOneWidget);

    await tester.tap(find.text('Buy more').last);
    await tester.pump();

    expect(buyCount, 1);
  });

  testWidgets('owned equipment can be bought until room pet count', (
    tester,
  ) async {
    final item = buildItem(
      id: 'equipment-1',
      sku: 'equip_crown',
      type: 'cosmetic',
      category: 'equipment',
      priceCoins: 260,
    );
    var buyCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          ownedQuantity: 1,
          maxOwnedQuantity: 2,
          isIap: false,
          priceString: '',
          canAffordCoins: true,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () => buyCount++,
          onBuyDiamonds: () {},
          onHandleLetter: () {},
          onUsePetTicket: () {},
        ),
      ),
    );

    expect(find.text('Owned x1'), findsOneWidget);

    await tester.tap(find.text('Buy more').last);
    await tester.pump();

    expect(buyCount, 1);
  });

  testWidgets('owned equipment locks once quantity reaches room pet count', (
    tester,
  ) async {
    final item = buildItem(
      id: 'equipment-2',
      sku: 'equip_ribbon',
      type: 'cosmetic',
      category: 'equipment',
      priceCoins: 170,
    );
    var buyCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          ownedQuantity: 2,
          maxOwnedQuantity: 2,
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
          onUsePetTicket: () => buyCount++,
        ),
      ),
    );

    await tester.tap(find.text('Owned').last);
    await tester.pump();

    expect(buyCount, 0);
  });

  testWidgets('owned pet ticket is usable and shows quantity', (tester) async {
    final item = buildItem(
      id: 'pet-ticket-1',
      sku: 'pet_ticket',
      category: 'pet_ticket',
      priceDiamonds: 150,
    );
    var buyCount = 0;
    var useCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          ownedQuantity: 2,
          maxOwnedQuantity: 1,
          isIap: false,
          priceString: '',
          canAffordCoins: false,
          canAffordDiamonds: true,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () {},
          onBuyDiamonds: () => buyCount++,
          onHandleLetter: () {},
          onUsePetTicket: () => useCount++,
        ),
      ),
    );

    expect(find.text('Owned x2'), findsOneWidget);

    await tester.tap(find.text('Use').last);
    await tester.pump();

    expect(useCount, 1);
    expect(buyCount, 0);
  });

  testWidgets('unowned pet ticket starts purchase flow', (tester) async {
    final item = buildItem(
      id: 'pet-ticket-2',
      sku: 'pet_ticket',
      category: 'pet_ticket',
      priceDiamonds: 150,
    );
    var buyCount = 0;
    var useCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: false,
          ownedQuantity: 0,
          maxOwnedQuantity: 1,
          isIap: false,
          priceString: '',
          canAffordCoins: false,
          canAffordDiamonds: true,
          canBuyIap: false,
          hasDepartedPets: true,
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () {},
          onBuyDiamonds: () => buyCount++,
          onHandleLetter: () {},
          onUsePetTicket: () => useCount++,
        ),
      ),
    );

    await tester.tap(find.text('Buy').last);
    await tester.pump();

    expect(buyCount, 1);
    expect(useCount, 0);
  });

  testWidgets('owned background remains non-interactive', (tester) async {
    final item = buildItem(
      id: 'background-1',
      sku: 'background_test1',
      type: 'cosmetic',
      category: 'background',
      priceCoins: 30,
    );
    var buyCount = 0;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: true,
          ownedQuantity: 0,
          maxOwnedQuantity: 1,
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
          onUsePetTicket: () => buyCount++,
        ),
      ),
    );

    await tester.tap(find.text('Owned').last);
    await tester.pump();

    expect(buyCount, 0);
  });

  testWidgets('Return Letter is interactive even when no departed pets', (
    tester,
  ) async {
    final item = buildItem(
      id: 'letter-1',
      sku: 'return_letter',
      priceCoins: 100,
    );

    var handledLetter = false;

    await tester.pumpWidget(
      buildHarness(
        locale: const Locale('en'),
        child: (context, l10n) => ShopGridItemCard(
          item: item,
          isOwned: false,
          ownedQuantity: 0,
          maxOwnedQuantity: 1,
          isIap: false,
          priceString: '',
          canAffordCoins: true,
          canAffordDiamonds: false,
          canBuyIap: false,
          hasDepartedPets: false, // NO departed pets
          onOpenThemePreview: () {},
          onBuyIap: () {},
          onBuyCoins: () {},
          onBuyDiamonds: () {},
          onHandleLetter: () {
            handledLetter = true;
          },
          onUsePetTicket: () {},
        ),
      ),
    );

    await tester.tap(find.text('Buy').last);
    await tester.pump();

    expect(handledLetter, true);
  });
}
