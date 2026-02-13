import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/user_avatar.dart';
import 'home_responsive.dart';

class HomePolaroidMemoryFrame extends StatelessWidget {
  const HomePolaroidMemoryFrame({
    super.key,
    required this.imageUrl,
    required this.caption,
    required this.userLabel,
    required this.senderAvatar,
    required this.senderFallbackText,
    this.onTap,
    this.fixedMediaZone = false,
    this.mediaZoneFraction = 0.62,
    this.photoAspectRatio = 1.72,
    this.captionMaxLines = 2,
    this.avatarOverlapOffset = 10,
    this.captionTopInset = 36,
    this.captionReservedHeight = 80,
    this.noCaptionReservedHeight = 60,
    this.showAvatar = true,
    this.showShadow = true,
    this.emptyPhotoPlaceholder,
  });

  final String imageUrl;
  final String caption;
  final String userLabel;
  final String? senderAvatar;
  final String? senderFallbackText;
  final VoidCallback? onTap;
  final bool fixedMediaZone;
  final double mediaZoneFraction;
  final double photoAspectRatio;
  final int captionMaxLines;
  final double avatarOverlapOffset;
  final double captionTopInset;
  final double captionReservedHeight;
  final double noCaptionReservedHeight;
  final bool showAvatar;
  final bool showShadow;
  final Widget? emptyPhotoPlaceholder;

  @override
  Widget build(BuildContext context) {
    final showCaption = caption.trim().isNotEmpty;
    final showUserLabel = userLabel.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final scale = homeUiScale(screenWidth);
        final innerPadding = 14.0 * scale;
        final avatarSize = 46.0 * scale;
        final captionFontSize = 14.0 * scale;
        final labelFontSize = 11.0 * scale;
        final resolvedCaptionTopInset = captionTopInset * scale;
        final resolvedCaptionLines = captionMaxLines;
        final minPhotoHeight = 72.0 * scale;
        final photoWidth = width - (innerPadding * 2);
        final hasFiniteHeight = constraints.maxHeight.isFinite;
        double photoHeight;
        double bottomHeight;
        if (fixedMediaZone && hasFiniteHeight) {
          final contentHeight = constraints.maxHeight - (innerPadding * 2);
          final safeContentHeight = math.max(0.0, contentHeight).toDouble();
          final zoneHeight = (safeContentHeight * mediaZoneFraction).clamp(
            96.0 * scale,
            safeContentHeight,
          );
          final photoFromRatio = photoWidth / photoAspectRatio;
          photoHeight = math.min(photoFromRatio, zoneHeight).toDouble();
          final maxPhotoHeight = math.max(0.0, photoFromRatio);
          final safeMin = math.min(minPhotoHeight, maxPhotoHeight);
          photoHeight = photoHeight.clamp(safeMin, maxPhotoHeight).toDouble();
          bottomHeight = math
              .max(0.0, safeContentHeight - photoHeight)
              .toDouble();
        } else {
          var legacyPhotoSize = photoWidth;
          if (hasFiniteHeight) {
            final reservedBelowPhoto = showCaption
                ? captionReservedHeight
                : noCaptionReservedHeight;
            final available =
                constraints.maxHeight - (innerPadding * 2) - reservedBelowPhoto;
            if (available.isFinite && available > 0) {
              legacyPhotoSize = math.min(legacyPhotoSize, available).toDouble();
            }
          }
          photoHeight = legacyPhotoSize;
          bottomHeight = hasFiniteHeight
              ? math
                    .max(
                      0,
                      constraints.maxHeight -
                          (innerPadding * 2) -
                          legacyPhotoSize,
                    )
                    .toDouble()
              : (showCaption ? 80.0 : 60.0);
        }
        final bottomInset = 8.0 * scale;
        final double safeBottomHeight = math.max(0, bottomHeight - bottomInset);
        final showIdentityBand = showAvatar || showUserLabel;
        final identityLabelSectionHeight = showUserLabel
            ? ((showAvatar ? 6.0 * scale : 0.0) + (22.0 * scale))
            : 0.0;
        final identityBandPreferredHeight =
            (showAvatar ? avatarSize : 0.0) + identityLabelSectionHeight;
        final identityBandHeight = showIdentityBand
            ? math.min(safeBottomHeight, math.max(0.0, identityBandPreferredHeight))
            : 0.0;
        final captionBandHeight = math.max(0.0, safeBottomHeight - identityBandHeight);
        final captionTopSpacing = math.min(
          resolvedCaptionTopInset,
          captionBandHeight * 0.35,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: EdgeInsets.all(innerPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black87, width: 3),
                boxShadow: showShadow
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: photoHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black87, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isEmpty
                          ? (emptyPhotoPlaceholder ?? const _Placeholder())
                          : CachedNetworkImageView(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              portraitFriendlyCrop: true,
                            ),
                    ),
                  ),
                  if (showIdentityBand)
                    SizedBox(
                      height: identityBandHeight,
                      child: ClipRect(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showAvatar)
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black87,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.10),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: UserAvatar(
                                      avatar: senderAvatar,
                                      fallbackText: senderFallbackText,
                                      size: avatarSize - 10,
                                    ),
                                  ),
                                ),
                              if (showUserLabel) ...[
                                Gap(6 * scale),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: photoWidth),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.black87,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      userLabel,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: labelFontSize,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (showCaption)
                    SizedBox(
                      height: captionBandHeight,
                      child: ClipRect(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            8,
                            captionTopSpacing,
                            8,
                            4,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: captionBandHeight < 6
                                ? const SizedBox.shrink()
                                : Text(
                                    caption,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: captionFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: math.max(1, resolvedCaptionLines),
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                          ),
                        ),
                      ),
                    )
                  else if (safeBottomHeight > identityBandHeight)
                    SizedBox(height: safeBottomHeight - identityBandHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.photo,
        size: 34,
        color: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }
}
