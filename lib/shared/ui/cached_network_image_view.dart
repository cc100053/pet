import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'local_file_image.dart';

class CachedNetworkImageView extends StatelessWidget {
  const CachedNetworkImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = _resolveDimension(width, constraints.maxWidth);
        final resolvedHeight = _resolveDimension(height, constraints.maxHeight);
        final cacheWidth = _cacheDimension(context, resolvedWidth);
        final cacheHeight = _cacheDimension(context, resolvedHeight);

        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholderFadeInDuration: const Duration(milliseconds: 120),
          placeholder: (context, url) => placeholder ?? fallbackPlaceholder,
          errorWidget: (context, url, error) => errorWidget ?? fallbackError,
        );
      },
    );
  }

  double _resolveDimension(double? preferred, double fallback) {
    if (preferred != null && preferred.isFinite && preferred > 0) {
      return preferred;
    }
    return fallback;
  }

  int? _cacheDimension(BuildContext context, double value) {
    if (!value.isFinite || value <= 0) {
      return null;
    }
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final target = (value * dpr).round();
    return target > 0 ? target : null;
  }
}
