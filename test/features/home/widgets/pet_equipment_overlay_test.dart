import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/pet_equipment_overlay.dart';
import 'package:pet/features/pet/equipment_catalog.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('positions front-layer equipment from socket and anchor', (
    tester,
  ) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'ghost',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );

    expect(positioned.left, closeTo(28.444444, 0.001));
    expect(positioned.top, closeTo(-6.888889, 0.001));
  });

  testWidgets('renders face and head equipment at the head socket together', (
    tester,
  ) async {
    const hatDefinition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
    );
    const sunglassesDefinition = EquipmentDefinition(
      sku: 'test_sunglasses',
      slot: PetEquipmentSlot.face,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.2, h: 0.1),
      assetPath: 'assets/equipment/sunglasses.png',
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'ghost',
          equippedSkusBySlot: {
            PetEquipmentSlot.head: 'test_hat',
            PetEquipmentSlot.face: 'test_sunglasses',
          },
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          definitions: [hatDefinition, sunglassesDefinition],
        ),
      ),
    );

    final hat = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );
    final sunglasses = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-face-test_sunglasses')),
    );

    expect(hat.left, closeTo(28.444444, 0.001));
    expect(hat.top, closeTo(-6.888889, 0.001));
    expect(sunglasses.left, closeTo(38.444444, 0.001));
    expect(sunglasses.top, closeTo(3.111111, 0.001));
  });

  testWidgets('routes negative z-order items to the behind layer', (
    tester,
  ) async {
    const behindDefinition = EquipmentDefinition(
      sku: 'test_cape',
      slot: PetEquipmentSlot.back,
      anchor: EquipmentAnchor(x: 0.5, y: 0.5),
      sizeRatio: EquipmentSize(w: 0.3, h: 0.3),
      assetPath: 'assets/equipment/hats/straw_hat.png',
      zOrder: -1,
    );

    await tester.pumpWidget(
      buildHarness(
        const Column(
          children: [
            PetEquipmentOverlay(
              petId: 'ghost',
              equippedSkusBySlot: {PetEquipmentSlot.back: 'test_cape'},
              petSize: Size(100, 100),
              layer: PetEquipmentOverlayLayer.behindPet,
              definitions: [behindDefinition],
            ),
            PetEquipmentOverlay(
              petId: 'ghost',
              equippedSkusBySlot: {PetEquipmentSlot.back: 'test_cape'},
              petSize: Size(100, 100),
              layer: PetEquipmentOverlayLayer.frontPet,
              definitions: [behindDefinition],
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('pet-equipment-behindPet-back-test_cape')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pet-equipment-frontPet-back-test_cape')),
      findsNothing,
    );
  });

  testWidgets('shows socket debug markers on the front layer', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'ghost',
          equippedSkusBySlot: {},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          showSocketDebug: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('pet-socket-debug-head')), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-socket-debug-body')), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-socket-debug-back')), findsOneWidget);
  });

  testWidgets('applies per-pet fit override to production placement', (
    tester,
  ) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
      petOverrides: {
        'ghost': EquipmentFitOverride(offset: Offset(0.1, 0.05), scale: 0.5),
      },
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'ghost',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
        matching: find.byType(Image),
      ),
    );

    expect(positioned.left, closeTo(48.444444, 0.001));
    expect(positioned.top, closeTo(8.111111, 0.001));
    expect(image.width, closeTo(20, 0.001));
    expect(image.height, closeTo(10, 0.001));
  });

  testWidgets('applies per-state anchor and size override', (tester) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
      petStateOverrides: {
        'cat': EquipmentStateFitOverrides(
          walk: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.25, y: 0.5),
            sizeRatio: EquipmentSize(w: 0.2, h: 0.1),
          ),
        ),
      },
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'cat',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          isWalking: true,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
        matching: find.byType(Image),
      ),
    );

    expect(positioned.left, closeTo(39.666667, 0.001));
    expect(positioned.top, closeTo(11, 0.001));
    expect(image.width, closeTo(20, 0.001));
    expect(image.height, closeTo(10, 0.001));
  });

  testWidgets('applies ghost idle motion track to overlay placement', (
    tester,
  ) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'ghost',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          animationProgress: 1 / 26,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );

    expect(positioned.left, closeTo(28.444444, 0.001));
    expect(positioned.top, closeTo(-6.888889, 0.001));
  });

  testWidgets('applies chicken Stay track to Idle overlay placement', (
    tester,
  ) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'chicken',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          animationProgress: 750 / 1200,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );

    expect(positioned.left, closeTo(15.111111, 0.001));
    expect(positioned.top, closeTo(-2.222222, 0.001));
  });

  testWidgets('applies walk motion track to overlay placement', (tester) async {
    const definition = EquipmentDefinition(
      sku: 'test_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 1.0),
      sizeRatio: EquipmentSize(w: 0.4, h: 0.2),
      assetPath: 'assets/equipment/hats/straw_hat.png',
    );

    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'cat',
          equippedSkusBySlot: {PetEquipmentSlot.head: 'test_hat'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
          animationProgress: 300 / 1200,
          isWalking: true,
          definitions: [definition],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-test_hat')),
    );

    expect(positioned.left, closeTo(20, 0.001));
    expect(positioned.top, closeTo(-4.444444, 0.001));
  });

  testWidgets('does not render incompatible sunglasses on chicken', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        const PetEquipmentOverlay(
          petId: 'chicken',
          equippedSkusBySlot: {PetEquipmentSlot.face: 'equip_sunglasses'},
          petSize: Size(100, 100),
          layer: PetEquipmentOverlayLayer.frontPet,
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey('pet-equipment-frontPet-face-equip_sunglasses'),
      ),
      findsNothing,
    );
  });
}
