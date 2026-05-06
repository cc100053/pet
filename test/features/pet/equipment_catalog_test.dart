import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/equipment_catalog.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  test('looks up head equipment by sku', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');
    final crown = EquipmentCatalog.bySku('equip_crown');

    expect(item, isNotNull);
    expect(item!.slot, PetEquipmentSlot.head);
    expect(item.assetPath, 'assets/equipment/hats/straw_hat.png');
    expect(crown, isNotNull);
    expect(crown!.slot, PetEquipmentSlot.head);
    expect(crown.assetPath, 'assets/equipment/hats/crown.png');
  });

  test('filters items by slot', () {
    final headItems = EquipmentCatalog.forSlot(PetEquipmentSlot.head);
    final bodyItems = EquipmentCatalog.forSlot(PetEquipmentSlot.body);

    expect(headItems.map((item) => item.sku), contains('equip_straw_hat'));
    expect(headItems.map((item) => item.sku), contains('equip_crown'));
    expect(bodyItems, isEmpty);
  });

  test('stores crown default fit as a head equipment item', () {
    final item = EquipmentCatalog.bySku('equip_crown');

    expect(item, isNotNull);
    expect(item!.petOverrides, isEmpty);
    expect(item.petStateOverrides, isEmpty);
    expect(item.anchor.x, closeTo(0.5, 0.001));
    expect(item.anchor.y, closeTo(0.82, 0.001));
    expect(item.sizeRatio.w, closeTo(0.34, 0.001));
    expect(item.sizeRatio.h, closeTo(0.34, 0.001));
  });

  test('stores straw hat per-state fit overrides from Godot exports', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');

    expect(item, isNotNull);
    expect(item!.petOverrides, isEmpty);
    expect(item.petStateOverrides.keys, containsAll(['cat', 'fish', 'tiger']));

    final catIdle = item.fitOverrideFor(
      'cat',
      isWalking: false,
      isSleeping: false,
    );
    final fishWalk = item.fitOverrideFor(
      'fish',
      isWalking: true,
      isSleeping: false,
    );
    final tigerSleep = item.fitOverrideFor(
      'tiger',
      isWalking: false,
      isSleeping: true,
    );

    expect(catIdle.anchor?.x, closeTo(0.5, 0.001));
    expect(catIdle.anchor?.y, closeTo(0.7, 0.001));
    expect(fishWalk.anchor?.x, closeTo(0.45, 0.001));
    expect(fishWalk.sizeRatio?.w, closeTo(0.76, 0.001));
    expect(tigerSleep.anchor?.y, closeTo(0.7, 0.001));
  });

  test('stores per-pet fit override values', () {
    const override = EquipmentFitOverride(
      offset: Offset(-0.03, 0.02),
      scale: 0.85,
      anchor: EquipmentAnchor(x: 0.4, y: 0.6),
      sizeRatio: EquipmentSize(w: 0.7, h: 0.3),
    );

    expect(override.offset, const Offset(-0.03, 0.02));
    expect(override.scale, 0.85);
    expect(override.anchor?.x, 0.4);
    expect(override.sizeRatio?.w, 0.7);
  });
}
