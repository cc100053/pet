import 'package:flutter/material.dart';

const String _avatarAlignFragmentKey = 'avatar_align';
const String _avatarViewFragmentKey = 'avatar_view';
const String _avatarViewV2FragmentKey = 'avatar_view_v2';
const double _avatarMinScale = 0.5;
const double _avatarMaxScale = 4.0;

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
      if (x != null && y != null && scale != null) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0)),
          scale: scale.clamp(1.0, _avatarMaxScale),
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
      if (x != null && y != null && scale != null) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0)),
          scale: scale.clamp(_avatarMinScale, _avatarMaxScale),
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
      if (x != null && y != null) {
        return ParsedAvatarUrl(
          imageUrl: baseUrl,
          alignment: Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0)),
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

String buildAvatarUrlWithFraming(
  String avatarUrl, {
  required Alignment alignment,
  required double scale,
}) {
  final parsed = parseAvatarUrlWithAlignment(avatarUrl);
  final x = alignment.x.clamp(-1.0, 1.0);
  final y = alignment.y.clamp(-1.0, 1.0);
  final normalizedScale = scale.clamp(1.0, _avatarMaxScale);
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
