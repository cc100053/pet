import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
      child: Column(
        children: [
          statusBar,
          const Gap(12),
          photoGallery,
          const Gap(10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: petHomeCard,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, bottomInset + 8),
            child: bottomNavBar,
          ),
        ],
      ),
    );
  }
}
