import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_canvas.dart';

void main() {
  group('RoomCanvas.contentRect', () {
    test('matches canvas aspect ratio and is centered', () {
      for (final field in const [
        Size(300, 600),
        Size(800, 600),
        Size(412, 380),
        Size(540, 300),
      ]) {
        final rect = RoomCanvas.contentRect(field);
        expect(
          rect.width / rect.height,
          closeTo(RoomCanvas.aspectRatio, 1e-9),
          reason: 'aspect for $field',
        );
        // Centered inside the field.
        expect(rect.left, closeTo((field.width - rect.width) / 2, 1e-9));
        expect(rect.top, closeTo((field.height - rect.height) / 2, 1e-9));
        // Fits within the field.
        expect(rect.width, lessThanOrEqualTo(field.width + 1e-9));
        expect(rect.height, lessThanOrEqualTo(field.height + 1e-9));
      }
    });

    test('empty field yields zero rect', () {
      expect(RoomCanvas.contentRect(Size.zero), Rect.zero);
      expect(RoomCanvas.contentRect(const Size(0, 100)), Rect.zero);
    });
  });

  group('center fraction round-trip is device independent', () {
    test('same fraction -> same relative spot across field sizes', () {
      const fraction = Offset(0.3, 0.7);
      const scale = 1.4;

      Offset relativeCenter(Size field) {
        final content = RoomCanvas.contentRect(field);
        final size = RoomCanvas.furnitureSize(content, scale);
        final topLeft = RoomCanvas.topLeftFromCenterFraction(
          centerFraction: fraction,
          content: content,
          itemSize: size,
        );
        final center = topLeft + Offset(size.width / 2, size.height / 2);
        // Position of the item center expressed as a fraction of the content
        // rect must be identical regardless of device size.
        return Offset(
          (center.dx - content.left) / content.width,
          (center.dy - content.top) / content.height,
        );
      }

      final a = relativeCenter(const Size(320, 480));
      final b = relativeCenter(const Size(800, 1000));
      expect(a.dx, closeTo(b.dx, 1e-9));
      expect(a.dy, closeTo(b.dy, 1e-9));
      expect(a.dx, closeTo(fraction.dx, 1e-9));
      expect(a.dy, closeTo(fraction.dy, 1e-9));
    });

    test('topLeft <-> centerFraction is invertible', () {
      final content = RoomCanvas.contentRect(const Size(420, 700));
      const fraction = Offset(0.62, 0.18);
      final size = RoomCanvas.furnitureSize(content, 1.0);
      final topLeft = RoomCanvas.topLeftFromCenterFraction(
        centerFraction: fraction,
        content: content,
        itemSize: size,
      );
      final center = topLeft + Offset(size.width / 2, size.height / 2);
      final back = RoomCanvas.centerFractionFromCenter(
        center: center,
        content: content,
      );
      expect(back.dx, closeTo(fraction.dx, 1e-9));
      expect(back.dy, closeTo(fraction.dy, 1e-9));
    });
  });

  group('furnitureSize scales with the canvas', () {
    test('bigger canvas -> proportionally bigger furniture', () {
      final small = RoomCanvas.furnitureSize(
        RoomCanvas.contentRect(const Size(320, 480)),
        1.0,
      );
      final big = RoomCanvas.furnitureSize(
        RoomCanvas.contentRect(const Size(640, 960)),
        1.0,
      );
      // Same relative footprint, larger absolute size on the larger canvas.
      expect(big.width, greaterThan(small.width));
      expect(big.width / small.width, closeTo(2.0, 1e-9));
    });

    test('scale multiplier is linear', () {
      final content = RoomCanvas.contentRect(const Size(400, 600));
      final base = RoomCanvas.furnitureSize(content, 1.0);
      final scaled = RoomCanvas.furnitureSize(content, 2.0);
      expect(scaled.width / base.width, closeTo(2.0, 1e-9));
    });
  });

  group('clampCenterFraction keeps the item inside the canvas', () {
    test('clamps so half-extent stays in range', () {
      final content = RoomCanvas.contentRect(const Size(360, 540));
      final size = RoomCanvas.furnitureSize(content, 2.0);
      final clamped = RoomCanvas.clampCenterFraction(
        centerFraction: const Offset(1.5, -0.4),
        content: content,
        itemSize: size,
      );
      final halfFx = (size.width / 2) / content.width;
      final halfFy = (size.height / 2) / content.height;
      expect(clamped.dx, lessThanOrEqualTo(1 - halfFx + 1e-9));
      expect(clamped.dx, greaterThanOrEqualTo(halfFx - 1e-9));
      expect(clamped.dy, lessThanOrEqualTo(1 - halfFy + 1e-9));
      expect(clamped.dy, greaterThanOrEqualTo(halfFy - 1e-9));
    });
  });
}
