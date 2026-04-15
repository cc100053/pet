import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_furniture_math.dart';
import 'package:pet/features/home/widgets/home_furniture_scale_controls.dart';

void main() {
  Widget buildHarness({
    required double scale,
    required ValueNotifier<double> scaleNotifier,
    ValueNotifier<double?>? endValueNotifier,
    VoidCallback? onFlip,
  }) {
    scaleNotifier.value = scale;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: scaleNotifier,
            builder: (context, currentScale, _) {
              final canDecrease = currentScale > roomFurnitureMinScale + 0.001;
              final canIncrease = currentScale < roomFurnitureMaxScale - 0.001;
              return HomeFurnitureScaleControls(
                label: 'Size',
                scale: currentScale,
                minScale: roomFurnitureMinScale,
                maxScale: roomFurnitureMaxScale,
                step: roomFurnitureScaleStep,
                decreaseLabel: 'Smaller',
                increaseLabel: 'Larger',
                flipLabel: 'Flip horizontally',
                onDecrease: canDecrease
                    ? () {
                        scaleNotifier.value = nudgeRoomFurnitureScale(
                          currentScale,
                          stepDelta: -1,
                        );
                      }
                    : null,
                onIncrease: canIncrease
                    ? () {
                        scaleNotifier.value = nudgeRoomFurnitureScale(
                          currentScale,
                          stepDelta: 1,
                        );
                      }
                    : null,
                onFlip: onFlip,
                onChanged: (value) {
                  scaleNotifier.value = roundRoomFurnitureScaleToStep(value);
                },
                onChangeEnd: endValueNotifier == null
                    ? null
                    : (value) {
                        endValueNotifier.value = roundRoomFurnitureScaleToStep(
                          value,
                        );
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('disables scale buttons at the configured bounds', (
    tester,
  ) async {
    final scaleNotifier = ValueNotifier<double>(roomFurnitureMinScale);

    await tester.pumpWidget(
      buildHarness(scale: roomFurnitureMinScale, scaleNotifier: scaleNotifier),
    );

    final decreaseButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('home_furniture_scale_decrease')),
        matching: find.byType(FilledButton),
      ),
    );
    final increaseButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('home_furniture_scale_increase')),
        matching: find.byType(FilledButton),
      ),
    );

    expect(decreaseButton.onPressed, isNull);
    expect(increaseButton.onPressed, isNotNull);

    scaleNotifier.value = roomFurnitureMaxScale;
    await tester.pump();

    final maxDecreaseButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('home_furniture_scale_decrease')),
        matching: find.byType(FilledButton),
      ),
    );
    final maxIncreaseButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('home_furniture_scale_increase')),
        matching: find.byType(FilledButton),
      ),
    );

    expect(maxDecreaseButton.onPressed, isNotNull);
    expect(maxIncreaseButton.onPressed, isNull);
  });

  testWidgets('step buttons adjust scale by one configured step', (
    tester,
  ) async {
    final scaleNotifier = ValueNotifier<double>(1.0);

    await tester.pumpWidget(
      buildHarness(scale: 1.0, scaleNotifier: scaleNotifier),
    );

    await tester.tap(find.byKey(const Key('home_furniture_scale_increase')));
    await tester.pump();
    expect(scaleNotifier.value, closeTo(1.1, 0.001));
    expect(find.text('110%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_furniture_scale_decrease')));
    await tester.pump();
    expect(scaleNotifier.value, closeTo(1.0, 0.001));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('slider updates the visible scale and reports the final value', (
    tester,
  ) async {
    final scaleNotifier = ValueNotifier<double>(1.0);
    final endValueNotifier = ValueNotifier<double?>(null);

    await tester.pumpWidget(
      buildHarness(
        scale: 1.0,
        scaleNotifier: scaleNotifier,
        endValueNotifier: endValueNotifier,
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const Key('home_furniture_scale_slider')),
    );
    slider.onChanged?.call(1.27);
    await tester.pump();

    expect(scaleNotifier.value, closeTo(1.3, 0.001));
    expect(find.text('130%'), findsOneWidget);

    slider.onChangeEnd?.call(1.27);
    expect(endValueNotifier.value, closeTo(1.3, 0.001));
  });

  testWidgets('flip button fires callback with tooltip label', (tester) async {
    final scaleNotifier = ValueNotifier<double>(1.0);
    var flipCount = 0;

    await tester.pumpWidget(
      buildHarness(
        scale: 1.0,
        scaleNotifier: scaleNotifier,
        onFlip: () => flipCount++,
      ),
    );

    expect(find.byTooltip('Flip horizontally'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_furniture_flip')));
    await tester.pump();

    expect(flipCount, 1);
  });
}
