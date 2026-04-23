import 'dart:ui';

import '../../pet/equipment_catalog.dart';
import '../../pet/pet_sockets.dart';

class EquipmentPlacement {
  const EquipmentPlacement({
    required this.itemSize,
    required this.socketOffset,
    required this.anchorOffset,
    required this.topLeft,
  });

  final Size itemSize;
  final Offset socketOffset;
  final Offset anchorOffset;
  final Offset topLeft;
}

EquipmentPlacement resolveEquipmentPlacement({
  required Size petSize,
  required PetSocket socket,
  required EquipmentAnchor anchor,
  required EquipmentSize sizeRatio,
  Offset normalizedOffset = Offset.zero,
  double scale = 1,
}) {
  final itemSize = Size(
    sizeRatio.w * petSize.width * scale,
    sizeRatio.h * petSize.height * scale,
  );
  final socketOffset =
      socket.toOffset(petSize) +
      Offset(
        normalizedOffset.dx * petSize.width,
        normalizedOffset.dy * petSize.height,
      );
  final anchorOffset = anchor.toOffset(itemSize);

  return EquipmentPlacement(
    itemSize: itemSize,
    socketOffset: socketOffset,
    anchorOffset: anchorOffset,
    topLeft: socketOffset - anchorOffset,
  );
}
