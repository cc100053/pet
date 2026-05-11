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

  ShopItem buildEquipmentItem({
    String id = 'hat',
    String sku = 'equip_straw_hat',
    String name = 'Straw Hat',
    String slot = 'head',
    String assetPath = 'assets/equipment/hats/straw_hat.png',
  }) {
    return ShopItem(
      id: id,
      sku: sku,
      type: 'cosmetic',
      name: name,
      priceCoins: 120,
      priceDiamonds: null,
      priceJpy: 120,
      description: 'Sunny hat.',
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'equipment',
      emoji: '👒',
      furnitureAssetPath: assetPath,
      equipmentSlotValue: slot,
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
          petType: 'ghost',
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
          equipmentItems: const [],
          equippedItemIdsBySlot: const {},
          equippedItemSkusBySlot: const {},
          equipmentLoading: false,
          equipmentErrorText: null,
          onClose: () {},
          onFurnitureTap: (_) {},
          onBackgroundApply: (_) {},
          onEquipItem: (itemId, slot) async {},
          onUnequipItem: (_) async {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('furniture_inventory_item_sofa')),
      findsOneWidget,
    );
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('Sofa'), findsOneWidget);
    expect(find.text('Owned x2  ·  Available x1'), findsOneWidget);
  });

  testWidgets('disables furniture placement when no copies are available', (
    tester,
  ) async {
    final item = buildFurnitureItem();
    var tapCount = 0;

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          petType: 'ghost',
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
          equipmentItems: const [],
          equippedItemIdsBySlot: const {},
          equippedItemSkusBySlot: const {},
          equipmentLoading: false,
          equipmentErrorText: null,
          onClose: () {},
          onFurnitureTap: (_) => tapCount++,
          onBackgroundApply: (_) {},
          onEquipItem: (itemId, slot) async {},
          onUnequipItem: (_) async {},
        ),
      ),
    );

    expect(find.text('Owned x2  ·  Available x0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('furniture_inventory_item_sofa')));
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
          petType: 'ghost',
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
          equipmentItems: const [],
          equippedItemIdsBySlot: const {},
          equippedItemSkusBySlot: const {},
          equipmentLoading: false,
          equipmentErrorText: null,
          onClose: () {},
          onFurnitureTap: (_) {},
          onBackgroundApply: (_) {},
          onEquipItem: (itemId, slot) async {},
          onUnequipItem: (_) async {},
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      'assets/furniture/toilet.png',
    );
  });

  testWidgets('equipment tab previews and equips owned item', (tester) async {
    final item = buildEquipmentItem();
    String? equippedItemId;
    String? unequippedSlot;

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          petType: 'ghost',
          furnitureCatalog: const {},
          furnitureInventory: const {},
          selectedFurnitureItemId: null,
          availableFurnitureCount: (_) => 0,
          furnitureLoading: false,
          furnitureErrorText: null,
          backgroundItems: const [],
          activeBackgroundId: null,
          backgroundLoading: false,
          backgroundErrorText: null,
          applyingBackgroundId: null,
          equipmentItems: [item],
          equippedItemIdsBySlot: const {},
          equippedItemSkusBySlot: const {},
          equipmentLoading: false,
          equipmentErrorText: null,
          onClose: () {},
          onFurnitureTap: (_) {},
          onBackgroundApply: (_) {},
          onEquipItem: (itemId, slot) async {
            equippedItemId = '$itemId:$slot';
          },
          onUnequipItem: (slot) async {
            unequippedSlot = slot;
          },
        ),
      ),
    );

    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();

    expect(find.text('Straw Hat'), findsOneWidget);

    await tester.tap(find.text('Straw Hat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Equip'));
    await tester.pumpAndSettle();

    expect(equippedItemId, 'hat:head');
    expect(unequippedSlot, isNull);
  });

  testWidgets('equipment tab treats face and head as separate slots', (
    tester,
  ) async {
    final hat = buildEquipmentItem();
    final sunglasses = buildEquipmentItem(
      id: 'sunglasses',
      sku: 'equip_sunglasses',
      name: 'Sunglasses',
      slot: 'face',
      assetPath: 'assets/equipment/sunglasses.png',
    );
    final equipped = <String>[];

    await tester.pumpWidget(
      buildHarness(
        HomeRoomInventoryPanel(
          petType: 'ghost',
          furnitureCatalog: const {},
          furnitureInventory: const {},
          selectedFurnitureItemId: null,
          availableFurnitureCount: (_) => 0,
          furnitureLoading: false,
          furnitureErrorText: null,
          backgroundItems: const [],
          activeBackgroundId: null,
          backgroundLoading: false,
          backgroundErrorText: null,
          applyingBackgroundId: null,
          equipmentItems: [hat, sunglasses],
          equippedItemIdsBySlot: const {'head': 'hat'},
          equippedItemSkusBySlot: const {'head': 'equip_straw_hat'},
          equipmentLoading: false,
          equipmentErrorText: null,
          onClose: () {},
          onFurnitureTap: (_) {},
          onBackgroundApply: (_) {},
          onEquipItem: (itemId, slot) async {
            equipped.add('$itemId:$slot');
          },
          onUnequipItem: (_) async {},
        ),
      ),
    );

    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();

    expect(find.text('Straw Hat'), findsOneWidget);
    expect(find.text('Sunglasses'), findsNothing);

    await tester.tap(find.text('Face'));
    await tester.pumpAndSettle();

    expect(find.text('Straw Hat'), findsNothing);
    expect(find.text('Sunglasses'), findsOneWidget);

    await tester.tap(find.text('Sunglasses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equip'));
    await tester.pumpAndSettle();

    expect(equipped, ['sunglasses:face']);
  });
}
