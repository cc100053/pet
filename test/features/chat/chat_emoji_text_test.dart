import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_emoji_text.dart';

void main() {
  test('emoji-only messages of 1-3 emoji get big sizes', () {
    expect(chatEmojiOnlyFontSize('😂'), 44);
    expect(chatEmojiOnlyFontSize('👍🏻 🇯🇵'), 38);
    expect(chatEmojiOnlyFontSize('👨‍👩‍👧❤️🎉'), 32);
    expect(chatEmojiOnlyFontSize('😂😂😂😂'), isNull);
    expect(chatEmojiOnlyFontSize('hi 😂'), isNull);
    expect(chatEmojiOnlyFontSize('123'), isNull);
  });

  test('inline emoji runs are enlarged, text keeps base style', () {
    const base = TextStyle(fontSize: 16, height: 1.36);
    final spans = enlargeChatEmojiSpans([
      const TextSpan(text: '生日快樂🎊🎉 !', style: base),
    ]);
    final root = spans.single as TextSpan;
    expect(root.style, base);
    final children = root.children!.cast<TextSpan>();
    expect(children.map((s) => s.text), ['生日快樂', '🎊🎉', ' !']);
    expect(children[1].style!.fontSize, 16 * chatInlineEmojiScale);
    expect(children[0].style, isNull);
  });

  test('text without emoji is returned unchanged', () {
    const span = TextSpan(text: 'hello', style: TextStyle(fontSize: 16));
    expect(identical(enlargeChatEmojiSpans([span]).single, span), isTrue);
    expect(chatTextHasEmoji('hello'), isFalse);
  });
}
