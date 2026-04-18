import 'package:flutter/material.dart';

const String _avatarAlignFragmentKey = 'avatar_align';
const String _avatarViewFragmentKey = 'avatar_view';
const String _avatarViewV2FragmentKey = 'avatar_view_v2';
const double _avatarMinScale = 0.5;
const double _avatarMaxScale = 4.0;
const double avatarRelativeMinScale = 1.0;
const double avatarRelativeMaxScale = _avatarMaxScale;

enum AvatarScaleMode { relativeZoom, legacyAbsolute }

class ParsedAvatarUrl {
  const ParsedAvatarUrl({
    required this.imageUrl,
    required this.alignment,
    required this.scale,
    required this.scaleMode,
  });

  final String imageUrl;
  final Alignment alignment;
  final double scale;
  final AvatarScaleMode scaleMode;
}

class AvatarFramingTransform {
  const AvatarFramingTransform({
    required this.viewport,
    required this.imageAspectRatio,
    required this.baseImageSize,
    required this.minFillScale,
    required this.relativeScale,
    required this.effectiveScale,
    required this.maxPan,
    required this.alignment,
    required this.offset,
  });

  final Size viewport;
  final double imageAspectRatio;
  final Size baseImageSize;
  final double minFillScale;
  final double relativeScale;
  final double effectiveScale;
  final Offset maxPan;
  final Alignment alignment;
  final Offset offset;

  static AvatarFramingTransform resolve({
    required Size viewport,
    required double imageAspectRatio,
    required Alignment alignment,
    required double scale,
  }) {
    final safeViewport = _safeViewport(viewport);
    final safeRatio = _safeAspectRatio(imageAspectRatio);
    final base = _baseImageSizeForContain(safeViewport, safeRatio);
    final circleRadius = safeViewport.shortestSide / 2;
    final minFillScale = _minScaleForCircle(base, circleRadius);
    final relativeScale = scale
        .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
        .toDouble();
    final effectiveScale = minFillScale * relativeScale;
    final maxPan = _maxPan(base, circleRadius, effectiveScale);
    final clampedAlignment = _clampAlignment(alignment, maxPan);
    final offset = Offset(
      clampedAlignment.x * maxPan.dx,
      clampedAlignment.y * maxPan.dy,
    );

    return AvatarFramingTransform(
      viewport: safeViewport,
      imageAspectRatio: safeRatio,
      baseImageSize: base,
      minFillScale: minFillScale,
      relativeScale: relativeScale,
      effectiveScale: effectiveScale,
      maxPan: maxPan,
      alignment: clampedAlignment,
      offset: offset,
    );
  }

  Alignment alignmentForOffset(Offset nextOffset) {
    final x = maxPan.dx <= 0 ? 0.0 : (nextOffset.dx / maxPan.dx);
    final y = maxPan.dy <= 0 ? 0.0 : (nextOffset.dy / maxPan.dy);
    return Alignment(_clampUnit(x), _clampUnit(y));
  }
}

