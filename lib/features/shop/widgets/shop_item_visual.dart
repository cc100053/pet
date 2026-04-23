import 'package:flutter/material.dart';

import '../models/shop_item.dart';

class ShopFurnitureVisual extends StatelessWidget {
  const ShopFurnitureVisual({
    super.key,
    required this.item,
    required this.size,
    this.fit = BoxFit.contain,
  });

  final ShopItem item;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.furnitureAssetPath?.trim();
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallbackEmoji(),
      );
    }
    return _fallbackEmoji();
  }

  Widget _fallbackEmoji() {
    return Text(
      item.emoji ?? '🪑',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size * 0.7, height: 1),
    );
  }
}

class ShopCatalogItemVisual extends StatelessWidget {
  const ShopCatalogItemVisual({
    super.key,
    required this.item,
    required this.size,
    this.fit = BoxFit.contain,
    this.fallbackEmoji,
  });

  final ShopItem item;
  final double size;
  final BoxFit fit;
  final String? fallbackEmoji;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.previewAssetPath?.trim();
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Text(
      fallbackEmoji ?? item.emoji ?? '🎁',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size * 0.7, height: 1),
    );
  }
}
