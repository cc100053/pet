import 'package:flutter/material.dart';

List<Rect> resolveOnboardingFocusTargetRects({
  required BuildContext overlayContext,
  required Iterable<GlobalKey> targetKeys,
}) {
  final overlayBox = overlayContext.findRenderObject() as RenderBox?;
  if (overlayBox == null || !overlayBox.hasSize) {
    return const <Rect>[];
  }

  final rects = <Rect>[];
  for (final key in targetKeys) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      continue;
    }
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) {
      continue;
    }
    final topLeftGlobal = targetBox.localToGlobal(Offset.zero);
    final topLeftLocal = overlayBox.globalToLocal(topLeftGlobal);
    rects.add(topLeftLocal & targetBox.size);
  }
  return rects;
}
