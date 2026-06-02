import 'package:flutter/widgets.dart';

/// Returns the global-coordinate [Rect] of the render box behind [key], or
/// `null` if the key is not currently laid out (no context, no `RenderBox`, or
/// unsized).
Rect? globalRectForKey(GlobalKey key) {
  final context = key.currentContext;
  final renderObject = context?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }
  final origin = renderObject.localToGlobal(Offset.zero);
  return origin & renderObject.size;
}
