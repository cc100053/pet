import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
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

  // Per-page zoom state keeps gesture behavior isolated to each photo canvas.
  final Map<int, TransformationController> _transformControllers =
      <int, TransformationController>{};
  late AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  int? _zoomAnimationIndex;
  bool _chromeVisible = true;
  bool _isCurrentPageZoomed = false;
  bool _savingToGallery = false;
  bool _showDownloadedIcon = false;
  Timer? _downloadedIconTimer;
  Timer? _singleTapTimer;
  int _activePointerCount = 0;
  Offset? _tapDownPosition;
  bool _singleTapCancelled = false;
  final Map<int, double> _aspectRatios = <int, double>{};
  final Set<int> _resolvingAspect = <int>{};

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
          final index = _zoomAnimationIndex;
          if (_zoomAnimation != null && index != null) {
            _controllerFor(index).value = _zoomAnimation!.value;
          }
        });
    _isCurrentPageZoomed = _currentScale > 1.01;
  }

  @override
  void dispose() {
    _downloadedIconTimer?.cancel();
    _singleTapTimer?.cancel();
    _pageController.dispose();
    _zoomAnimController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _closeWithCurrentIndex() {
    Navigator.of(context).pop(_currentIndex);
  }

  TransformationController _controllerFor(int index) {
    return _transformControllers.putIfAbsent(index, () {
      final controller = TransformationController();
      controller.addListener(() => _handleTransformChanged(index));
      return controller;
    });
  }

  double _scaleFor(int index) {
    return _transformControllers[index]?.value.getMaxScaleOnAxis() ?? 1.0;
  }

  double get _currentScale => _scaleFor(_currentIndex);

  void _handleTransformChanged(int index) {
    if (!mounted || index != _currentIndex) {
      return;
    }
    final isZoomed = _scaleFor(index) > 1.01;
    if (isZoomed == _isCurrentPageZoomed) {
      return;
    }
    setState(() {
      _isCurrentPageZoomed = isZoomed;
      if (isZoomed) {
        _chromeVisible = false;
      }
    });
  }

  void _handleDoubleTapDown(int index, TapDownDetails details) {
    _singleTapTimer?.cancel();
    _zoomAnimationIndex = index;
    _doubleTapDetails = details;
  }

  void _handleDoubleTap(int index) {
    final controller = _controllerFor(index);
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = controller.value.getMaxScaleOnAxis();

    Matrix4 end;
    if (currentScale > 1.1) {
      end = Matrix4.identity();
    } else {
      const targetScale = 2.5;
      end = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (targetScale - 1),
          -position.dy * (targetScale - 1),
          0,
          1,
        )
        ..scaleByDouble(targetScale, targetScale, 1, 1);
    }

    _zoomAnimation = Matrix4Tween(begin: controller.value, end: end).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  void _toggleChrome() {
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _handleCanvasPointerDown(PointerDownEvent event) {
    _activePointerCount += 1;
    if (_activePointerCount > 1) {
      _singleTapTimer?.cancel();
      _singleTapCancelled = true;
      return;
    }
    _tapDownPosition = event.position;
    _singleTapCancelled = false;
  }

  void _handleCanvasPointerMove(PointerMoveEvent event) {
    final start = _tapDownPosition;
    if (_activePointerCount != 1 || _singleTapCancelled || start == null) {
      return;
    }
    if ((event.position - start).distanceSquared > 144) {
      _singleTapCancelled = true;
    }
  }

  void _handleCanvasPointerEnd() {
    if (_activePointerCount > 0) {
      _activePointerCount -= 1;
    }
    if (_activePointerCount != 0 || _singleTapCancelled) {
      if (_activePointerCount == 0) {
        _tapDownPosition = null;
        _singleTapCancelled = false;
      }
      return;
    }
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(kDoubleTapTimeout, () {
      if (!mounted) {
        return;
      }
      _toggleChrome();
    });
    _tapDownPosition = null;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_currentScale > 1.05) {
      return;
    }

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
    setState(() {
      _currentIndex = index;
      _isCurrentPageZoomed = _scaleFor(index) > 1.01;
      _dragOffset = 0;
      _dragOpacity = 1.0;
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

  void _ensureAspectRatio(int index) {
    final item = widget.items[index];
    final url = item.imageUrl.trim();
    final localPath = item.localImagePath;
    final cacheKey = url.isNotEmpty
        ? url
        : (localPath == null || localPath.isEmpty ? '' : 'local:$localPath');

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
      ImageAspectCache.instance.ensureResolved(url);
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
    final controller = _controllerFor(index);

    Widget imageWidget;
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      imageWidget = Image.file(
        File(localPath),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    } else if (url.isNotEmpty) {
      imageWidget = CachedNetworkImageView(imageUrl: url, fit: BoxFit.contain);
    } else {
      imageWidget = const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureAspectRatio(index);
        final aspectRatio =
            _aspectRatios[index] ??
            (constraints.maxWidth / constraints.maxHeight).clamp(0.5, 2.0);
        var imageWidth = constraints.maxWidth;
        var imageHeight = imageWidth / aspectRatio;
        if (imageHeight > constraints.maxHeight) {
          imageHeight = constraints.maxHeight;
          imageWidth = imageHeight * aspectRatio;
        }

        return Listener(
          onPointerDown: _handleCanvasPointerDown,
          onPointerMove: _handleCanvasPointerMove,
          onPointerUp: (_) => _handleCanvasPointerEnd(),
          onPointerCancel: (_) => _handleCanvasPointerEnd(),
          child: GestureDetector(
            key: ValueKey<String>('photo-viewer-canvas-$index'),
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (details) => _handleDoubleTapDown(index, details),
            onDoubleTap: () => _handleDoubleTap(index),
            child: Center(
              child: InteractiveViewer(
                transformationController: controller,
                minScale: 1.0,
                maxScale: 5.0,
                panEnabled: _scaleFor(index) > 1.001,
                scaleEnabled: true,
                constrained: false,
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Center(child: imageWidget),
                ),
              ),
            ),
          ),
        );
      },
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

  Widget _buildTopChrome({
    required AppLocalizations l10n,
    required String? senderName,
    required DateTime? sentAt,
  }) {
    final hasMeta = senderName != null || sentAt != null;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildTopCircleIconButton(
                  onPressed: (_savingToGallery || _showDownloadedIcon)
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
                            valueColor: AlwaysStoppedAnimation<Color>(
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
                const Spacer(),
                _buildTopCircleIconButton(
                  onPressed: _closeWithCurrentIndex,
                  icon: Icons.close,
                  tooltip: l10n.commonClose,
                ),
              ],
            ),
            if (hasMeta) ...[
              const SizedBox(height: 8),
              Center(
                child: _PhotoMetaStrip(
                  senderName: senderName,
                  sentTimeText: sentAt == null ? null : _formatSentTime(sentAt),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomChrome({
    required String? caption,
    required int imageCount,
  }) {
    final showIndicator = widget.showIndicator && imageCount > 1;
    if (caption == null && !showIndicator) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: caption == null ? 0.42 : 0.76),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, caption == null ? 24 : 56, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showIndicator)
                  Center(
                    child: _PageIndicator(
                      currentIndex: _currentIndex,
                      count: imageCount,
                    ),
                  ),
                if (caption != null) ...[
                  if (showIndicator) const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      caption,
                      key: const ValueKey<String>('photo-viewer-caption'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChromeOverlay({
    Key? key,
    required AppLocalizations l10n,
    required String? senderName,
    required DateTime? sentAt,
    required String? caption,
    required int imageCount,
  }) {
    return _ChromeOverlay(
      key: key,
      top: _buildTopChrome(l10n: l10n, senderName: senderName, sentAt: sentAt),
      bottom: _buildBottomChrome(caption: caption, imageCount: imageCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.items.length;
    final l10n = AppLocalizations.of(context)!;
    final senderName = _senderNameFor(_currentIndex);
    final sentTime = _sentTimeFor(_currentIndex);
    final caption = _captionFor(_currentIndex);

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
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _dragOpacity,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageCount == 1
                          ? _buildImage(0)
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: imageCount,
                              onPageChanged: _onPageChanged,
                              physics: _isCurrentPageZoomed
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              itemBuilder: (_, index) => _buildImage(index),
                            ),
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _chromeVisible
                              ? _buildChromeOverlay(
                                  key: const ValueKey<String>(
                                    'photo-viewer-chrome',
                                  ),
                                  l10n: l10n,
                                  senderName: senderName,
                                  sentAt: sentTime,
                                  caption: caption,
                                  imageCount: imageCount,
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey<String>(
                                    'photo-viewer-no-chrome',
                                  ),
                                ),
                        ),
                      ),
                    ],
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

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentIndex, required this.count});

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 12 : 6,
          height: isActive ? 12 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.38),
          ),
        );
      }),
    );
  }
}

class _ChromeOverlay extends StatelessWidget {
  const _ChromeOverlay({super.key, required this.top, required this.bottom});

  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [top, bottom]);
  }
}

class _PhotoMetaStrip extends StatelessWidget {
  const _PhotoMetaStrip({this.senderName, this.sentTimeText});

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
      key: const ValueKey<String>('photo-viewer-meta'),
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSender)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Flexible(
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
          if (hasSender && hasSentTime) const SizedBox(width: 12),
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
