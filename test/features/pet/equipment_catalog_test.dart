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
}
