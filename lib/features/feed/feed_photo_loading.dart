import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/ui/balanced_text.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../pet/pet_animated_image.dart';
import '../pet/pet_animation_frames.dart';
import '../pet/pet_catalog.dart';

class FeedPhotoLoading extends StatelessWidget {
  const FeedPhotoLoading({super.key, this.petAsset});

  final String? petAsset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final source = petAsset ?? PetCatalog.byId(null).stayAsset;
    final pet = reduceMotion
        ? Image.asset(
            PetAnimationFrames.sequenceForAsset(source)?.frameAssets.first ??
                source,
            height: 100,
          )
        : JuicyFloat(
            yOffset: 3,
            child: PetAnimatedImage(sourceAsset: source, height: 100),
          );

    return Semantics(
      liveRegion: true,
      label: '${l10n.feedPhotoLoadingTitle} ${l10n.feedPhotoLoadingSubtitle}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: pet),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final dot = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.leafStrong,
                      shape: BoxShape.circle,
                    ),
                  );
                  return reduceMotion
                      ? dot
                      : dot
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .fade(
                              begin: 0.35,
                              end: 1,
                              delay: Duration(milliseconds: index * 160),
                              duration: const Duration(milliseconds: 500),
                            );
                }),
              ),
              const SizedBox(height: 12),
              BalancedText(
                l10n.feedPhotoLoadingTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              BalancedText(
                l10n.feedPhotoLoadingSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
