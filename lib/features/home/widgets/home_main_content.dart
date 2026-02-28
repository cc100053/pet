import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../shared/ui/adaptive_layout.dart';
import 'home_responsive.dart';

class HomeMainContent extends StatelessWidget {
  const HomeMainContent({
    super.key,
    required this.bottomInset,
    required this.statusBar,
    required this.photoGallery,
    required this.petHomeCard,
    required this.bottomNavBar,
  });

  final double bottomInset;
  final Widget statusBar;
  final Widget photoGallery;
  final Widget petHomeCard;
  final Widget bottomNavBar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = adaptiveContentMaxWidth(
            constraints.maxWidth,
            tabletMaxWidth: 540,
          );
          final responsive = HomeResponsiveSpec.fromWidth(constraints.maxWidth);
          final uiScale = homeUiScale(constraints.maxWidth);
          final topGap = responsive.pick(compact: 4, regular: 6, expanded: 12);
          final middleGap = responsive.pick(
            compact: 2,
            regular: 4,
            expanded: 10,
          );
          final horizontalPadding = responsive.pick(
            compact: 14,
            regular: 16,
            expanded: 20,
          );
          final navTopGap = responsive.pick(
            compact: 4,
            regular: 6,
            expanded: 8,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  statusBar,
                  Gap(topGap * uiScale),
                  photoGallery,
                  Gap(middleGap * uiScale),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding * uiScale,
                      ),
                      child: petHomeCard,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      navTopGap * uiScale,
                      0,
                      bottomInset + 8,
                    ),
                    child: bottomNavBar,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
