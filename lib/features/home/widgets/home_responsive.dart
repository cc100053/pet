import '../../../shared/ui/adaptive_layout.dart';
import '../../../shared/ui/app_ui_scale.dart';

enum HomeBreakpoint { compact, regular, expanded }

double homeUiScale(double screenWidth) {
  return appUiScale(screenWidth);
}

class HomeResponsiveSpec {
  const HomeResponsiveSpec._(this.breakpoint);

  final HomeBreakpoint breakpoint;

  static HomeResponsiveSpec fromWidth(
    double width, {
    bool? isIosTabletDisplay,
  }) {
    final tabletDisplay = isIosTabletDisplay ?? detectIosTabletDisplay();
    if (tabletDisplay) {
      return const HomeResponsiveSpec._(HomeBreakpoint.expanded);
    }
    final effectiveWidth = effectiveAdaptiveWidth(width, tabletMaxWidth: 540);
    if (effectiveWidth <= 360) {
      return const HomeResponsiveSpec._(HomeBreakpoint.compact);
    }
    if (effectiveWidth <= 430) {
      return const HomeResponsiveSpec._(HomeBreakpoint.regular);
    }
    return const HomeResponsiveSpec._(HomeBreakpoint.expanded);
  }

  bool get isCompact => breakpoint == HomeBreakpoint.compact;
  bool get isRegular => breakpoint == HomeBreakpoint.regular;
  bool get isExpanded => breakpoint == HomeBreakpoint.expanded;

  double pick({
    required double compact,
    required double regular,
    required double expanded,
  }) {
    switch (breakpoint) {
      case HomeBreakpoint.compact:
        return compact;
      case HomeBreakpoint.regular:
        return regular;
      case HomeBreakpoint.expanded:
        return expanded;
    }
  }

  int pickInt({
    required int compact,
    required int regular,
    required int expanded,
  }) {
    switch (breakpoint) {
      case HomeBreakpoint.compact:
        return compact;
      case HomeBreakpoint.regular:
        return regular;
      case HomeBreakpoint.expanded:
        return expanded;
    }
  }
}
