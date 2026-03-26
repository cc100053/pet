import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_room_inventory_panel.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  ShopItem buildFurnitureItem() {
    return ShopItem(
      id: 'sofa',
      sku: 'furniture_emoji_sofa',
      type: 'cosmetic',
      name: 'Emoji Sofa',
      priceCoins: 250,
      priceDiamonds: null,
      priceJpy: 250,
      description: 'Comfy sofa.',
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'furniture',
      emoji: '🛋️',
      backgroundKey: null,
    );
  }

  Widget buildHarness(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }

  testWidgets('shows shared available furniture count in the inventory panel', (
    tester,
  ) async {
    final item = buildFurnitureItem();

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          furnitureCatalog: {item.id: item},
          furnitureInventory: {item.id: 2},
          selectedFurnitureItemId: item.id,
          availableFurnitureCount: (itemId) => itemId == item.id ? 1 : 0,
          furnitureLoading: false,
          furnitureErrorText: null,
          backgroundItems: const [],
          activeBackgroundId: null,
          backgroundLoading: false,
          backgroundErrorText: null,
          applyingBackgroundId: null,
          onClose: () {},
          onFurnitureTap: (_) {},
          onBackgroundApply: (_) {},
        ),
      ),
    );

    expect(find.text('Sofa'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });
}
