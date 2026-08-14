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
    this.bottomOverlay,
  });

  final double bottomInset;
  final Widget statusBar;
  final Widget photoGallery;
  final Widget petHomeCard;
  final Widget bottomNavBar;
  final Widget? bottomOverlay;

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
          final minGalleryHeight = responsive.pick(
            compact: 210,
            regular: 230,
            expanded: 250,
          );
          final maxGalleryHeight = responsive.pick(
            compact: 330,
            regular: 400,
            expanded: 420,
          );
          final gallerySplitRatio = responsive.pick(
            compact: 0.6,
            regular: 0.58,
            expanded: 0.6,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  statusBar,
                  Gap(topGap * uiScale),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final splitGap = middleGap * uiScale;
                        final splitAvailableHeight =
                            bodyConstraints.maxHeight - splitGap;
                        final safeSplitHeight = splitAvailableHeight.isFinite
                            ? splitAvailableHeight.clamp(0.0, double.infinity)
                            : 0.0;
                        final galleryHeight =
                            (safeSplitHeight * gallerySplitRatio).clamp(
                              minGalleryHeight * uiScale,
                              maxGalleryHeight * uiScale,
                            );
                        final petAreaHeight = (safeSplitHeight - galleryHeight)
                            .clamp(0.0, double.infinity);
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: galleryHeight,
                              child: photoGallery,
                            ),
                            Gap(splitGap),
                            SizedBox(
                              height: petAreaHeight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding * uiScale,
                                ),
                                child: petHomeCard,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // When a placed piece is selected the size controls take over
                  // the bottom nav bar's slot (and hide it) so they never cover
                  // the pet's play area.
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      navTopGap * uiScale,
                      0,
                      bottomInset + 8,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: bottomOverlay != null
                          ? KeyedSubtree(
                              key: const ValueKey('home-furniture-scale'),
                              child: bottomOverlay!,
                            )
                          : KeyedSubtree(
                              key: const ValueKey('home-bottom-nav'),
                              child: bottomNavBar,
                            ),
                    ),
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
