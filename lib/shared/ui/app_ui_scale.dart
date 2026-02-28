import 'package:flutter/foundation.dart';

import 'adaptive_layout.dart';

const double kUiScaleTabletWidth = 540;
String? _lastLoggedAppUiScaleKey;

double appUiScale(
  double screenWidth, {
  bool? isIosTabletDisplay,
  bool log = false,
  String logSource = 'default',
}) {
  if (!screenWidth.isFinite || screenWidth <= 0) {
    return 1.0;
  }
  final tabletDisplay = isIosTabletDisplay ?? detectIosTabletDisplay();
  late final double scale;
  double? effectiveWidth;
  if (tabletDisplay) {
    scale = 1.0;
  } else {
    effectiveWidth = effectiveAdaptiveWidth(
      screenWidth,
      tabletMaxWidth: kUiScaleTabletWidth,
    );
    if (effectiveWidth <= 360) {
      scale = 0.76;
    } else if (effectiveWidth <= 430) {
      scale = 0.9;
    } else {
      scale = 1.0;
    }
  }
  if (log && kDebugMode) {
    final key = [
      logSource,
      screenWidth.toStringAsFixed(1),
      (effectiveWidth ?? -1).toStringAsFixed(1),
      tabletDisplay,
      scale.toStringAsFixed(2),
    ].join('|');
    if (_lastLoggedAppUiScaleKey != key) {
      _lastLoggedAppUiScaleKey = key;
      debugPrint(
        '[UI_SCALE][$logSource] viewportWidth=${screenWidth.toStringAsFixed(1)} '
        'effectiveWidth=${effectiveWidth == null ? 'tablet-override' : effectiveWidth.toStringAsFixed(1)} '
        'iosTabletDisplay=$tabletDisplay '
        'scale=${scale.toStringAsFixed(2)}',
      );
    }
  }
  return scale;
}
