import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/pet_equipment_layout.dart';
import 'package:pet/features/pet/equipment_catalog.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  test('resolves top-left from socket and anchor', () {
    final placement = resolveEquipmentPlacement(
      petSize: const Size(100, 100),
      socket: const PetSocket(x: 0.5, y: 0.25),
      anchor: const EquipmentAnchor(x: 0.5, y: 1),
      sizeRatio: const EquipmentSize(w: 0.4, h: 0.2),
    );

    expect(placement.itemSize, const Size(40, 20));
    expect(placement.socketOffset, const Offset(50, 25));
    expect(placement.anchorOffset, const Offset(20, 20));
    expect(placement.topLeft, const Offset(30, 5));
  });

  test('applies normalized offset against pet size', () {
    final placement = resolveEquipmentPlacement(
      petSize: const Size(100, 100),
      socket: const PetSocket(x: 0.5, y: 0.25),
      anchor: const EquipmentAnchor(x: 0.5, y: 1),
      sizeRatio: const EquipmentSize(w: 0.4, h: 0.2),
      normalizedOffset: const Offset(0.1, -0.05),
    );

    expect(placement.socketOffset, const Offset(60, 20));
    expect(placement.topLeft, const Offset(40, 0));
  });

  test('scales item size before anchor calculation', () {
    final placement = resolveEquipmentPlacement(
      petSize: const Size(100, 100),
      socket: const PetSocket(x: 0.5, y: 0.25),
      anchor: const EquipmentAnchor(x: 0.5, y: 1),
      sizeRatio: const EquipmentSize(w: 0.4, h: 0.2),
      scale: 0.5,
    );

    expect(placement.itemSize, const Size(20, 10));
    expect(placement.anchorOffset, const Offset(10, 10));
    expect(placement.topLeft, const Offset(40, 15));
  });

  test('supports width ratio plus source image aspect sizing', () {
    const sizeRatio = EquipmentSize.fromWidthAspect(
      widthRatio: 0.8,
      aspectRatio: 1821 / 700,
    );

    final placement = resolveEquipmentPlacement(
      petSize: const Size(450, 450),
      socket: const PetSocket(x: 214 / 450, y: 59 / 450),
      anchor: const EquipmentAnchor(x: 0.5, y: 0.55),
      sizeRatio: sizeRatio,
    );

    expect(placement.itemSize.width, closeTo(360, 0.001));
    expect(placement.itemSize.height, closeTo(138.3855, 0.001));
    expect(placement.anchorOffset.dx, closeTo(180, 0.001));
    expect(placement.anchorOffset.dy, closeTo(76.1126, 0.001));
    expect(placement.topLeft.dx, closeTo(34, 0.001));
    expect(placement.topLeft.dy, closeTo(-17.1126, 0.001));
  });

  test('straw hat catalog values match the Godot equipment preview export', () {
    final definition = EquipmentCatalog.bySku('equip_straw_hat');

    expect(definition, isNotNull);
    expect(definition!.anchor.x, closeTo(0.5, 0.001));
    expect(definition.anchor.y, closeTo(0.55, 0.001));
    expect(definition.sizeRatio.w, closeTo(0.8, 0.001));
    expect(definition.sizeRatio.h, closeTo(0.8 / (1821 / 700), 0.001));
  });

  test('crown catalog values use head socket with square source aspect', () {
    final definition = EquipmentCatalog.bySku('equip_crown');

    expect(definition, isNotNull);
    expect(definition!.anchor.x, closeTo(0.5, 0.001));
    expect(definition.anchor.y, closeTo(0.55, 0.001));
    expect(definition.sizeRatio.w, closeTo(0.32, 0.001));
    expect(definition.sizeRatio.h, closeTo(0.32, 0.001));
  });
}
