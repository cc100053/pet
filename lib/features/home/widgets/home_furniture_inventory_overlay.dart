import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeFurnitureInventoryOverlay extends StatelessWidget {
  const HomeFurnitureInventoryOverlay({
    super.key,
    required this.visible,
    required this.panel,
  });

  final bool visible;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -1.1),
            duration: 220.ms,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: 160.ms,
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}
