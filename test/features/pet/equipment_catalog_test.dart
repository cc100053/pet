import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/equipment_catalog.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  test('looks up head equipment by sku', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');
    final crown = EquipmentCatalog.bySku('equip_crown');
    final sunglasses = EquipmentCatalog.bySku('equip_sunglasses');

    expect(item, isNotNull);
    expect(item!.slot, PetEquipmentSlot.head);
    expect(item.assetPath, 'assets/equipment/hats/straw_hat.png');
    expect(crown, isNotNull);
    expect(crown!.slot, PetEquipmentSlot.head);
    expect(crown.assetPath, 'assets/equipment/hats/crown.png');
    expect(sunglasses, isNotNull);
    expect(sunglasses!.slot, PetEquipmentSlot.face);
  });

  test('filters items by slot', () {
    final headItems = EquipmentCatalog.forSlot(PetEquipmentSlot.head);
    final faceItems = EquipmentCatalog.forSlot(PetEquipmentSlot.face);
    final bodyItems = EquipmentCatalog.forSlot(PetEquipmentSlot.body);

    expect(headItems.map((item) => item.sku), contains('equip_straw_hat'));
    expect(headItems.map((item) => item.sku), contains('equip_crown'));
    expect(
      headItems.map((item) => item.sku),
      isNot(contains('equip_sunglasses')),
    );
    expect(faceItems.map((item) => item.sku), contains('equip_sunglasses'));
    expect(bodyItems.map((item) => item.sku), contains('equip_ribbon'));
  });

  test('stores crown fit values from Godot exports', () {
    final item = EquipmentCatalog.bySku('equip_crown');

    expect(item, isNotNull);
    expect(item!.petOverrides.keys, containsAll(['cat', 'fish', 'tiger']));
    expect(item.petStateOverrides, isEmpty);
    expect(item.anchor.x, closeTo(0.5, 0.001));
    expect(item.anchor.y, closeTo(0.55, 0.001));
    expect(item.sizeRatio.w, closeTo(0.32, 0.001));
    expect(item.sizeRatio.h, closeTo(0.32, 0.001));

    final cat = item.fitOverrideFor('cat', isWalking: false, isSleeping: false);
    final fish = item.fitOverrideFor(
      'fish',
      isWalking: false,
      isSleeping: false,
    );
    final tiger = item.fitOverrideFor(
      'tiger',
      isWalking: false,
      isSleeping: false,
    );

    expect(cat.anchor?.y, closeTo(0.7, 0.001));
    expect(fish.anchor?.x, closeTo(0.4, 0.001));
    expect(fish.anchor?.y, closeTo(0.6, 0.001));
    expect(tiger.anchor?.y, closeTo(0.9, 0.001));
  });

  test('stores straw hat per-pet fit overrides from Godot exports', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');

    expect(item, isNotNull);
    expect(item!.petOverrides.keys, containsAll(['cat', 'fish', 'tiger']));
    expect(item.petStateOverrides, isEmpty);

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
    expect(catIdle.anchor?.y, closeTo(0.75, 0.001));
    expect(fishWalk.anchor?.x, closeTo(0.45, 0.001));
    expect(fishWalk.sizeRatio?.w, closeTo(0.65, 0.001));
    expect(tigerSleep.anchor?.y, closeTo(0.9, 0.001));
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
