import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_furniture_math.dart';
import 'package:pet/features/home/widgets/home_furniture_edit_bar.dart';

void main() {
  Widget build(Widget bar) => MaterialApp(
    home: Scaffold(
      body: Align(alignment: Alignment.bottomCenter, child: bar),
    ),
  );

  testWidgets('without a selection shows the hint and Done', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      build(
        HomeFurnitureEditBar(
          hint: 'Tap a piece',
          doneLabel: 'Done',
          onDone: () => done++,
        ),
      ),
    );
    expect(find.text('Tap a piece'), findsOneWidget);
    expect(find.byKey(const Key('home_furniture_flip')), findsNothing);
    await tester.tap(find.byKey(const Key('home_furniture_done')));
    expect(done, 1);
  });

  testWidgets(
    'selection actions fire and the layer menu respects availability',
    (tester) async {
      final calls = <String>[];
      FurnitureLayerAction layer(
        FurnitureLayerMove move, {
        bool enabled = true,
      }) => FurnitureLayerAction(
        move: move,
        label: move.name,
        onSelected: enabled ? () => calls.add(move.name) : null,
      );
      await tester.pumpWidget(
        build(
          HomeFurnitureEditBar(
            hint: 'hint',
            doneLabel: 'Done',
            onDone: () {},
            selection: HomeFurnitureSelectionActions(
              decreaseLabel: 'Smaller',
              increaseLabel: 'Bigger',
              flipLabel: 'Flip',
              layerLabel: 'Layer',
              storeLabel: 'Put away',
              onDecrease: null,
              onIncrease: () => calls.add('bigger'),
              onFlip: () => calls.add('flip'),
              onStore: () => calls.add('store'),
              layerActions: [
                layer(FurnitureLayerMove.front),
                layer(FurnitureLayerMove.forward),
                layer(FurnitureLayerMove.backward, enabled: false),
                layer(FurnitureLayerMove.back, enabled: false),
              ],
            ),
          ),
        ),
      );
      expect(find.text('hint'), findsNothing);
      await tester.tap(find.byKey(const Key('home_furniture_scale_decrease')));
      await tester.tap(find.byKey(const Key('home_furniture_scale_increase')));
      await tester.tap(find.byKey(const Key('home_furniture_flip')));
      await tester.tap(find.byKey(const Key('home_furniture_store')));
      expect(calls, ['bigger', 'flip', 'store']);

      await tester.tap(find.byKey(const Key('home_furniture_layer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home_furniture_layer_backward')));
      await tester.pumpAndSettle();
      expect(calls, ['bigger', 'flip', 'store'], reason: 'disabled entry');

      await tester.tap(find.byKey(const Key('home_furniture_layer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home_furniture_layer_forward')));
      await tester.pumpAndSettle();
      expect(calls.last, 'forward');
    },
  );

  testWidgets('fits the nav bar height on the narrowest phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      build(
        HomeFurnitureEditBar(
          hint: 'hint',
          doneLabel: 'Done',
          onDone: () {},
          selection: HomeFurnitureSelectionActions(
            decreaseLabel: 'a',
            increaseLabel: 'b',
            flipLabel: 'c',
            layerLabel: 'd',
            storeLabel: 'e',
            onDecrease: () {},
            onIncrease: () {},
            onFlip: () {},
            onStore: () {},
            layerActions: const [],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Five ~44pt actions plus Done fit side by side without overlapping.
    final flip = tester.getRect(find.byKey(const Key('home_furniture_flip')));
    final store = tester.getRect(find.byKey(const Key('home_furniture_store')));
    final done = tester.getRect(find.byKey(const Key('home_furniture_done')));
    expect(flip.width, greaterThan(40));
    expect(store.right, lessThanOrEqualTo(done.left));
    expect(
      tester.getSize(find.byKey(const Key('home_furniture_edit_bar'))).height,
      lessThanOrEqualTo(68),
    );
  });
}
