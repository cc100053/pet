import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_pet_peek_shift.dart';

void main() {
  final calls = <(bool, bool?)>[];

  Widget build({required bool hidden, int cheerTick = 0}) => MaterialApp(
    home: Stack(
      children: [
        Positioned(
          left: 100,
          top: 100,
          child: HomePetPeekShift(
            hidden: hidden,
            shift: const Offset(-60, 200),
            cheerTick: cheerTick,
            builder: (walking, facingRight) {
              calls.add((walking, facingRight));
              return const SizedBox(key: Key('pet'), width: 10, height: 10);
            },
          ),
        ),
      ],
    ),
  );

  Offset petTopLeft(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const Key('pet')));

  testWidgets('walks to the peek spot and back, facing the way it goes', (
    tester,
  ) async {
    calls.clear();
    await tester.pumpWidget(build(hidden: false));
    expect(petTopLeft(tester), const Offset(100, 100));
    expect(calls.last, (false, null));

    await tester.pumpWidget(build(hidden: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.last, (true, false), reason: 'walking left to the spot');
    await tester.pump(HomePetPeekShift.tripDuration);
    expect(petTopLeft(tester), const Offset(40, 300));
    expect(calls.last, (false, null));

    await tester.pumpWidget(build(hidden: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.last, (true, true), reason: 'walking right on the way back');
    await tester.pump(HomePetPeekShift.tripDuration);
    expect(petTopLeft(tester), const Offset(100, 100));
  });

  testWidgets('hops only while hidden when cheerTick changes', (tester) async {
    await tester.pumpWidget(build(hidden: false));
    await tester.pumpWidget(build(hidden: false, cheerTick: 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(petTopLeft(tester), const Offset(100, 100));

    await tester.pumpWidget(build(hidden: true, cheerTick: 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(hidden: true, cheerTick: 2));
    await tester.pump(const Duration(milliseconds: 210));
    expect(petTopLeft(tester).dy, lessThan(300 - 10));
    await tester.pumpAndSettle();
    expect(petTopLeft(tester), const Offset(40, 300));
  });
}
