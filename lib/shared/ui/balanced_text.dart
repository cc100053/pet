import 'package:budoux_dart/budoux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// [Text] that wraps into even lines instead of leaving an orphan (a lone
/// "す。" or "anytime." on the last line), like CSS `text-wrap: balance`.
///
/// Layout picks the narrowest width that keeps the same height (line count)
/// without truncating, then aligns that block per [textAlign]. Text that fits
/// on one line looks exactly like [Text]. Use it for short UI copy (titles,
/// subtitles, hints, dialog messages), not long paragraphs or chat bodies.
///
/// Japanese, Chinese and Korean lines only break between phrases or words
/// (see [PhraseBreaks]), never mid-word like "ア|イテム".
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final shown = PhraseBreaks.apply(
      data,
      Localizations.maybeLocaleOf(context),
    );
    return _Balance(
      alignment: switch (textAlign) {
        TextAlign.center => Alignment.center,
        TextAlign.right || TextAlign.end => AlignmentDirectional.centerEnd,
        _ => AlignmentDirectional.centerStart,
      },
      child: Text(
        shown,
        semanticsLabel: identical(shown, data) ? null : data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Glues CJK text into phrases so wrapping never splits a word.
///
/// Flutter may break between any two Japanese, Chinese or Hangul characters.
/// Japanese and Chinese are split into phrases with BudouX; Korean already
/// separates words with spaces (like CSS `word-break: keep-all`). Characters
/// inside a phrase are joined with invisible WORD JOINERs, so the only break
/// opportunities left are between phrases. A phrase wider than the line still
/// breaks as a last resort.
abstract final class PhraseBreaks {
  static const _wordJoiner = '\u2060';
  static final _cjk = RegExp(
    '[\u1100-\u11ff\u3040-\u30ff\u3130-\u318f\u3400-\u9fff'
    '\uac00-\ud7af\uf900-\ufaff]',
  );
  static final _models = <String, BudouX>{};

  /// Loads the phrase models; until then text wraps like plain [Text].
  static Future<void> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    await Future.wait([
      for (final name in const ['ja', 'zh-hans', 'zh-hant'])
        assets
            .loadString('packages/budoux_dart/models/$name.json')
            .then((json) => _models[name] = BudouX(json)),
    ]);
  }

  /// [text] with word joiners inside phrases, or [text] itself when the
  /// locale needs none.
  static String apply(String text, Locale? locale) {
    if (locale == null || !_cjk.hasMatch(text)) return text;
    final Iterable<String>? phrases = switch (locale.languageCode) {
      // Words are space-separated: glue everything but whitespace.
      'ko' => [text],
      'ja' => _models['ja']?.parse(text),
      'zh'
          when locale.scriptCode == 'Hant' ||
              const {'TW', 'HK', 'MO'}.contains(locale.countryCode) =>
        _models['zh-hant']?.parse(text),
      'zh' => _models['zh-hans']?.parse(text),
      _ => null,
    };
    if (phrases == null) return text;

    final breaks = <int>{};
    var end = 0;
    for (final phrase in phrases) {
      breaks.add(end += phrase.length);
    }
    final out = StringBuffer();
    var offset = 0;
    String? previous;
    // Iterate graphemes so a joiner never lands inside an emoji or a
    // surrogate pair that the phrase model split.
    for (final char in text.characters) {
      if (previous != null &&
          !breaks.contains(offset) &&
          previous.trim().isNotEmpty &&
          char.trim().isNotEmpty) {
        out.write(_wordJoiner);
      }
      out.write(char);
      offset += char.length;
      previous = char;
    }
    return out.toString();
  }
}

class _Balance extends SingleChildRenderObjectWidget {
  const _Balance({required this.alignment, super.child});

  final AlignmentGeometry alignment;

  @override
  _RenderBalance createRenderObject(BuildContext context) => _RenderBalance(
    alignment: alignment,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderBalance renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = Directionality.of(context);
  }
}

class _RenderBalance extends RenderShiftedBox {
  _RenderBalance({
    required AlignmentGeometry alignment,
    required TextDirection textDirection,
  }) : _alignment = alignment,
       _textDirection = textDirection,
       super(null);

  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderParagraph? _findParagraph(RenderObject node) {
    if (node is RenderParagraph) return node;
    RenderParagraph? found;
    node.visitChildren((child) => found ??= _findParagraph(child));
    return found;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    child?.getDryLayout(constraints.loosen()) ?? Size.zero,
  );

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final loose = constraints.loosen();
    // Measure with unbounded height: a height cap (e.g. from IntrinsicHeight)
    // clamps the child so narrower probes never look taller and the search
    // collapses the text to ~0 width.
    final probe = BoxConstraints(maxWidth: loose.maxWidth);
    child.layout(probe, parentUsesSize: true);
    final paragraph = _findParagraph(child);
    var width = loose.maxWidth;
    if (loose.hasBoundedWidth &&
        paragraph != null &&
        !paragraph.didExceedMaxLines) {
      final height = child.size.height;
      var lo = 0.0;
      var hi = loose.maxWidth;
      // ponytail: ~12 paragraph layouts per pass; fine for short copy.
      for (var i = 0; i < 12 && hi - lo > 1; i++) {
        final mid = (lo + hi) / 2;
        child.layout(probe.copyWith(maxWidth: mid), parentUsesSize: true);
        final keeps =
            child.size.height <= height + 0.5 && !paragraph.didExceedMaxLines;
        if (keeps) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      width = (hi.ceilToDouble() + 1).clamp(0.0, loose.maxWidth);
    }
    child.layout(loose.copyWith(maxWidth: width), parentUsesSize: true);
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = _alignment
        .resolve(_textDirection)
        .alongOffset(size - child.size as Offset);
  }
}
