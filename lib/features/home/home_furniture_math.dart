import 'dart:math';

import 'package:flutter/widgets.dart';

const double roomFurnitureMinScale = 0.8;
const double roomFurnitureMaxScale = 2.0;
const double roomFurnitureScaleStep = 0.1;

int availableRoomFurnitureCount({
  required int totalOwned,
  required int placedCount,
}) {
  return max(0, totalOwned - placedCount);
}

double clampRoomFurnitureScale(double scale) {
  return scale.clamp(roomFurnitureMinScale, roomFurnitureMaxScale);
}

Size roomFurnitureSizeForScale({
  required Size baseSize,
  required double scale,
}) {
  final effectiveScale = clampRoomFurnitureScale(scale);
  return Size(
    baseSize.width * effectiveScale,
    baseSize.height * effectiveScale,
  );
}

Offset normalizedPositionFromTopLeftSized({
  required Offset topLeft,
  required Size fieldSize,
  required Size itemSize,
}) {
  final maxX = max(0.0, fieldSize.width - itemSize.width);
  final maxY = max(0.0, fieldSize.height - itemSize.height);
  final normalizedX = maxX == 0 ? 0.0 : topLeft.dx / maxX;
  final normalizedY = maxY == 0 ? 0.0 : topLeft.dy / maxY;
  return Offset(normalizedX, normalizedY);
}

Offset positionFromNormalizedSized({
  required Offset normalized,
  required Size fieldSize,
  required Size itemSize,
}) {
  final maxX = max(0.0, fieldSize.width - itemSize.width);
  final maxY = max(0.0, fieldSize.height - itemSize.height);
  return Offset(normalized.dx * maxX, normalized.dy * maxY);
}

Offset clampTopLeftSized({
  required Offset topLeft,
  required Size fieldSize,
  required Size itemSize,
}) {
  final maxX = max(0.0, fieldSize.width - itemSize.width);
  final maxY = max(0.0, fieldSize.height - itemSize.height);
  final clampedX = topLeft.dx.clamp(0.0, maxX);
  final clampedY = topLeft.dy.clamp(0.0, maxY);
  return Offset(clampedX, clampedY);
}

Offset normalizedPositionAfterFurnitureResize({
  required Offset normalized,
  required Size fieldSize,
  required Size currentSize,
  required Size nextSize,
}) {
  final currentTopLeft = positionFromNormalizedSized(
    normalized: normalized,
    fieldSize: fieldSize,
    itemSize: currentSize,
  );
  final clampedTopLeft = clampTopLeftSized(
    topLeft: currentTopLeft,
    fieldSize: fieldSize,
    itemSize: nextSize,
  );
  return normalizedPositionFromTopLeftSized(
    topLeft: clampedTopLeft,
    fieldSize: fieldSize,
    itemSize: nextSize,
  );
}
