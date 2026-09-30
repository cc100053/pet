import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/balanced_text.dart';

void main() {
  // Regression: the What's New toast wraps bullets in IntrinsicHeight, whose
  // height cap made the balance search collapse the text to ~2px wide.
  testWidgets('keeps readable width under IntrinsicHeight', (tester) async {
    const text =
        'Pumpkin Lantern, Candy Cauldron and Bat-Wing Armchair are now '
        'in the Shop.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: BalancedText(text))],
              ),
            ),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    expect(paragraph.size.width, greaterThan(150));
  });
}
