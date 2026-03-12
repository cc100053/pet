import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';
import 'package:pet/shared/ui/user_avatar.dart';

import '../../../shared/theme/app_theme.dart';
import '../home_gallery_feed_utils.dart';
import 'home_responsive.dart';

class PetPhotoGallery extends StatefulWidget {
  const PetPhotoGallery({
    super.key,
    required this.imageUrls,
    required this.captions,
    required this.sentAts,
    this.isRefreshing = false,
    this.jumpToLatestEventId = 0,
    required this.senderAvatars,
    required this.senderFallbackTexts,
    required this.onPlaceholderTap,
  });

  final List<String> imageUrls;
  final List<String?> captions;
  final List<DateTime?> sentAts;
  final bool isRefreshing;
  final int jumpToLatestEventId;
  final List<String?> senderAvatars;
  final List<String?> senderFallbackTexts;
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
      .take(kPetHomeGalleryMaxPhotos)
      .toList(growable: false);
  int get _slotCount => math.max(kPetHomeGalleryMinSlots, _urls.length);

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
    if (oldWidget.jumpToLatestEventId != widget.jumpToLatestEventId &&
        widget.jumpToLatestEventId > 0 &&
        _urls.isNotEmpty) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      _page = 0;
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

  Future<void> _openViewerAt({
    required int index,
    required List<String> urls,
  }) async {
    final items = List<PhotoViewerItem>.generate(
      urls.length,
      (i) => PhotoViewerItem(
        imageUrl: urls[i],
        caption: i < widget.captions.length ? widget.captions[i] : null,
        senderName: i < widget.senderFallbackTexts.length
            ? widget.senderFallbackTexts[i]
            : null,
        sentAt: i < widget.sentAts.length ? widget.sentAts[i] : null,
        localImagePath: urls[i].startsWith('http') ? null : urls[i],
      ),
    );
    final resultIndex = await FullScreenPhotoViewer.open(
      context,
      items: items,
      initialIndex: index,
    );
    if (!mounted || resultIndex == null || !_pageController.hasClients) {
      return;
    }
    final target = resultIndex.clamp(0, _slotCount - 1);
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) {
      return;
    }
    setState(() => _page = target.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final urls = _urls;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final responsive = HomeResponsiveSpec.fromWidth(layoutWidth);
        final scale = homeUiScale(layoutWidth);
        final tokens = _GalleryFrameTokens.fromScale(
          scale: scale,
          responsive: responsive,
        );
        final aspectRatio = responsive.pick(
          compact: 1.44,
          regular: 1.32,
          expanded: 1.08,
        );
        final cardMargin = responsive.pick(compact: 4, regular: 6, expanded: 8);
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            children: [
              PageView.builder(
                key: const ValueKey('pet-photo-gallery-page-view'),
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
                  final senderAvatar = index < widget.senderAvatars.length
                      ? widget.senderAvatars[index]
                      : null;
                  final senderFallbackText =
                      index < widget.senderFallbackTexts.length
                      ? widget.senderFallbackTexts[index]
                      : null;
                  return AnimatedContainer(
                    key: ValueKey('pet-photo-gallery-item-$index'),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.symmetric(
                      horizontal: cardMargin,
                      vertical: cardMargin,
                    ),
                    child: Opacity(
                      opacity: dim,
                      child: hasPhoto
                          ? _GalleryPhotoCard(
                              imageUrl: urls[index],
                              caption: caption,
                              senderAvatar: senderAvatar,
                              senderFallbackText: senderFallbackText,
                              scale: scale,
                              tokens: tokens,
                              onTap: () =>
                                  _openViewerAt(index: index, urls: urls),
                            )
                          : _PlaceholderFrame(
                              ctaText: l10n.feedPickPhotoHint,
                              scale: scale,
                              tokens: tokens,
                              onTap: widget.onPlaceholderTap,
                            ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 10 * scale,
                right: 14 * scale,
                child: IgnorePointer(
                  ignoring: !widget.isRefreshing,
                  child: AnimatedOpacity(
                    opacity: widget.isRefreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: SizedBox(
                        width: 16 * scale,
                        height: 16 * scale,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  const _GalleryPhotoCard({
    required this.imageUrl,
    required this.caption,
    required this.senderAvatar,
    required this.senderFallbackText,
    required this.scale,
    required this.tokens,
    required this.onTap,
  });

  final String imageUrl;
  final String caption;
  final String? senderAvatar;
  final String? senderFallbackText;
  final double scale;
  final _GalleryFrameTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GalleryPolaroidFrame(
      imageUrl: imageUrl,
      caption: caption.trim(),
      senderAvatar: senderAvatar,
      senderFallbackText: senderFallbackText,
      scale: scale,
      tokens: tokens,
      onTap: onTap,
    );
  }
}

class _PlaceholderFrame extends StatelessWidget {
  const _PlaceholderFrame({
    required this.ctaText,
    required this.scale,
    required this.tokens,
    required this.onTap,
  });

  final String ctaText;
  final double scale;
  final _GalleryFrameTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GalleryPolaroidFrame(
      imageUrl: '',
      caption: ctaText,
      senderAvatar: null,
      senderFallbackText: null,
      scale: scale,
      tokens: tokens,
      onTap: onTap,
      emptyPhotoPlaceholder: const _PlaceholderPhotoArea(),
    );
  }
}

class _GalleryPolaroidFrame extends StatelessWidget {
  const _GalleryPolaroidFrame({
    required this.imageUrl,
    required this.caption,
    required this.senderAvatar,
    required this.senderFallbackText,
    required this.scale,
    required this.tokens,
    required this.onTap,
    this.emptyPhotoPlaceholder,
  });

  final String imageUrl;
  final String caption;
  final String? senderAvatar;
  final String? senderFallbackText;
  final double scale;
  final _GalleryFrameTokens tokens;
  final VoidCallback onTap;
  final Widget? emptyPhotoPlaceholder;

  @override
  Widget build(BuildContext context) {
    final hasCaption = caption.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.all(tokens.innerPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black87, width: 3),
          ),
          child: CustomMultiChildLayout(
            delegate: _GalleryFrameLayoutDelegate(tokens: tokens),
            children: [
              LayoutId(
                id: _GalleryFrameSlot.photo,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isEmpty
                        ? (emptyPhotoPlaceholder ??
                              const _PlaceholderPhotoArea())
                        : CachedNetworkImageView(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            portraitFriendlyCrop: false,
                          ),
                  ),
                ),
              ),
              LayoutId(
                id: _GalleryFrameSlot.caption,
                child: hasCaption
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final captionHeight = constraints.maxHeight;
                          final safeCaptionHeight = math.max(
                            0.0,
                            captionHeight - tokens.captionBottomInset,
                          );
                          final effectiveTopInset = math.min(
                            tokens.captionTopInset,
                            safeCaptionHeight * 0.42,
                          );
                          return ClipRect(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                8 * scale,
                                effectiveTopInset,
                                8 * scale,
                                tokens.captionBottomInset,
                              ),
                              child: Align(
                                alignment: const Alignment(0, -0.15),
                                child: Text(
                                  caption.trim(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w600,
                                    height: 1.12,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              LayoutId(
                id: _GalleryFrameSlot.avatar,
                child: Center(
                  child: Container(
                    width: tokens.avatarSize,
                    height: tokens.avatarSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: UserAvatar(
                      avatar: senderAvatar,
                      fallbackText: senderFallbackText,
                      size: tokens.avatarSize - 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GalleryFrameSlot { photo, caption, avatar }

class _GalleryFrameTokens {
  const _GalleryFrameTokens({
    required this.innerPadding,
    required this.avatarSize,
    required this.photoRatio,
    required this.avatarOverlapRatio,
    required this.captionTopInset,
    required this.captionBottomInset,
    required this.minCaptionHeight,
  });

  final double innerPadding;
  final double avatarSize;
  final double photoRatio;
  final double avatarOverlapRatio;
  final double captionTopInset;
  final double captionBottomInset;
  final double minCaptionHeight;

  factory _GalleryFrameTokens.fromScale({
    required double scale,
    required HomeResponsiveSpec responsive,
  }) {
    return _GalleryFrameTokens(
      innerPadding:
          responsive.pick(compact: 11, regular: 12, expanded: 12) * scale,
      avatarSize:
          responsive.pick(compact: 46, regular: 50, expanded: 50) * scale,
      photoRatio: responsive.pick(compact: 0.80, regular: 0.82, expanded: 0.82),
      avatarOverlapRatio: responsive.pick(
        compact: 0.60,
        regular: 0.62,
        expanded: 0.62,
      ),
      captionTopInset:
          responsive.pick(compact: 16, regular: 24, expanded: 24) * scale,
      captionBottomInset:
          responsive.pick(compact: 7, regular: 8, expanded: 8) * scale,
      minCaptionHeight:
          responsive.pick(compact: 44, regular: 48, expanded: 48) * scale,
    );
  }
}

class _GalleryFrameLayoutDelegate extends MultiChildLayoutDelegate {
  _GalleryFrameLayoutDelegate({required this.tokens});

  final _GalleryFrameTokens tokens;

  @override
  void performLayout(Size size) {
    final maxPhotoHeight = math.max(0.0, size.height - tokens.minCaptionHeight);
    final photoHeight = math
        .min(size.height * tokens.photoRatio, maxPhotoHeight)
        .clamp(0.0, size.height);
    final captionHeight = math.max(0.0, size.height - photoHeight);

    if (hasChild(_GalleryFrameSlot.photo)) {
      layoutChild(
        _GalleryFrameSlot.photo,
        BoxConstraints.tight(Size(size.width, photoHeight)),
      );
      positionChild(_GalleryFrameSlot.photo, Offset.zero);
    }

    if (hasChild(_GalleryFrameSlot.caption)) {
      layoutChild(
        _GalleryFrameSlot.caption,
        BoxConstraints.tight(Size(size.width, captionHeight)),
      );
      positionChild(_GalleryFrameSlot.caption, Offset(0, photoHeight));
    }

    if (hasChild(_GalleryFrameSlot.avatar)) {
      final avatarSize = tokens.avatarSize;
      layoutChild(
        _GalleryFrameSlot.avatar,
        BoxConstraints.tight(Size(avatarSize, avatarSize)),
      );
      final dx = (size.width - avatarSize) / 2;
      final dy = photoHeight - (avatarSize * tokens.avatarOverlapRatio);
      positionChild(_GalleryFrameSlot.avatar, Offset(dx, dy));
    }
  }

  @override
  bool shouldRelayout(covariant _GalleryFrameLayoutDelegate oldDelegate) {
    return oldDelegate.tokens != tokens;
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
