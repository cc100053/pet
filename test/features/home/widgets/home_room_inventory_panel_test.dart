import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_room_inventory_panel.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  ShopItem buildFurnitureItem({String? assetPath}) {
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
      furnitureAssetPath: assetPath,
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

  testWidgets('shows shared total and available furniture counts', (
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
    expect(find.text('Owned x2'), findsOneWidget);
    expect(find.text('Available x1'), findsOneWidget);
  });

  testWidgets('disables furniture placement when no copies are available', (
    tester,
  ) async {
    final item = buildFurnitureItem();
    var tapCount = 0;

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          furnitureCatalog: {item.id: item},
          furnitureInventory: {item.id: 2},
          selectedFurnitureItemId: null,
          availableFurnitureCount: (itemId) => 0,
          furnitureLoading: false,
          furnitureErrorText: null,
          backgroundItems: const [],
          activeBackgroundId: null,
          backgroundLoading: false,
          backgroundErrorText: null,
          applyingBackgroundId: null,
          onClose: () {},
          onFurnitureTap: (_) => tapCount++,
          onBackgroundApply: (_) {},
        ),
      ),
    );

    expect(find.text('Owned x2'), findsOneWidget);
    expect(find.text('Available x0'), findsOneWidget);

    await tester.tap(find.text('Sofa'));
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('renders image-backed furniture in the inventory panel', (
    tester,
  ) async {
    final item = buildFurnitureItem(assetPath: 'assets/furniture/toilet.png');

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          furnitureCatalog: {item.id: item},
          furnitureInventory: {item.id: 1},
          selectedFurnitureItemId: null,
          availableFurnitureCount: (itemId) => 1,
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

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      'assets/furniture/toilet.png',
    );
  });
}
