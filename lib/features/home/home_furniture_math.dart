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

double roundRoomFurnitureScaleToStep(double scale) {
  final clamped = clampRoomFurnitureScale(scale);
  final offsetSteps =
      ((clamped - roomFurnitureMinScale) / roomFurnitureScaleStep).round();
  final rounded =
      roomFurnitureMinScale + (offsetSteps * roomFurnitureScaleStep);
  return clampRoomFurnitureScale((rounded * 100).roundToDouble() / 100);
}

double nudgeRoomFurnitureScale(double scale, {required int stepDelta}) {
  if (stepDelta == 0) {
    return roundRoomFurnitureScaleToStep(scale);
  }
  return roundRoomFurnitureScaleToStep(
    scale + (stepDelta * roomFurnitureScaleStep),
  );
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

/// A placed piece as the layering helpers see it: its on-canvas footprint and
/// stored z (higher draws in front).
class FurnitureLayerBox {
  const FurnitureLayerBox({
    required this.id,
    required this.rect,
    required this.z,
    this.isFloor = false,
  });

  final String id;
  final Rect rect;
  final double z;
  final bool isFloor;
}

enum FurnitureLayerMove { front, forward, backward, back }

/// Auto-layering after a place/move: [target] goes in front of the pieces it
/// overlaps that sit higher in the room (smaller bottom edge) and behind the
/// ones lower down; floor pieces stay behind standing ones. Returns null when
/// the current z already satisfies that.
double? autoFurnitureZ(
  FurnitureLayerBox target,
  Iterable<FurnitureLayerBox> others,
) {
  var lo = double.negativeInfinity;
  var hi = double.infinity;
  for (final other in others) {
    if (other.id == target.id || !other.rect.overlaps(target.rect)) {
      continue;
    }
    final behind = other.isFloor != target.isFloor
        ? other.isFloor
        : other.rect.bottom <= target.rect.bottom;
    if (behind) {
      lo = max(lo, other.z);
    } else {
      hi = min(hi, other.z);
    }
  }
  if (target.z > lo && target.z < hi) {
    return null;
  }
  // shortcut: manual overrides can leave no gap (lo >= hi); the piece then
  // keeps its layer. Upgrade to renumbering the overlap group if users hit it.
  if (lo >= hi) {
    return null;
  }
  if (lo == double.negativeInfinity) {
    return hi - 1;
  }
  if (hi == double.infinity) {
    return lo + 1;
  }
  return (lo + hi) / 2;
}

/// Manual layering. Forward/backward step past the next piece [target]
/// overlaps (a global step could swap with a piece elsewhere and show no
/// change). Returns null when the move would change nothing visible.
double? movedFurnitureZ(
  FurnitureLayerBox target,
  Iterable<FurnitureLayerBox> others,
  FurnitureLayerMove move,
) {
  final rest = others.where((o) => o.id != target.id).toList();
  final overlapping = rest.where((o) => o.rect.overlaps(target.rect));
  final above = overlapping.where((o) => o.z > target.z).toList()
    ..sort((a, b) => a.z.compareTo(b.z));
  final below = overlapping.where((o) => o.z < target.z).toList()
    ..sort((a, b) => b.z.compareTo(a.z));
  switch (move) {
    case FurnitureLayerMove.front:
      return above.isEmpty ? null : rest.map((o) => o.z).reduce(max) + 1;
    case FurnitureLayerMove.back:
      return below.isEmpty ? null : rest.map((o) => o.z).reduce(min) - 1;
    case FurnitureLayerMove.forward:
      if (above.isEmpty) {
        return null;
      }
      final passed = above.first.z;
      final next = rest
          .where((o) => o.z > passed)
          .fold(double.infinity, (v, o) => min(v, o.z));
      return next == double.infinity ? passed + 1 : (passed + next) / 2;
    case FurnitureLayerMove.backward:
      if (below.isEmpty) {
        return null;
      }
      final passed = below.first.z;
      final next = rest
          .where((o) => o.z < passed)
          .fold(double.negativeInfinity, (v, o) => max(v, o.z));
      return next == double.negativeInfinity ? passed - 1 : (passed + next) / 2;
  }
}