ParsedAvatarUrl parseAvatarUrlWithAlignment(String avatarUrl) {
  final trimmed = avatarUrl.trim();
  if (trimmed.isEmpty) {
    return const ParsedAvatarUrl(
      imageUrl: '',
      alignment: Alignment.center,
      scale: 1,
      scaleMode: AvatarScaleMode.relativeZoom,
    );
  }

  final hashIndex = trimmed.indexOf('#');
  final baseUrl = hashIndex >= 0 ? trimmed.substring(0, hashIndex) : trimmed;
  final fragment = hashIndex >= 0 ? trimmed.substring(hashIndex + 1) : '';

  if (fragment.startsWith('$_avatarViewV2FragmentKey=')) {
    final encoded = fragment.substring('$_avatarViewV2FragmentKey='.length);
    final parts = encoded.split(',');
    if (parts.length == 3) {
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      final scale = double.tryParse(parts[2]);
      if (_allFinite(x, y) && scale != null && scale.isFinite) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(_clampUnit(x!), _clampUnit(y!)),
          scale: scale
              .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
              .toDouble(),
          scaleMode: AvatarScaleMode.relativeZoom,
        );
      }
    }
  }

  if (fragment.startsWith('$_avatarViewFragmentKey=')) {
    final encoded = fragment.substring('$_avatarViewFragmentKey='.length);
    final parts = encoded.split(',');
    if (parts.length == 3) {
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      final scale = double.tryParse(parts[2]);
      if (_allFinite(x, y) && scale != null && scale.isFinite) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(_clampUnit(x!), _clampUnit(y!)),
          scale: scale.clamp(_avatarMinScale, _avatarMaxScale).toDouble(),
          scaleMode: AvatarScaleMode.legacyAbsolute,
        );
      }
    }
  }

  if (fragment.startsWith('$_avatarAlignFragmentKey=')) {
    final encoded = fragment.substring('$_avatarAlignFragmentKey='.length);
    final parts = encoded.split(',');
    if (parts.length == 2) {
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      if (_allFinite(x, y)) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(_clampUnit(x!), _clampUnit(y!)),
          scale: 1,
          scaleMode: AvatarScaleMode.legacyAbsolute,
        );
      }
    }
  }

  return ParsedAvatarUrl(
    imageUrl: baseUrl,
    alignment: Alignment.center,
    scale: 1,
    scaleMode: AvatarScaleMode.relativeZoom,
  );
}

bool _allFinite(double? first, double? second) {
  if (first == null || second == null || !first.isFinite || !second.isFinite) {
    return false;
  }
  return true;
}

String buildAvatarUrlWithFraming(
  String avatarUrl, {
  required Alignment alignment,
  required double scale,
}) {
  final parsed = parseAvatarUrlWithAlignment(avatarUrl);
  final x = _clampUnit(alignment.x);
  final y = _clampUnit(alignment.y);
  final normalizedScale = scale
      .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
      .toDouble();
  if (x.abs() < 0.001 &&
      y.abs() < 0.001 &&
      (normalizedScale - 1).abs() < 0.001) {
    return parsed.imageUrl;
  }
  final xText = x.toStringAsFixed(3);
  final yText = y.toStringAsFixed(3);
  final scaleText = normalizedScale.toStringAsFixed(3);
  return '${parsed.imageUrl}#$_avatarViewV2FragmentKey=$xText,$yText,$scaleText';
}

Size _safeViewport(Size viewport) {
  final width = viewport.width.isFinite && viewport.width > 0
      ? viewport.width
      : 1.0;
  final height = viewport.height.isFinite && viewport.height > 0
      ? viewport.height
      : 1.0;
  return Size(width, height);
}

double _safeAspectRatio(double ratio) {
  if (!ratio.isFinite || ratio <= 0) {
    return 1.0;
  }
  return ratio;
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
  return <double>[
    neededWidthScale,
    neededHeightScale,
    0.5,
  ].reduce((a, b) => a > b ? a : b);
}

Offset _maxPan(Size base, double circleRadius, double scale) {
  final width = base.width * scale;
  final height = base.height * scale;
  final maxX = ((width - (circleRadius * 2)) / 2)
      .clamp(0.0, double.infinity)
      .toDouble();
  final maxY = ((height - (circleRadius * 2)) / 2)
      .clamp(0.0, double.infinity)
      .toDouble();
  return Offset(maxX, maxY);
}

Alignment _clampAlignment(Alignment alignment, Offset maxPan) {
  return Alignment(
    maxPan.dx <= 0 ? 0.0 : _clampUnit(alignment.x),
    maxPan.dy <= 0 ? 0.0 : _clampUnit(alignment.y),
  );
}

double _clampUnit(double value) {
  return value.clamp(-1.0, 1.0).toDouble();
}
