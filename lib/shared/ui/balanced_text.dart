import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// [Text] that wraps into even lines instead of leaving an orphan (a lone
/// "す。" or "anytime." on the last line), like CSS `text-wrap: balance`.
///
/// Layout picks the narrowest width that keeps the same height (line count)
/// without truncating, then aligns that block per [textAlign]. Text that fits
/// on one line looks exactly like [Text]. Use it for short UI copy (titles,
/// subtitles, hints, dialog messages), not long paragraphs or chat bodies.
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
    return _Balance(
      alignment: switch (textAlign) {
        TextAlign.center => Alignment.center,
        TextAlign.right || TextAlign.end => AlignmentDirectional.centerEnd,
        _ => AlignmentDirectional.centerStart,
      },
      child: Text(
        data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
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
    child.layout(loose, parentUsesSize: true);
    final paragraph = _findParagraph(child);
    if (loose.hasBoundedWidth &&
        paragraph != null &&
        !paragraph.didExceedMaxLines) {
      final height = child.size.height;
      var lo = 0.0;
      var hi = loose.maxWidth;
      // ponytail: ~12 paragraph layouts per pass; fine for short copy.
      for (var i = 0; i < 12 && hi - lo > 1; i++) {
        final mid = (lo + hi) / 2;
        child.layout(loose.copyWith(maxWidth: mid), parentUsesSize: true);
        final keeps =
            child.size.height <= height + 0.5 && !paragraph.didExceedMaxLines;
        if (keeps) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      final width = (hi.ceilToDouble() + 1).clamp(0.0, loose.maxWidth);
      child.layout(loose.copyWith(maxWidth: width), parentUsesSize: true);
    }
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = _alignment
        .resolve(_textDirection)
        .alongOffset(size - child.size as Offset);
  }
}
