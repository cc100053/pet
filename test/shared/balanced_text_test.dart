import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/balanced_text.dart';

// The test font draws every glyph as a 1em square, so a 10px font gives
// 10px per character and line widths are exact.
const _style = TextStyle(fontSize: 10, height: 1);

Future<Size> _pump(
  WidgetTester tester,
  Widget child,
  double width, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
  return tester.getSize(find.byType(Text));
}

/// The rendered text of each line, word joiners stripped.
List<String> _lines(WidgetTester tester) {
  final paragraph = tester.renderObject<RenderParagraph>(find.byType(RichText));
  final text = paragraph.text.toPlainText();
  final lines = <String>[];
  var start = 0;
  for (var y = 5.0; y < paragraph.size.height; y += 10) {
    final end = y + 10 < paragraph.size.height
        ? paragraph.getPositionForOffset(Offset(0, y + 10)).offset
        : text.length;
    lines.add(text.substring(start, end).replaceAll('\u2060', ''));
    start = end;
  }
  return lines;
}

void main() {
  setUpAll(() => PhraseBreaks.load());

  testWidgets('never splits a Japanese word across lines', (tester) async {
    // 13 glyphs at 90px: greedy wrap is "ショップに新アイテ" / "ム入荷！".
    await _pump(
      tester,
      const BalancedText('ショップに新アイテム入荷！', style: _style),
      90,
      locale: const Locale('ja'),
    );
    expect(_lines(tester), ['ショップに', '新アイテム入荷！']);
  });

  testWidgets('keeps Traditional Chinese phrases whole', (tester) async {
    await _pump(
      tester,
      const BalancedText('遊戲剛才似乎異常中斷，請關閉 App 後重新開啟再試一次。', style: _style),
      200,
      locale: const Locale('zh', 'TW'),
    );
    final lines = _lines(tester);
    expect(lines.join(), '遊戲剛才似乎異常中斷，請關閉 App 後重新開啟再試一次。');
    for (final word in ['遊戲', '異常', '中斷', '關閉', '重新', '開啟']) {
      expect(lines.any((line) => line.contains(word)), isTrue, reason: word);
    }
  });

  test('glues Korean words but keeps spaces breakable', () {
    expect(
      PhraseBreaks.apply('새 아이템', const Locale('ko')),
      '새 아\u2060이\u2060템',
    );
  });

  test('leaves non-CJK text and emoji graphemes intact', () {
    const english = 'New items in the shop!';
    expect(
      identical(PhraseBreaks.apply(english, const Locale('ja')), english),
      isTrue,
    );
    final withEmoji = PhraseBreaks.apply('新アイテム🎃入荷', const Locale('ja'));
    expect(withEmoji.replaceAll('\u2060', ''), '新アイテム🎃入荷');
    expect(withEmoji, contains('🎃'));
  });

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
