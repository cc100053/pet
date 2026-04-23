import 'package:flutter/material.dart';

import '../../pet/equipment_catalog.dart';
import '../../pet/pet_sockets.dart';
import 'pet_equipment_layout.dart';

enum PetEquipmentOverlayLayer { behindPet, frontPet }

class PetEquipmentOverlay extends StatelessWidget {
  const PetEquipmentOverlay({
    super.key,
    required this.petId,
    required this.equippedSkusBySlot,
    required this.petSize,
    required this.layer,
    this.isWalking = false,
    this.isSleeping = false,
    this.showSocketDebug = false,
    this.definitions = EquipmentCatalog.items,
  });

  final String petId;
  final Map<String, String> equippedSkusBySlot;
  final Size petSize;
  final PetEquipmentOverlayLayer layer;
  final bool isWalking;
  final bool isSleeping;
  final bool showSocketDebug;
  final List<EquipmentDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    final socketConfig = PetSocketCatalog.forPet(petId);
    if (socketConfig == null) {
      return SizedBox(width: petSize.width, height: petSize.height);
    }

    final children = <Widget>[];
    for (final entry in equippedSkusBySlot.entries) {
      final definition = _definitionForSku(entry.value);
      if (definition == null) {
        continue;
      }
      final wantsBehind = definition.zOrder < 0;
      if (layer == PetEquipmentOverlayLayer.behindPet && !wantsBehind) {
        continue;
      }
      if (layer == PetEquipmentOverlayLayer.frontPet && wantsBehind) {
        continue;
      }
      final socket = socketConfig.resolve(
        entry.key,
        isWalking: isWalking,
        isSleeping: isSleeping,
      );
      if (socket == null) {
        continue;
      }

      final override =
          definition.petOverrides[petId] ?? const EquipmentFitOverride();
      final placement = resolveEquipmentPlacement(
        petSize: petSize,
        socket: socket,
        anchor: definition.anchor,
        sizeRatio: definition.sizeRatio,
        normalizedOffset: override.offset,
        scale: override.scale,
      );

      children.add(
        Positioned(
          key: ValueKey(
            'pet-equipment-${layer.name}-${entry.key}-${definition.sku}',
          ),
          left: placement.topLeft.dx,
          top: placement.topLeft.dy,
          child: Image.asset(
            definition.assetPath,
            width: placement.itemSize.width,
            height: placement.itemSize.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    }

    if (showSocketDebug && layer == PetEquipmentOverlayLayer.frontPet) {
      for (final slot in PetEquipmentSlot.values) {
        final socket = socketConfig.resolve(
          slot,
          isWalking: isWalking,
          isSleeping: isSleeping,
        );
        if (socket == null) {
          continue;
        }
        final offset = socket.toOffset(petSize);
        children.add(
          Positioned(
            key: ValueKey('pet-socket-debug-$slot'),
            left: offset.dx - 4,
            top: offset.dy - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _socketDebugColor(slot),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: petSize.width,
      height: petSize.height,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  EquipmentDefinition? _definitionForSku(String sku) {
    for (final definition in definitions) {
      if (definition.sku == sku) {
        return definition;
      }
    }
    return null;
  }

  Color _socketDebugColor(String slot) {
    switch (slot) {
      case PetEquipmentSlot.head:
        return const Color(0xFFFF6B6B);
      case PetEquipmentSlot.body:
        return const Color(0xFF4CAF50);
      case PetEquipmentSlot.back:
        return const Color(0xFF42A5F5);
    }
    return Colors.black;
  }
}
