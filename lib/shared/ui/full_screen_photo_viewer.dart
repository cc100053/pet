import 'dart:io';

import 'package:flutter/material.dart';

import 'cached_network_image_view.dart';

/// iPhone-style full-screen photo viewer with:
/// - Double-tap to zoom
/// - Pinch/drag to zoom and pan
/// - Swipe down to dismiss
/// - Swipe left/right between photos
class FullScreenPhotoViewer extends StatefulWidget {
  const FullScreenPhotoViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.localImagePaths = const {},
    this.showIndicator = true,
    this.captions = const [],
  });

  final List<String> imageUrls;
  final List<String?> captions;
  final int initialIndex;
  final bool showIndicator;

  /// Map of index -> local file path for optimistic display
  final Map<int, String> localImagePaths;

  /// Opens the photo viewer using a fade transition.
  static void open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    Map<int, String> localImagePaths = const {},
    bool showIndicator = true,
    List<String?> captions = const [],
  }) {
    if (imageUrls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenPhotoViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          localImagePaths: localImagePaths,
          showIndicator: showIndicator,
          captions: captions,
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _zoomAnimController = AnimationController(
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
    _pageController.dispose();
    _zoomAnimController.dispose();
    _transformController.dispose();
    super.dispose();
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

    _zoomAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: end,
    ).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
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
      Navigator.of(context).pop();
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

  String? _captionFor(int index) {
    if (widget.captions.length <= index) {
      return null;
    }
    final caption = widget.captions[index]?.trim();
    if (caption == null || caption.isEmpty) {
      return null;
    }
    return caption;
  }

  Widget _buildImage(int index) {
    final url = widget.imageUrls[index];
    final localPath = widget.localImagePaths[index];

    Widget imageWidget;
    if (localPath != null && File(localPath).existsSync()) {
      imageWidget = Image.file(
        File(localPath),
        fit: BoxFit.contain,
      );
    } else if (url.isNotEmpty) {
      imageWidget = CachedNetworkImageView(
        imageUrl: url,
        fit: BoxFit.contain,
      );
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
    final hasCaption = caption != null;
    final reservedHeight = hasCaption ? 56.0 : 0.0;
    final maxHeight = constraints.maxHeight.isFinite
        ? (constraints.maxHeight - reservedHeight).clamp(0.0, double.infinity)
        : constraints.maxHeight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: maxHeight,
            width: constraints.maxWidth,
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

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;

    return Scaffold(
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
                              physics: _transformController.value
                                          .getMaxScaleOnAxis() >
                                      1.05
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              itemBuilder: (_, index) =>
                                  _buildImagePage(index, constraints),
                            ),

                      // Close button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
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
