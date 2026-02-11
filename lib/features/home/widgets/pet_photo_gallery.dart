import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';

import 'home_polaroid_memory_frame.dart';

class PetPhotoGallery extends StatefulWidget {
  const PetPhotoGallery({
    super.key,
    required this.imageUrls,
    required this.captions,
    required this.senderAvatar,
    required this.senderFallbackText,
    required this.onPlaceholderTap,
  });

  final List<String> imageUrls;
  final List<String?> captions;
  final String? senderAvatar;
  final String? senderFallbackText;
  final VoidCallback onPlaceholderTap;

  @override
  State<PetPhotoGallery> createState() => _PetPhotoGalleryState();
}

class _PetPhotoGalleryState extends State<PetPhotoGallery> {
  static const double _viewportFraction = 0.8;
  late final PageController _pageController;
  double _page = 0;

  List<String> get _urls => widget.imageUrls
      .where((url) => url.isNotEmpty)
      .take(3)
      .toList(growable: false);
  int get _slotCount => math.max(3, _urls.length);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
    _pageController.addListener(_syncPage);
  }

  @override
  void didUpdateWidget(covariant PetPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pageController.hasClients) {
      return;
    }
    final current = (_pageController.page ?? _page).round();
    final clamped = current.clamp(0, _slotCount - 1);
    if (clamped != current) {
      _pageController.jumpToPage(clamped);
      _page = clamped.toDouble();
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncPage);
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage() {
    final value = _pageController.hasClients
        ? (_pageController.page ?? _page)
        : _page;
    if ((value - _page).abs() < 0.001) {
      return;
    }
    setState(() => _page = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final urls = _urls;
    return AspectRatio(
      aspectRatio: 6 / 5.7,
      child: PageView.builder(
        controller: _pageController,
        padEnds: true,
        itemCount: _slotCount,
        itemBuilder: (context, index) {
          final distance = ((_page - index).abs()).clamp(0.0, 1.0);
          final dim = 1 - (distance * 0.30);
          final hasPhoto = index < urls.length;
          final caption = index < widget.captions.length
              ? (widget.captions[index] ?? '').trim()
              : '';
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Opacity(
              opacity: dim,
              child: hasPhoto
                  ? _GalleryPhotoCard(
                      imageUrl: urls[index],
                      caption: caption,
                      senderAvatar: widget.senderAvatar,
                      senderFallbackText: widget.senderFallbackText,
                      onTap: () => FullScreenPhotoViewer.open(
                        context,
                        imageUrls: urls,
                        captions: List<String?>.generate(
                          urls.length,
                          (i) => i < widget.captions.length
                              ? widget.captions[i]
                              : null,
                        ),
                        initialIndex: index,
                      ),
                    )
                  : _PlaceholderFrame(
                      ctaText: l10n.feedPickPhotoHint,
                      onTap: widget.onPlaceholderTap,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  const _GalleryPhotoCard({
    required this.imageUrl,
    required this.caption,
    required this.senderAvatar,
    required this.senderFallbackText,
    required this.onTap,
  });

  final String imageUrl;
  final String caption;
  final String? senderAvatar;
  final String? senderFallbackText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomePolaroidMemoryFrame(
      imageUrl: imageUrl,
      caption: caption.trim(),
      userLabel: '',
      senderAvatar: senderAvatar,
      senderFallbackText: senderFallbackText,
      showShadow: false,
      fixedMediaZone: true,
      mediaZoneFraction: 0.91,
      photoAspectRatio: 0.95,
      avatarOverlapOffset: -8,
      captionTopInset: 18,
      captionMaxLines: 1,
      onTap: onTap,
    );
  }
}

class _PlaceholderFrame extends StatelessWidget {
  const _PlaceholderFrame({required this.ctaText, required this.onTap});

  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomePolaroidMemoryFrame(
      imageUrl: '',
      caption: ctaText,
      userLabel: '',
      senderAvatar: null,
      senderFallbackText: null,
      showShadow: false,
      fixedMediaZone: true,
      mediaZoneFraction: 0.88,
      photoAspectRatio: 0.95,
      showAvatar: false,
      captionTopInset: 12,
      captionMaxLines: 1,
      onTap: onTap,
      emptyPhotoPlaceholder: const _PlaceholderPhotoArea(),
    );
  }
}

class _PlaceholderPhotoArea extends StatelessWidget {
  const _PlaceholderPhotoArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F4EF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: 50,
              color: Colors.black.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
