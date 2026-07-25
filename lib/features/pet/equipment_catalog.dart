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
    this.incompatiblePetIds = const <String>{},
    this.zOrder = 1,
  });

  final String sku;
  final String slot;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final String assetPath;
  final Map<String, EquipmentFitOverride> petOverrides;
  final Map<String, EquipmentStateFitOverrides> petStateOverrides;
  final Set<String> incompatiblePetIds;
  final int zOrder;

  bool isCompatibleWithPet(String petId) => !incompatiblePetIds.contains(petId);

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
    // ── Straw Hat ──────────────────────────────────────────
    // Default (ghost): anchor(0.5, 0.55), size 0.8
    EquipmentDefinition(
      sku: 'equip_straw_hat',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 0.55),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.8,
        aspectRatio: 1821 / 700,
      ),
      assetPath: 'assets/equipment/hats/straw_hat.png',
      petOverrides: {
        'cat': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.75),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.8,
            aspectRatio: 1821 / 700,
          ),
        ),
        'fish': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.45, y: 0.65),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.65,
            aspectRatio: 1821 / 700,
          ),
        ),
        'tiger': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.9),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.8,
            aspectRatio: 1821 / 700,
          ),
        ),
        'chicken': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.45, y: 0.85),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.56,
            aspectRatio: 1821 / 700,
          ),
        ),
      },
      zOrder: 1,
    ),

    // ── Crown ──────────────────────────────────────────────
    // Default (ghost): anchor(0.5, 0.55), size 0.32
    EquipmentDefinition(
      sku: 'equip_crown',
      slot: PetEquipmentSlot.head,
      anchor: EquipmentAnchor(x: 0.5, y: 0.55),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.32,
        aspectRatio: 1,
      ),
      assetPath: 'assets/equipment/hats/crown.png',
      petOverrides: {
        'cat': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.7),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.32,
            aspectRatio: 1,
          ),
        ),
        'fish': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.4, y: 0.6),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.32,
            aspectRatio: 1,
          ),
        ),
        'tiger': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.9),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.32,
            aspectRatio: 1,
          ),
        ),
        'chicken': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.35, y: 0.85),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.32,
            aspectRatio: 1,
          ),
        ),
      },
      petStateOverrides: {
        'chicken': EquipmentStateFitOverrides(
          sleep: EquipmentFitOverride(
            anchor: EquipmentAnchor(x: 0.4, y: 0.65),
            sizeRatio: EquipmentSize.fromWidthAspect(
              widthRatio: 0.32,
              aspectRatio: 1,
            ),
          ),
        ),
      },
      zOrder: 1,
    ),

    // ── Ribbon ─────────────────────────────────────────────
    // All configured pets share the same anchor/size; tiger body hidden during sleep
    EquipmentDefinition(
      sku: 'equip_ribbon',
      slot: PetEquipmentSlot.body,
      anchor: EquipmentAnchor(x: 0.5, y: 0.2),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.32,
        aspectRatio: 1,
      ),
      assetPath: 'assets/equipment/ribbon.png',
      petOverrides: {
        'chicken': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.65, y: 0.5),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.32,
            aspectRatio: 1,
          ),
        ),
      },
      zOrder: 1,
    ),

    // ── Sunglasses ─────────────────────────────────────────
    // Default (ghost): anchor(0.6, 0.0), size 0.45
    EquipmentDefinition(
      sku: 'equip_sunglasses',
      slot: PetEquipmentSlot.face,
      anchor: EquipmentAnchor(x: 0.6, y: 0.0),
      sizeRatio: EquipmentSize.fromWidthAspect(
        widthRatio: 0.45,
        aspectRatio: 1,
      ),
      assetPath: 'assets/equipment/sunglasses.png',
      petOverrides: {
        'cat': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.2),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.45,
            aspectRatio: 1,
          ),
        ),
        'fish': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.05),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.36,
            aspectRatio: 1,
          ),
        ),
        'tiger': EquipmentFitOverride(
          anchor: EquipmentAnchor(x: 0.5, y: 0.2),
          sizeRatio: EquipmentSize.fromWidthAspect(
            widthRatio: 0.45,
            aspectRatio: 1,
          ),
        ),
      },
      incompatiblePetIds: {'chicken'},
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

  static bool isSkuCompatibleWithPet(String sku, String petId) {
    return bySku(sku)?.isCompatibleWithPet(petId) ?? true;
  }
}
