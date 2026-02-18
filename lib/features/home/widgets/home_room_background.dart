import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/ui/juice_wrappers.dart';
import '../../../shared/ui/responsive_layout.dart';

class HomeRoomBackground extends StatelessWidget {
  const HomeRoomBackground({super.key, required this.decoration});

  final Decoration decoration;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final responsiveLayout = ResponsiveLayout.fromSize(screenSize);

    return Stack(
      children: [
        Positioned.fill(child: DecoratedBox(decoration: decoration)),
        Positioned(
          bottom: responsiveLayout.y(150),
          left: responsiveLayout.x(-20),
          child: JuicyFloat(
            yOffset: responsiveLayout.s(20),
            delay: 500.ms,
            child: Container(
              width: responsiveLayout.s(150),
              height: responsiveLayout.s(150),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: responsiveLayout.y(300),
          right: responsiveLayout.x(-30),
          child: JuicyFloat(
            yOffset: responsiveLayout.s(30),
            delay: 1000.ms,
            child: Container(
              width: responsiveLayout.s(120),
              height: responsiveLayout.s(120),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
