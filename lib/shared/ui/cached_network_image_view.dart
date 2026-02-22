import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/avatar_display_position.dart';
import 'image_aspect_cache.dart';
import 'local_file_image.dart';

class CachedNetworkImageView extends StatelessWidget {
  const CachedNetworkImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.scale = 1,
    this.avatarScaleMode = AvatarScaleMode.relativeZoom,
    this.portraitFriendlyCrop = false,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double scale;
  final AvatarScaleMode avatarScaleMode;
  final bool portraitFriendlyCrop;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final local = buildLocalFileImage(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
    );
    if (local != null) {
      return local;
    }

    final theme = Theme.of(context);
    final fallbackPlaceholder = Container(
      color: theme.colorScheme.surfaceContainerHighest,
    );
    final fallbackError = Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image,
        size: 18,
        color: theme.colorScheme.outline,
      ),
    );

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: Alignment.center,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholderFadeInDuration: const Duration(milliseconds: 120),
      imageBuilder: (context, imageProvider) => _PortraitAwareImage(
        imageProvider: imageProvider,
        imageUrl: imageUrl,
        fit: fit,
        alignment: alignment,
        scale: scale,
        avatarScaleMode: avatarScaleMode,
        portraitFriendlyCrop: portraitFriendlyCrop,
        width: width,
        height: height,
      ),
      placeholder: (context, url) => placeholder ?? fallbackPlaceholder,
      errorWidget: (context, url, error) => errorWidget ?? fallbackError,
    );
  }
}

class _PortraitAwareImage extends StatefulWidget {
  const _PortraitAwareImage({
    required this.imageProvider,
    required this.imageUrl,
    required this.fit,
    required this.alignment,
    required this.scale,
    required this.avatarScaleMode,
    required this.portraitFriendlyCrop,
    required this.width,
    required this.height,
  });

  final ImageProvider imageProvider;
  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double scale;
  final AvatarScaleMode avatarScaleMode;
  final bool portraitFriendlyCrop;
  final double? width;
  final double? height;

  @override
  State<_PortraitAwareImage> createState() => _PortraitAwareImageState();
}

class _PortraitAwareImageState extends State<_PortraitAwareImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _PortraitAwareImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  void _resolveImage() {
    _removeListener();
    final stream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    final listener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();
      if (height <= 0 || !mounted) {
        return;
      }
      final ratio = width / height;
      ImageAspectCache.instance.set(widget.imageUrl, ratio);
      setState(() {
        _aspectRatio = ratio;
      });
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final ratio =
        _aspectRatio ?? ImageAspectCache.instance.get(widget.imageUrl) ?? 1.0;
    if (widget.avatarScaleMode == AvatarScaleMode.relativeZoom &&
        widget.width != null &&
        widget.height != null) {
      final viewport = Size(widget.width!, widget.height!);
      final base = _baseImageSizeForContain(viewport, ratio);
      final circleRadius = viewport.shortestSide / 2;
      final minScale = _minScaleForCircle(base, circleRadius);
      final effectiveScale = (widget.scale.clamp(1.0, 4.0) * minScale);
      final maxPan = _maxPan(base, circleRadius, effectiveScale);
      final offset = Offset(
        widget.alignment.x.clamp(-1.0, 1.0) * maxPan.dx,
        widget.alignment.y.clamp(-1.0, 1.0) * maxPan.dy,
      );
      return Center(
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: effectiveScale,
            child: SizedBox(
              width: base.width,
              height: base.height,
              child: Image(
                image: widget.imageProvider,
                fit: BoxFit.fill,
                width: base.width,
                height: base.height,
              ),
            ),
          ),
        ),
      );
    }

    var effectiveFit = widget.fit;
    if (widget.portraitFriendlyCrop &&
        widget.fit == BoxFit.cover &&
        ratio < 1.0) {
      // Keeps frame fully filled with no inner padding, while reducing side crop.
      effectiveFit = BoxFit.fitWidth;
    }
    return Transform.scale(
      scale: widget.scale.clamp(0.5, 4.0),
      child: Image(
        image: widget.imageProvider,
        fit: effectiveFit,
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
      ),
    );
  }

  Size _baseImageSizeForContain(Size viewport, double ratio) {
    final viewportAspect = viewport.width / viewport.height;
    if (ratio > viewportAspect) {
      final width = viewport.width;
      final height = width / ratio;
      return Size(width, height);
    }
    final height = viewport.height;
    final width = height * ratio;
    return Size(width, height);
  }

  double _minScaleForCircle(Size base, double circleRadius) {
    final neededWidthScale = (circleRadius * 2) / base.width;
    final neededHeightScale = (circleRadius * 2) / base.height;
    return [
      neededWidthScale,
      neededHeightScale,
      0.5,
    ].reduce((a, b) => a > b ? a : b);
  }

  Offset _maxPan(Size base, double circleRadius, double scale) {
    final width = base.width * scale;
    final height = base.height * scale;
    final maxX = ((width - (circleRadius * 2)) / 2).clamp(0.0, double.infinity);
    final maxY = ((height - (circleRadius * 2)) / 2).clamp(
      0.0,
      double.infinity,
    );
    return Offset(maxX, maxY);
  }
}
