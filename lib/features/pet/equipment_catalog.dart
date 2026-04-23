import 'dart:ui';

import 'pet_sockets.dart';

class EquipmentAnchor {
  const EquipmentAnchor({required this.x, required this.y});

  final double x;
  final double y;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);
}

class EquipmentSize {
  const EquipmentSize({required this.w, required this.h});

  final double w;
  final double h;
}

class EquipmentDefinition {
  const EquipmentDefinition({
    required this.sku,
    required this.slot,
    required this.anchor,
    required this.sizeRatio,
    required this.assetPath,
    this.zOrder = 1,
  });

  final String sku;
  final String slot;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final String assetPath;
  final int zOrder;
}

class EquipmentCatalog {
  static const List<EquipmentDefinition> items = [
    EquipmentDefinition(
      sku: 'equip_straw_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.52, y: 0.78),
      sizeRatio: EquipmentSize(w: 0.66, h: 0.34),
      assetPath: 'assets/equipment/hats/straw_hat.png',
      zOrder: 1,
    ),
  ];

  static EquipmentDefinition? bySku(String sku) {
    for (final item in items) {
      if (item.sku == sku) {
        return item;
      }
    }
    return null;
  }

  static List<EquipmentDefinition> forSlot(String slot) {
    return items.where((item) => item.slot == slot).toList(growable: false);
  }
}
