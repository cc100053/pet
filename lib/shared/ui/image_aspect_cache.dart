import 'package:flutter/painting.dart';

/// App-wide cache for image aspect ratios, keyed by image URL.
///
/// Populated automatically by [CachedNetworkImageView] and consumed by
/// [FullScreenPhotoViewer] so images render at their correct size immediately,
/// avoiding layout jumps when the async dimension resolution completes.
class ImageAspectCache {
  ImageAspectCache._();

  static final ImageAspectCache instance = ImageAspectCache._();

  final Map<String, double> _cache = {};
  final Set<String> _resolving = {};

  /// Returns the cached aspect ratio for [url], or `null` if unknown.
  double? get(String url) => _cache[url];

  /// Stores an aspect ratio for [url].
  void set(String url, double ratio) {
    if (url.isNotEmpty && ratio.isFinite && ratio > 0) {
      _cache[url] = ratio;
    }
  }

  /// Resolves the aspect ratio for [url] from the network if not already
  /// cached or in-flight.  The returned future completes once the ratio is
  /// available (or fails silently on error).
  void ensureResolved(String url) {
    if (url.isEmpty || _cache.containsKey(url) || _resolving.contains(url)) {
      return;
    }
    _resolving.add(url);
    final provider = NetworkImage(url);
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (h > 0) {
          _cache[url] = w / h;
        }
        _resolving.remove(url);
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        _resolving.remove(url);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }
}
