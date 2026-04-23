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
}
