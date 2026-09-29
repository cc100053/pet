import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/balanced_text.dart';

// The test font draws every glyph as a 1em square, so a 10px font gives
// 10px per character and line widths are exact.
const _style = TextStyle(fontSize: 10, height: 1);

Future<Size> _pump(WidgetTester tester, Widget child, double width) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  return tester.getSize(find.byType(Text));
}

void main() {
  testWidgets('balances an orphaned last line into even lines', (tester) async {
    // 22 glyphs at 210px: greedy wrap is 21 + 1 (the lone "す。" case).
    final size = await _pump(
      tester,
      const BalancedText('1か月・毎月自動更新。いつでも解約できます。', style: _style),
      210,
    );
    expect(size.height, 20, reason: 'still two lines');
    expect(size.width, lessThanOrEqualTo(120), reason: 'about 11 + 11');
  });

  testWidgets('one-line text keeps its natural width', (tester) async {
    final size = await _pump(
      tester,
      const BalancedText('Shop', style: _style),
      210,
    );
    expect(size, const Size(40, 10));
  });

  testWidgets('never truncates text that fit within maxLines', (tester) async {
    await _pump(
      tester,
      const BalancedText(
        'aaaa aaaa aaaa aaaa aaaa',
        style: _style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      200,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('works inside intrinsic sizing (dialog content)', (tester) async {
    await _pump(
      tester,
      const IntrinsicWidth(
        child: BalancedText('いつでも解約できます。いつでも解約できます。', style: _style),
      ),
      150,
    );
    expect(tester.takeException(), isNull);
  });
}
