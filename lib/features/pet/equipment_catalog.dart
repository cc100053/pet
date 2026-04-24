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

  const EquipmentSize.fromWidthAspect({
    required double widthRatio,
    required double aspectRatio,
  }) : w = widthRatio,
       h = widthRatio / aspectRatio;

  final double w;
  final double h;
}

class EquipmentFitOverride {
  const EquipmentFitOverride({this.offset = Offset.zero, this.scale = 1});

  final Offset offset;
  final double scale;
}

class EquipmentDefinition {
  const EquipmentDefinition({
    required this.sku,
    required this.slot,
    required this.anchor,
    required this.sizeRatio,
    required this.assetPath,
    this.petOverrides = const <String, EquipmentFitOverride>{},
    this.zOrder = 1,
  });

  final String sku;
  final String slot;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final String assetPath;
  final Map<String, EquipmentFitOverride> petOverrides;
  final int zOrder;
}

class EquipmentCatalog {
  static const List<EquipmentDefinition> items = [
    EquipmentDefinition(
      sku: 'equip_straw_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 0.55),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.8,
        aspectRatio: 1821 / 700,
      ),
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
