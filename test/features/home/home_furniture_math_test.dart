import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_furniture_math.dart';

void main() {
  test('availableRoomFurnitureCount uses room total and clamps at zero', () {
    expect(availableRoomFurnitureCount(totalOwned: 3, placedCount: 1), 2);
    expect(availableRoomFurnitureCount(totalOwned: 1, placedCount: 4), 0);
  });

  test('clampRoomFurnitureScale enforces the configured bounds', () {
    expect(clampRoomFurnitureScale(0.5), roomFurnitureMinScale);
    expect(clampRoomFurnitureScale(1.2), 1.2);
    expect(clampRoomFurnitureScale(2.4), roomFurnitureMaxScale);
  });

  test('roomFurnitureSizeForScale uses the clamped scale', () {
    final size = roomFurnitureSizeForScale(
      baseSize: const Size(42, 42),
      scale: 2.4,
    );

    expect(size.width, closeTo(84.0, 0.001));
    expect(size.height, closeTo(84.0, 0.001));
  });

  test(
    'normalizedPositionAfterFurnitureResize preserves top-left when possible',
    () {
      final currentSize = roomFurnitureSizeForScale(
        baseSize: const Size(42, 42),
        scale: 1.0,
      );
      final nextSize = roomFurnitureSizeForScale(
        baseSize: const Size(42, 42),
        scale: 1.5,
      );
      const fieldSize = Size(120, 120);
      const normalized = Offset(0.4, 0.4);

      final currentTopLeft = positionFromNormalizedSized(
        normalized: normalized,
        fieldSize: fieldSize,
        itemSize: currentSize,
      );
      final nextNormalized = normalizedPositionAfterFurnitureResize(
        normalized: normalized,
        fieldSize: fieldSize,
        currentSize: currentSize,
        nextSize: nextSize,
      );
      final nextTopLeft = positionFromNormalizedSized(
        normalized: nextNormalized,
        fieldSize: fieldSize,
        itemSize: nextSize,
      );

      expect(nextTopLeft.dx, closeTo(currentTopLeft.dx, 0.001));
      expect(nextTopLeft.dy, closeTo(currentTopLeft.dy, 0.001));
    },
  );

  test('normalizedPositionAfterFurnitureResize reclamps at room edge', () {
    final currentSize = roomFurnitureSizeForScale(
      baseSize: const Size(42, 42),
      scale: 1.0,
    );
    final nextSize = roomFurnitureSizeForScale(
      baseSize: const Size(42, 42),
      scale: roomFurnitureMaxScale,
    );
    const fieldSize = Size(120, 120);
    const normalized = Offset(1, 1);

    final nextNormalized = normalizedPositionAfterFurnitureResize(
      normalized: normalized,
      fieldSize: fieldSize,
      currentSize: currentSize,
      nextSize: nextSize,
    );
    final nextTopLeft = positionFromNormalizedSized(
      normalized: nextNormalized,
      fieldSize: fieldSize,
      itemSize: nextSize,
    );

    expect(nextTopLeft.dx, closeTo(fieldSize.width - nextSize.width, 0.001));
    expect(nextTopLeft.dy, closeTo(fieldSize.height - nextSize.height, 0.001));
  });
}
