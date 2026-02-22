import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pet/l10n/app_localizations.dart';

import 'cached_network_image_view.dart';
import 'image_aspect_cache.dart';
import 'photo_viewer_item.dart';
import 'status_bar_style.dart';

/// iPhone-style full-screen photo viewer with:
/// - Double-tap to zoom
/// - Pinch/drag to zoom and pan
/// - Swipe down to dismiss
/// - Swipe left/right between photos
class FullScreenPhotoViewer extends StatefulWidget {
  const FullScreenPhotoViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.showIndicator = true,
  });

  final List<PhotoViewerItem> items;
  final int initialIndex;
  final bool showIndicator;

  /// Opens the photo viewer using a fade transition.
  static Future<int?> open(
    BuildContext context, {
    required List<PhotoViewerItem> items,
    int initialIndex = 0,
    bool showIndicator = true,
  }) {
    if (items.isEmpty) return Future<int?>.value(null);
    return Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenPhotoViewer(
              items: items,
              initialIndex: initialIndex,
              showIndicator: showIndicator,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // For swipe-down-to-dismiss
  double _dragOffset = 0;
  double _dragOpacity = 1.0;

  // For double-tap zoom
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  final Map<int, double> _aspectRatios = {};
  final Set<int> _resolvingAspect = {};
  bool _savingToGallery = false;
  bool _showDownloadedIcon = false;
  Timer? _downloadedIconTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _zoomAnimController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (_zoomAnimation != null) {
            _transformController.value = _zoomAnimation!.value;
          }
        });
  }

  @override
  void dispose() {
    _downloadedIconTimer?.cancel();
    _pageController.dispose();
    _zoomAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _closeWithCurrentIndex() {
    Navigator.of(context).pop(_currentIndex);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 end;
    if (currentScale > 1.1) {
      // Zoom out
      end = Matrix4.identity();
    } else {
      // Zoom in to 2.5x at tap position
      const targetScale = 2.5;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      end = Matrix4.identity()
        ..setTranslationRaw(x, y, 0)
        ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1));
    }

    _zoomAnimation = Matrix4Tween(begin: _transformController.value, end: end)
        .animate(
          CurvedAnimation(
            parent: _zoomAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _zoomAnimController.forward(from: 0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Only allow swipe-down when not zoomed
    if (_transformController.value.getMaxScaleOnAxis() > 1.05) return;

    setState(() {
      _dragOffset += details.delta.dy;
      _dragOpacity = (1 - (_dragOffset.abs() / 300)).clamp(0.4, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      _closeWithCurrentIndex();
    } else {
      setState(() {
        _dragOffset = 0;
        _dragOpacity = 1.0;
      });
    }
  }

  void _onPageChanged(int index) {
    // Reset zoom when switching pages
    _transformController.value = Matrix4.identity();
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _saveCurrentImageToGallery() async {
    if (_savingToGallery) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingToGallery = true);

    try {
      final bytes = await _resolveCurrentImageBytes();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('image_bytes_unavailable');
      }

      final name = 'pettomo_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: name,
      );
      final saved = _isGallerySaveSuccess(result);
      if (!mounted) {
        return;
      }
      if (saved) {
        _downloadedIconTimer?.cancel();
        setState(() => _showDownloadedIcon = true);
        _downloadedIconTimer = Timer(const Duration(seconds: 1), () {
          if (!mounted) {
            return;
          }
          setState(() => _showDownloadedIcon = false);
        });
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved ? l10n.photoViewerSavedToGallery : l10n.photoViewerSaveFailed,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.photoViewerSaveFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _savingToGallery = false);
      }
    }
  }

  Future<Uint8List?> _resolveCurrentImageBytes() async {
    final item = widget.items[_currentIndex];
    final localPath = item.localImagePath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      return File(localPath).readAsBytes();
    }

    final url = item.imageUrl.trim();
    if (url.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      if (chunks.isEmpty) {
        return null;
      }
      return Uint8List.fromList(chunks);
    } finally {
      client.close(force: true);
    }
  }

  bool _isGallerySaveSuccess(dynamic result) {
    if (result is bool) {
      return result;
    }
    if (result is Map) {
      final dynamic isSuccess = result['isSuccess'];
      if (isSuccess is bool) {
        return isSuccess;
      }
      final dynamic filePath = result['filePath'];
      if (filePath is String && filePath.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Widget _buildTopCircleIconButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
    Widget? iconChild,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: iconChild ?? Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  void _ensureAspectRatio(int index) {
    final item = widget.items[index];
    final url = item.imageUrl.trim();
    final localPath = item.localImagePath;
    final cacheKey = url.isNotEmpty
        ? url
        : (localPath == null || localPath.isEmpty ? '' : 'local:$localPath');

    // Use shared cache first – avoids async setState jump.
    final cached = cacheKey.isEmpty
        ? null
        : ImageAspectCache.instance.get(cacheKey);
    if (cached != null) {
      _aspectRatios[index] = cached;
      return;
    }

    if (_aspectRatios.containsKey(index) || _resolvingAspect.contains(index)) {
      return;
    }
    final ImageProvider provider;
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      provider = FileImage(File(localPath));
    } else if (url.isNotEmpty) {
      provider = NetworkImage(url);
    } else {
      return;
    }
    _resolvingAspect.add(index);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final ratio = info.image.width / info.image.height;
        final safeRatio = ratio.isFinite && ratio > 0 ? ratio : 1.0;
        if (cacheKey.isNotEmpty) {
          ImageAspectCache.instance.set(cacheKey, safeRatio);
        }
        if (mounted) {
          setState(() {
            _aspectRatios[index] = safeRatio;
          });
        } else {
          _aspectRatios[index] = safeRatio;
        }
        _resolvingAspect.remove(index);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        _resolvingAspect.remove(index);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  String? _captionFor(int index) {
    final caption = widget.items[index].caption?.trim();
    if (caption == null || caption.isEmpty) {
      return null;
    }
    return caption;
  }

  Widget _buildImage(int index) {
    final item = widget.items[index];
    final url = item.imageUrl.trim();
    final localPath = item.localImagePath;

    Widget imageWidget;
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      imageWidget = Image.file(File(localPath), fit: BoxFit.contain);
    } else if (url.isNotEmpty) {
      imageWidget = CachedNetworkImageView(imageUrl: url, fit: BoxFit.contain);
    } else {
      imageWidget = const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
      );
    }

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 5.0,
        panEnabled: true,
        scaleEnabled: true,
        child: Center(child: imageWidget),
      ),
    );
  }

  Widget _buildImagePage(int index, BoxConstraints constraints) {
    final caption = _captionFor(index);
    final senderName = _senderNameFor(index);
    final sentTime = _sentTimeFor(index);
    final hasMeta = senderName != null || sentTime != null;
    _ensureAspectRatio(index);
    final aspectRatio = _aspectRatios[index] ?? (4 / 5);
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : MediaQuery.of(context).size.height;
    final reserved = (caption == null ? 0.0 : 56.0) + (hasMeta ? 52.0 : 0.0);
    final maxImageHeight = (maxHeight - reserved - 24).clamp(0.0, maxHeight);
    var imageWidth = maxWidth;
    var imageHeight = imageWidth / aspectRatio;
    if (imageHeight > maxImageHeight) {
      imageHeight = maxImageHeight;
      imageWidth = imageHeight * aspectRatio;
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMeta) ...[
            _PhotoMetaCard(
              senderName: senderName,
              sentTimeText: sentTime == null ? null : _formatSentTime(sentTime),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: _buildImage(index),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            _CaptionCard(text: caption),
          ],
        ],
      ),
    );
  }

  String? _senderNameFor(int index) {
    final sender = widget.items[index].senderName?.trim();
    if (sender == null || sender.isEmpty) {
      return null;
    }
    return sender;
  }

  DateTime? _sentTimeFor(int index) {
    return widget.items[index].sentAt;
  }

  String _formatSentTime(DateTime date) {
    final localDate = date.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localDate),
    );
    if (DateUtils.isSameDay(localDate, DateTime.now())) {
      return timeText;
    }
    final dateText = localizations.formatShortDate(localDate);
    return '$dateText $timeText';
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.items.length;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.dark,
      child: PopScope<int>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _closeWithCurrentIndex();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _dragOpacity,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Image viewer
                          imageCount == 1
                              ? _buildImagePage(0, constraints)
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: imageCount,
                                  onPageChanged: _onPageChanged,
                                  physics:
                                      _transformController.value
                                              .getMaxScaleOnAxis() >
                                          1.05
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  itemBuilder: (_, index) =>
                                      _buildImagePage(index, constraints),
                                ),

                          // Download button
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _buildTopCircleIconButton(
                              onPressed:
                                  (_savingToGallery || _showDownloadedIcon)
                                  ? null
                                  : _saveCurrentImageToGallery,
                              icon: Icons.download_rounded,
                              tooltip: l10n.photoViewerDownloadTooltip,
                              iconChild: _savingToGallery
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : _showDownloadedIcon
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          ),

                          // Close button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildTopCircleIconButton(
                              onPressed: _closeWithCurrentIndex,
                              icon: Icons.close,
                              tooltip: l10n.commonClose,
                            ),
                          ),

                          // Page indicator (only if multiple images)
                          if (widget.showIndicator && imageCount > 1)
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(imageCount, (i) {
                                  final isActive = i == _currentIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: isActive ? 10 : 6,
                                    height: isActive ? 10 : 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PhotoMetaCard extends StatelessWidget {
  const _PhotoMetaCard({this.senderName, this.sentTimeText});

  final String? senderName;
  final String? sentTimeText;

  @override
  Widget build(BuildContext context) {
    final hasSender = senderName != null && senderName!.isNotEmpty;
    final hasSentTime = sentTimeText != null && sentTimeText!.isNotEmpty;
    if (!hasSender && !hasSentTime) {
      return const SizedBox.shrink();
    }
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (hasSender)
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.person, size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      senderName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasSender && hasSentTime) const SizedBox(width: 10),
          if (hasSentTime)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  sentTimeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
