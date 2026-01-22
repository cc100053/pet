import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

class HomeLatestPhotoCard extends StatelessWidget {
  const HomeLatestPhotoCard({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final latestPhoto = imageUrl;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: latestPhoto == null || latestPhoto.isEmpty
              ? _PhotoPlaceholder(label: l10n.photoLabel)
              : CachedNetworkImage(
                  imageUrl: latestPhoto,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => const _PhotoLoading(),
                  errorWidget: (context, url, error) =>
                      _PhotoPlaceholder(label: l10n.photoLabel),
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
