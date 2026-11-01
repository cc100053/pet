import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_furniture_math.dart';

FurnitureLayerBox box(
  String id,
  double left,
  double top,
  double z, {
  bool floor = false,
}) => FurnitureLayerBox(
  id: id,
  rect: Rect.fromLTWH(left, top, 40, 40),
  z: z,
  isFloor: floor,
);

void main() {
  group('autoFurnitureZ', () {
    test('a piece lower in the room goes in front of what it overlaps', () {
      final chair = box('chair', 0, 0, 5);
      final lamp = box('lamp', 10, 20, 1);
      expect(autoFurnitureZ(lamp, [chair, lamp]), 6);
    });

    test('a piece higher in the room goes behind what it overlaps', () {
      final chair = box('chair', 0, 20, 1);
      final lamp = box('lamp', 10, 0, 5);
      expect(autoFurnitureZ(lamp, [chair]), 0);
    });

    test('slots between a piece behind and a piece in front', () {
      final back = box('back', 0, 0, 1);
      final front = box('front', 0, 30, 3);
      final mid = box('mid', 0, 15, 9);
      expect(autoFurnitureZ(mid, [back, front]), 2);
    });

    test('a rug stays behind standing furniture even when lower', () {
      final chair = box('chair', 0, 0, 1);
      final rug = box('rug', 0, 20, 5, floor: true);
      expect(autoFurnitureZ(rug, [chair]), 0);
      final chair2 = box('chair2', 0, 30, 0);
      expect(autoFurnitureZ(chair2, [box('rug', 0, 0, 5, floor: true)]), 6);
    });

    test('no change when already correct, isolated, or no gap exists', () {
      expect(autoFurnitureZ(box('a', 0, 20, 2), [box('b', 0, 0, 1)]), isNull);
      expect(
        autoFurnitureZ(box('a', 0, 0, 2), [box('b', 100, 100, 9)]),
        isNull,
      );
      final behind = box('behind', 0, 0, 5);
      final front = box('front', 0, 30, 1);
      expect(autoFurnitureZ(box('t', 0, 15, 9), [behind, front]), isNull);
    });
  });

  group('movedFurnitureZ', () {
    final target = box('t', 0, 0, 2);
    final over = box('over', 10, 10, 3);
    final elsewhere = box('elsewhere', 200, 200, 4);
    final under = box('under', 5, 5, 1);
    final all = [target, over, elsewhere, under];

    test('forward steps past the next overlapping piece only', () {
      expect(movedFurnitureZ(target, all, FurnitureLayerMove.forward), 3.5);
    });

    test('backward steps below the next overlapping piece', () {
      expect(movedFurnitureZ(target, all, FurnitureLayerMove.backward), 0);
    });

    test('front and back go past every piece', () {
      expect(movedFurnitureZ(target, all, FurnitureLayerMove.front), 5);
      expect(movedFurnitureZ(target, all, FurnitureLayerMove.back), 0);
    });

    test('returns null when nothing overlapping is in that direction', () {
      final top = box('top', 0, 0, 10);
      expect(
        movedFurnitureZ(top, [top, under], FurnitureLayerMove.front),
        isNull,
      );
      expect(
        movedFurnitureZ(top, [top, under], FurnitureLayerMove.forward),
        isNull,
      );
      expect(
        movedFurnitureZ(top, [top, elsewhere], FurnitureLayerMove.back),
        isNull,
      );
    });
  });
}
