import 'package:flutter/material.dart';

import 'cached_network_image_view.dart';
import '../utils/avatar_display_position.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatar,
    required this.fallbackText,
    this.size = 40,
  });

  static const int presetCount = 6;
  static const String presetPrefix = 'preset:';
  static const String defaultAvatarAssetPath = 'assets/app/PetTomo_appicon.png';

  final String? avatar;
  final String? fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = (avatar ?? '').trim();

    if (value.startsWith(presetPrefix)) {
      final presetId = int.tryParse(value.substring(presetPrefix.length));
      if (presetId != null) {
        return _PresetAvatar(presetId: presetId, size: size);
      }
    }

    if (value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'))) {
      final parsed = parseAvatarUrlWithAlignment(value);
      return ClipOval(
        child: CachedNetworkImageView(
          imageUrl: parsed.imageUrl,
          width: size,
          height: size,
          alignment: parsed.alignment,
          scale: parsed.scale,
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        defaultAvatarAssetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _FallbackLetterAvatar(size: size, fallbackText: fallbackText),
      ),
    );
  }

  static String _initialLetter(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _FallbackLetterAvatar extends StatelessWidget {
  const _FallbackLetterAvatar({required this.size, required this.fallbackText});

  final double size;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final letter = UserAvatar._initialLetter(fallbackText);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _PresetAvatar extends StatelessWidget {
  const _PresetAvatar({required this.presetId, required this.size});

  final int presetId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = presetId % UserAvatar.presetCount;
    final preset = _presets[resolved];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: preset.gradient,
        ),
      ),
      child: Icon(preset.icon, color: Colors.white, size: size * 0.52),
    );
  }
}

class _PresetDefinition {
  const _PresetDefinition({required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;
}

const List<_PresetDefinition> _presets = [
  _PresetDefinition(
    icon: Icons.pets_rounded,
    gradient: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
  ),
  _PresetDefinition(
    icon: Icons.star_rounded,
    gradient: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
  ),
  _PresetDefinition(
    icon: Icons.favorite_rounded,
    gradient: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
  ),
  _PresetDefinition(
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFFA1FFCE), Color(0xFFFAFFD1)],
  ),
  _PresetDefinition(
    icon: Icons.cloud_rounded,
    gradient: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  ),
  _PresetDefinition(
    icon: Icons.local_florist_rounded,
    gradient: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
  ),
];
