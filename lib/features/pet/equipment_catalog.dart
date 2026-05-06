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
  const EquipmentFitOverride({
    this.offset = Offset.zero,
    this.scale = 1,
    this.anchor,
    this.sizeRatio,
  });

  final Offset offset;
  final double scale;
  final EquipmentAnchor? anchor;
  final EquipmentSize? sizeRatio;
}

class EquipmentStateFitOverrides {
  const EquipmentStateFitOverrides({this.idle, this.walk, this.sleep});

  final EquipmentFitOverride? idle;
  final EquipmentFitOverride? walk;
  final EquipmentFitOverride? sleep;

  EquipmentFitOverride? resolve({
    required bool isWalking,
    required bool isSleeping,
  }) {
    if (isWalking) {
      return walk ?? idle;
    }
    if (isSleeping) {
      return sleep ?? idle;
    }
    return idle;
  }
}

class EquipmentDefinition {
  const EquipmentDefinition({
    required this.sku,
    required this.slot,
    required this.anchor,
    required this.sizeRatio,
    required this.assetPath,
    this.petOverrides = const <String, EquipmentFitOverride>{},
    this.petStateOverrides = const <String, EquipmentStateFitOverrides>{},
    this.zOrder = 1,
  });

  final String sku;
  final String slot;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final String assetPath;
  final Map<String, EquipmentFitOverride> petOverrides;
  final Map<String, EquipmentStateFitOverrides> petStateOverrides;
  final int zOrder;

  EquipmentFitOverride fitOverrideFor(
    String petId, {
    required bool isWalking,
    required bool isSleeping,
  }) {
    final stateOverride = petStateOverrides[petId]?.resolve(
      isWalking: isWalking,
      isSleeping: isSleeping,
    );
    return stateOverride ?? petOverrides[petId] ?? const EquipmentFitOverride();
  }
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
      petStateOverrides: {
        'cat': EquipmentStateFitOverrides(
          idle: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.7),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
          walk: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.7),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
          sleep: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.7),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
        ),
        'fish': EquipmentStateFitOverrides(
          idle: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.45, y: 0.6),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.76,
              aspectRatio: 1821 / 700,
            ),
          ),
          walk: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.45, y: 0.6),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.76,
              aspectRatio: 1821 / 700,
            ),
          ),
          sleep: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.45, y: 0.6),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.76,
              aspectRatio: 1821 / 700,
            ),
          ),
        ),
        'tiger': EquipmentStateFitOverrides(
          idle: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.9),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
          walk: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.9),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
          sleep: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.5, y: 0.7),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.8,
              aspectRatio: 1821 / 700,
            ),
          ),
        ),
      },
      zOrder: 1,
    ),
    EquipmentDefinition(
      sku: 'equip_crown',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 0.82),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.34,
        aspectRatio: 1,
      ),
      assetPath: 'assets/equipment/hats/crown.png',
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
