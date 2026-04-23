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

    expect(positioned.left, closeTo(30, 0.001));
    expect(positioned.top, closeTo(3, 0.001));
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
}
