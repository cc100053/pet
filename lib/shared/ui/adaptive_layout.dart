import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

const double kTabletLayoutBreakpoint = 700;

bool detectIosTabletDisplay() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return false;
  }
  final views = ui.PlatformDispatcher.instance.views;
  if (views.isEmpty) {
    return false;
  }
  final display = views.first.display;
  final dpr = display.devicePixelRatio;
  if (!dpr.isFinite || dpr <= 0) {
    return false;
  }
  final logicalWidth = display.size.width / dpr;
  final logicalHeight = display.size.height / dpr;
  final logicalShortestSide = math.min(logicalWidth, logicalHeight);
  return logicalShortestSide >= 600;
}

double effectiveAdaptiveWidth(
  double width, {
  required double tabletMaxWidth,
  double tabletBreakpoint = kTabletLayoutBreakpoint,
}) {
  if (!width.isFinite || width <= 0) {
    return tabletMaxWidth;
  }
  if (width >= tabletBreakpoint) {
    return tabletMaxWidth;
  }
  return width;
}

double adaptiveContentMaxWidth(
  double width, {
  required double tabletMaxWidth,
  double tabletBreakpoint = kTabletLayoutBreakpoint,
}) {
  if (!width.isFinite || width <= 0) {
    return tabletMaxWidth;
  }
  if (width >= tabletBreakpoint) {
    return tabletMaxWidth;
  }
  return double.infinity;
}
