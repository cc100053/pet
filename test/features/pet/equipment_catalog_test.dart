import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/equipment_catalog.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  test('looks up straw hat by sku', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');

    expect(item, isNotNull);
    expect(item!.slot, PetEquipmentSlot.head);
    expect(item.assetPath, 'assets/equipment/hats/straw_hat.png');
  });

  test('filters items by slot', () {
    final headItems = EquipmentCatalog.forSlot(PetEquipmentSlot.head);
    final bodyItems = EquipmentCatalog.forSlot(PetEquipmentSlot.body);

    expect(headItems.map((item) => item.sku), contains('equip_straw_hat'));
    expect(bodyItems, isEmpty);
  });

  test('defaults per-pet fit overrides to empty', () {
    final item = EquipmentCatalog.bySku('equip_straw_hat');

    expect(item, isNotNull);
    expect(item!.petOverrides, isEmpty);
  });

  test('stores per-pet fit override offset and scale', () {
    const override = EquipmentFitOverride(
      offset: Offset(-0.03, 0.02),
      scale: 0.85,
    );

    expect(override.offset, const Offset(-0.03, 0.02));
    expect(override.scale, 0.85);
  });
}
