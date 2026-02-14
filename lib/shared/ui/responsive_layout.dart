import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Scales design-time values to the current constraint size.
class ResponsiveLayout {
  const ResponsiveLayout._({
    required this.scaleX,
    required this.scaleY,
    required this.uniformScale,
  });

  factory ResponsiveLayout.fromSize(
    Size currentSize, {
    Size designSize = const Size(390, 844),
  }) {
    final width = (currentSize.width.isFinite && currentSize.width > 0)
        ? currentSize.width
        : designSize.width;
    final height = (currentSize.height.isFinite && currentSize.height > 0)
        ? currentSize.height
        : designSize.height;
    final sx = width / designSize.width;
    final sy = height / designSize.height;
    return ResponsiveLayout._(
      scaleX: sx,
      scaleY: sy,
      uniformScale: math.min(sx, sy),
    );
  }

  final double scaleX;
  final double scaleY;
  final double uniformScale;

  double x(num value) => value.toDouble() * scaleX;
  double y(num value) => value.toDouble() * scaleY;
  double s(num value) => value.toDouble() * uniformScale;

  Offset offset(num dx, num dy) => Offset(x(dx), y(dy));
}
