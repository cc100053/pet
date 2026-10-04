import 'package:flutter/widgets.dart';

/// Inline emoji render this much larger than the surrounding text, like
/// Telegram, so they don't look shrunken next to full-width CJK glyphs.
const double chatInlineEmojiScale = 1.25;

/// One run of emoji: pictographs plus their skin-tone, variation-selector,
/// ZWJ, keycap and flag (regional indicator) parts.
final RegExp _emojiRunPattern = RegExp(
  // The analyzer can't parse \p{...} even with unicode: true; tests run it.
  // ignore: valid_regexps
  r'(?:\p{Extended_Pictographic}|[\u{1F1E6}-\u{1F1FF}\u{1F3FB}-\u{1F3FF}\u{FE0F}\u{200D}\u{20E3}])+',
  unicode: true,
);
final RegExp _whitespacePattern = RegExp(r'\s+');

bool chatTextHasEmoji(String text) => _emojiRunPattern.hasMatch(text);

/// Font size for a message made of only 1–3 emoji (Telegram-style "big
/// emoji"), or null when [text] isn't such a message.
double? chatEmojiOnlyFontSize(String text) {
  final compact = text.replaceAll(_whitespacePattern, '');
  if (compact.isEmpty) return null;
  final match = _emojiRunPattern.matchAsPrefix(compact);
  if (match == null || match.end != compact.length) return null;
  return switch (compact.characters.length) {
    1 => 44,
    2 => 38,
    3 => 32,
    _ => null,
  };
}

/// Returns [spans] with emoji enlarged: a lone span holding only 1–3 emoji
/// becomes big emoji; otherwise every emoji run inside each [TextSpan] is
/// scaled by [chatInlineEmojiScale]. Top-level span styles are kept, so
/// callers can still inspect them. Enlarged runs get a scaled-down line height
/// so lines don't grow.
List<InlineSpan> enlargeChatEmojiSpans(List<InlineSpan> spans) {
  if (spans case [TextSpan(:final text?, :final style?)]) {
    final bigSize = chatEmojiOnlyFontSize(text);
    if (bigSize != null) {
      return [
        TextSpan(
          text: text,
          style: style.copyWith(fontSize: bigSize, height: 1.15),
        ),
      ];
    }
  }
  return [
    for (final span in spans)
      if (span is TextSpan && span.text != null && span.style != null)
        _enlargeEmojiIn(span, chatInlineEmojiScale)
      else
        span,
  ];
}

InlineSpan _enlargeEmojiIn(TextSpan span, double scale) {
  final text = span.text!;
  final style = span.style!;
  final matches = _emojiRunPattern.allMatches(text).toList();
  if (matches.isEmpty) return span;

  final emojiStyle = style.copyWith(
    // 14 is Flutter's default when the theme leaves fontSize unset.
    fontSize: (style.fontSize ?? 14) * scale,
    height: style.height == null ? null : style.height! / scale,
  );
  final children = <InlineSpan>[];
  var index = 0;
  for (final match in matches) {
    if (match.start > index) {
      children.add(TextSpan(text: text.substring(index, match.start)));
    }
    children.add(TextSpan(text: match.group(0), style: emojiStyle));
    index = match.end;
  }
  if (index < text.length) {
    children.add(TextSpan(text: text.substring(index)));
  }
  return TextSpan(style: style, children: children);
}
