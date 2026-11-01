import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_fading_hint.dart';

void main() {
  Widget build({bool dismissed = false}) => MaterialApp(
    home: HomeFadingHint(dismissed: dismissed, child: const Text('hint')),
  );

  double opacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  testWidgets('fades out after visibleFor, then reports onHidden', (
    tester,
  ) async {
    var hidden = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeFadingHint(
          dismissed: false,
          onHidden: () => hidden++,
          child: const Text('hint'),
        ),
      ),
    );
    expect(opacity(tester), 1);
    await tester.pump(const Duration(seconds: 2));
    expect(opacity(tester), 1);
    await tester.pump(const Duration(seconds: 1));
    expect(opacity(tester), 0);
    expect(hidden, 0, reason: 'still fading');
    await tester.pumpAndSettle();
    expect(hidden, 1);
  });

  testWidgets('a dismiss hides it for good', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpWidget(build(dismissed: true));
    expect(opacity(tester), 0);
    await tester.pumpWidget(build());
    expect(opacity(tester), 0, reason: 'drag ended early; stays hidden');
    await tester.pump(const Duration(seconds: 3));
  });
}
