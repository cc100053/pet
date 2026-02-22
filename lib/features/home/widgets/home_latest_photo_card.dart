import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';

class HomeLatestPhotoCard extends StatelessWidget {
  const HomeLatestPhotoCard({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final urls = imageUrls.where((url) => url.isNotEmpty).take(3).toList();
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: urls.isEmpty
          ? _PhotoPlaceholder(label: l10n.photoLabel)
          : ClipRect(
              child: _PhotoBubbles(
                imageUrls: urls,
                fallbackLabel: l10n.photoLabel,
              ),
            ),
    );
  }
}

class _PhotoBubbles extends StatelessWidget {
  const _PhotoBubbles({required this.imageUrls, required this.fallbackLabel});

  final List<String> imageUrls;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final base = constraints.biggest.shortestSide;

        var gap = base * 0.06;
        final inset = base * 0.08;

        // Invisible boundary: scale the layout to fit both width and height.
        // This prevents RenderFlex overflows when bumping the bubble multipliers.
        var smallSize = base * 0.44;
        var bigSize = base * 0.48;

        final availableWidth = width - (inset * 2);
        final availableHeight = height - (inset * 2);

        final neededWidth = math.max((smallSize * 2) + gap, bigSize);
        final widthScale = neededWidth <= 0
            ? 1.0
            : math.min(1.0, availableWidth / neededWidth);
        smallSize *= widthScale;
        bigSize *= widthScale;
        gap *= widthScale;

        final neededHeight = smallSize + gap + bigSize;
        final heightScale = neededHeight <= 0
            ? 1.0
            : math.min(1.0, availableHeight / neededHeight);
        smallSize *= heightScale;
        bigSize *= heightScale;
        gap *= heightScale;

        final a = imageUrls.isNotEmpty ? imageUrls[0] : '';
        final b = imageUrls.length > 1 ? imageUrls[1] : '';
        final c = imageUrls.length > 2 ? imageUrls[2] : '';

        void open(int index) {
          if (imageUrls[index].isEmpty) return;
          final viewerItems = imageUrls
              .map((url) => PhotoViewerItem(imageUrl: url))
              .toList(growable: false);
          FullScreenPhotoViewer.open(
            context,
            items: viewerItems,
            initialIndex: index,
          );
        }

        return Stack(
          children: [
            Positioned(
              top: -base * 0.12,
              left: -base * 0.10,
              child: Container(
                width: base * 0.42,
                height: base * 0.42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -base * 0.16,
              right: -base * 0.12,
              child: Container(
                width: base * 0.48,
                height: base * 0.48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(inset),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: _BubbleDrift(
                            delay: 420.ms,
                            xOffset: 8,
                            yOffset: 10,
                            child: _PhotoBubble(
                              imageUrl: b,
                              size: smallSize,
                              fallbackLabel: fallbackLabel,
                              onTap: b.isEmpty ? null : () => open(1),
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                        Transform.translate(
                          offset: const Offset(0, 4),
                          child: _BubbleDrift(
                            delay: 900.ms,
                            xOffset: 7,
                            yOffset: 9,
                            child: _PhotoBubble(
                              imageUrl: c,
                              size: smallSize,
                              fallbackLabel: fallbackLabel,
                              onTap: c.isEmpty ? null : () => open(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gap),
                    Transform.translate(
                      offset: const Offset(0, 4),
                      child: _BubbleDrift(
                        delay: 120.ms,
                        xOffset: 9,
                        yOffset: 12,
                        child: _PhotoBubble(
                          imageUrl: a,
                          size: bigSize,
                          fallbackLabel: fallbackLabel,
                          onTap: a.isEmpty ? null : () => open(0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BubbleDrift extends StatelessWidget {
  const _BubbleDrift({
    required this.child,
    required this.delay,
    required this.xOffset,
    required this.yOffset,
  });

  final Widget child;
  final Duration delay;
  final double xOffset;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveX(
          begin: -xOffset,
          end: xOffset,
          curve: Curves.easeInOutSine,
          duration: 5.seconds,
          delay: delay,
        )
        .moveY(
          begin: -yOffset,
          end: yOffset,
          curve: Curves.easeInOutSine,
          duration: 4.seconds,
          delay: delay,
        );
  }
}

class _PhotoBubble extends StatelessWidget {
  const _PhotoBubble({
    required this.imageUrl,
    required this.size,
    required this.fallbackLabel,
    required this.onTap,
  });

  final String imageUrl;
  final double size;
  final String fallbackLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ClipOval(
              child: imageUrl.isEmpty
                  ? _BubblePlaceholder(label: fallbackLabel)
                  : DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xFFF8F4EF)),
                      child: CachedNetworkImageView(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        portraitFriendlyCrop: true,
                        width: size,
                        height: size,
                        placeholder: const _PhotoLoading(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoLoading extends StatelessWidget {
  const _PhotoLoading();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF8F4EF));
  }
}

class _BubblePlaceholder extends StatelessWidget {
  const _BubblePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F4EF),
      alignment: Alignment.center,
      child: Icon(
        Icons.photo,
        size: 24,
        color: Colors.black.withValues(alpha: 0.22),
        semanticLabel: label,
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F4EF),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
