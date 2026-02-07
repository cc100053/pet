import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/ui/local_file_image.dart';

class PhotoFood extends StatelessWidget {
  const PhotoFood({
    super.key,
    required this.imageSource,
    required this.biteStage,
    this.size = const Size(82, 82),
  });

  final String imageSource;
  final int biteStage;
  final Size size;

  @override
  Widget build(BuildContext context) {
    if (biteStage >= 3) {
      return const SizedBox.shrink();
    }

    final removedFraction = switch (biteStage) {
      1 => 1 / 3,
      2 => 2 / 3,
      _ => 0.0,
    };

    final image = _buildImage();

    Widget framed = Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
    );

    if (removedFraction > 0) {
      framed = ClipPath(
        clipper: _PhotoFoodBiteClipper(removedFraction: removedFraction),
        child: framed,
      );
    }

    return framed;
  }

  Widget _buildImage() {
    final local = buildLocalFileImage(
      imageSource,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
    );
    if (local != null) {
      return local;
    }

    final uri = Uri.tryParse(imageSource);
    final isNetwork =
        uri != null &&
        (uri.scheme.eq('http') || uri.scheme.eq('https')) &&
        uri.host.isNotEmpty;

    if (isNetwork) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFE4C8),
            const Color(0xFFFFCF99).withValues(alpha: 0.92),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Color(0xFF855A33),
          size: 28,
        ),
      ),
    );
  }
}

class _PhotoFoodBiteClipper extends CustomClipper<Path> {
  _PhotoFoodBiteClipper({required this.removedFraction});

  final double removedFraction;

  @override
  Path getClip(Size size) {
    final visibleTop = (size.height * removedFraction).clamp(0.0, size.height);
    if (visibleTop <= 0.001) {
      return Path()..addRect(Offset.zero & size);
    }
    if (visibleTop >= size.height - 0.001) {
      return Path();
    }

    final path = Path()..moveTo(0, visibleTop);
    const teeth = 6;
    final step = size.width / teeth;
    for (var i = 0; i <= teeth; i++) {
      final x = (i * step).clamp(0.0, size.width);
      final y = visibleTop + (i.isEven ? 0 : min(8.0, size.height * 0.08));
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _PhotoFoodBiteClipper oldClipper) {
    return oldClipper.removedFraction != removedFraction;
  }
}

extension on String {
  bool eq(String other) => toLowerCase() == other;
}
