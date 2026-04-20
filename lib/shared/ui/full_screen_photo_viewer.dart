import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'chat_emoji_picker_sheet.dart';
import 'photo_viewer_item.dart';
import 'status_bar_style.dart';

typedef PhotoViewerReplyHandler =
    Future<void> Function(PhotoViewerItem item, String text);
typedef PhotoViewerReactionHandler =
    Future<void> Function(
      PhotoViewerItem item,
      String emoji,
      String? currentReactionEmoji,
    );

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
    this.cacheManager,
    this.onSendReply,
    this.onToggleReaction,
  });

  final List<PhotoViewerItem> items;
  final int initialIndex;
  final bool showIndicator;
  final BaseCacheManager? cacheManager;
  final PhotoViewerReplyHandler? onSendReply;
  final PhotoViewerReactionHandler? onToggleReaction;

  static Future<int?> open(
    BuildContext context, {
    required List<PhotoViewerItem> items,
    int initialIndex = 0,
    bool showIndicator = true,
    BaseCacheManager? cacheManager,
    PhotoViewerReplyHandler? onSendReply,
    PhotoViewerReactionHandler? onToggleReaction,
  }) {
    if (items.isEmpty) {
      return Future<int?>.value(null);
    }
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
              cacheManager: cacheManager,
              onSendReply: onSendReply,
              onToggleReaction: onToggleReaction,
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

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, PhotoViewController> _photoControllers =
      <int, PhotoViewController>{};
  final Map<int, StreamSubscription<PhotoViewControllerValue>>
  _photoControllerSubscriptions =
      <int, StreamSubscription<PhotoViewControllerValue>>{};
  final Map<int, double> _pageScales = <int, double>{};

  double _dragOffset = 0;
  double _dragOpacity = 1.0;
  bool _chromeVisible = true;
  bool _isCurrentPageZoomed = false;
  int? _trackingPointer;
  double? _pointerDownY;
  bool _savingToGallery = false;
  bool _showDownloadedIcon = false;
  bool _showReplySentState = false;
  final Map<String, String?> _selectedReactionByMessageId = <String, String?>{};
  Timer? _downloadedIconTimer;
  Timer? _replySentTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    for (final item in widget.items) {
      final messageId = item.messageId?.trim();
      if (messageId == null || messageId.isEmpty) {
        continue;
      }
      _selectedReactionByMessageId[messageId] = item.selectedReactionEmoji;
    }
  }

  @override
  void dispose() {
    _downloadedIconTimer?.cancel();
    _replySentTimer?.cancel();
    _pageController.dispose();
    for (final subscription in _photoControllerSubscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _photoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PhotoViewController _photoControllerFor(int index) {
    return _photoControllers.putIfAbsent(index, () {
      final controller = PhotoViewController();
      _photoControllerSubscriptions[index] = controller.outputStateStream
          .listen((value) {
            final scale = value.scale ?? 1.0;
            _pageScales[index] = scale;
            if (!mounted || index != _currentIndex) {
              return;
            }
            final isZoomed = scale > 1.01;
            if (isZoomed == _isCurrentPageZoomed) {
              return;
            }
            setState(() {
              _isCurrentPageZoomed = isZoomed;
              if (isZoomed) {
                _chromeVisible = false;
              }
            });
          });
      return controller;
    });
  }

  double _scaleFor(int index) => _pageScales[index] ?? 1.0;

  void _closeWithCurrentIndex() {
    Navigator.of(context).pop(_currentIndex);
  }

  void _toggleChrome() {
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _onRawPointerDown(PointerDownEvent event) {
    if (_trackingPointer == null) {
      _trackingPointer = event.pointer;
      _pointerDownY = event.position.dy;
    } else {
      _cancelDismissGesture();
    }
  }

  void _onRawPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackingPointer) return;
    if (_isCurrentPageZoomed) {
      _cancelDismissGesture();
      return;
    }
    final dy = event.position.dy - (_pointerDownY ?? event.position.dy);
    setState(() {
      _dragOffset = dy;
      _dragOpacity = (1 - (dy.abs() / 300)).clamp(0.4, 1.0);
    });
  }

  void _onRawPointerUp(PointerUpEvent event) {
    if (event.pointer != _trackingPointer) return;
    _trackingPointer = null;
    _pointerDownY = null;
    if (_dragOffset.abs() > 100) {
      _closeWithCurrentIndex();
      return;
    }
    setState(() {
      _dragOffset = 0;
      _dragOpacity = 1.0;
    });
  }

  void _onRawPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _trackingPointer) return;
    _cancelDismissGesture();
  }

  void _cancelDismissGesture() {
    _trackingPointer = null;
    _pointerDownY = null;
    if (_dragOffset != 0) {
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

  ImageProvider<Object>? _imageProviderFor(PhotoViewerItem item) {
    final localPath = item.localImagePath?.trim();
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    final url = item.imageUrl.trim();
    if (url.isNotEmpty) {
      return CachedNetworkImageProvider(
        url,
        cacheManager: widget.cacheManager,
        errorListener: (_) {},
      );
    }
    return null;
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

  String? _captionFor(int index) {
    final caption = widget.items[index].caption?.trim();
    if (caption == null || caption.isEmpty) {
      return null;
    }
    return caption;
  }

  String? _senderNameFor(int index) {
    final sender = widget.items[index].senderName?.trim();
    if (sender == null || sender.isEmpty) {
      return null;
    }
    return sender;
  }

  PhotoViewerItem get _currentItem => widget.items[_currentIndex];

  bool get _canUseChatActions =>
      _currentItem.canChatInteract &&
      (widget.onSendReply != null || widget.onToggleReaction != null);

  String? get _currentReactionEmoji {
    final messageId = _currentItem.messageId?.trim();
    if (messageId == null || messageId.isEmpty) {
      return _currentItem.selectedReactionEmoji;
    }
    return _selectedReactionByMessageId[messageId] ??
        _currentItem.selectedReactionEmoji;
  }

  DateTime? _sentTimeFor(int index) => widget.items[index].sentAt;

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

  Future<void> _openReplyComposer() async {
    if (!_canUseChatActions || widget.onSendReply == null) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();
    var sending = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleSend() async {
              final text = textController.text.trim();
              if (text.isEmpty || sending) {
                return;
              }
              final navigator = Navigator.of(sheetContext);
              setModalState(() => sending = true);
              try {
                await widget.onSendReply!(_currentItem, text);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                _replySentTimer?.cancel();
                setState(() => _showReplySentState = true);
                _replySentTimer = Timer(const Duration(seconds: 1), () {
                  if (!mounted) {
                    return;
                  }
                  setState(() => _showReplySentState = false);
                });
              } catch (error) {
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.chatSendFailed(error.toString())),
                  ),
                );
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => sending = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
              ),
              child: _ReplyComposerSheet(
                controller: textController,
                senderName: _senderNameFor(_currentIndex),
                previewText: _captionFor(_currentIndex) ?? l10n.feedTitle,
                sending: sending,
                onSend: handleSend,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openReactionSheet() async {
    if (!_canUseChatActions || widget.onToggleReaction == null) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final selectedEmoji = await showChatEmojiPickerSheet(
      context,
      selectedEmoji: _currentReactionEmoji,
    );
    if (!mounted || selectedEmoji == null || selectedEmoji.isEmpty) {
      return;
    }
    final previousReactionEmoji = _currentReactionEmoji;
    final messageId = _currentItem.messageId?.trim();
    if (messageId == null || messageId.isEmpty) {
      return;
    }
    setState(() {
      _selectedReactionByMessageId[messageId] =
          previousReactionEmoji == selectedEmoji ? null : selectedEmoji;
    });
    try {
      await widget.onToggleReaction!(
        _currentItem,
        selectedEmoji,
        previousReactionEmoji,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedReactionByMessageId[messageId] = previousReactionEmoji;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatSendFailed(error.toString()))),
      );
    }
  }

  PhotoViewGalleryPageOptions _pageOptionFor(int index) {
    final item = widget.items[index];
    final provider = _imageProviderFor(item);
    if (provider == null) {
      return _buildBrokenImagePageOption();
    }

    return PhotoViewGalleryPageOptions(
      imageProvider: provider,
      controller: _photoControllerFor(index),
      minScale: PhotoViewComputedScale.contained,
      initialScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.2,
      basePosition: Alignment.center,
      tightMode: true,
      filterQuality: FilterQuality.medium,
      heroAttributes: PhotoViewHeroAttributes(tag: 'photo-viewer-$index'),
      onTapUp: (context, details, controllerValue) => _toggleChrome(),
      errorBuilder: (context, error, stackTrace) => _buildBrokenImageView(),
    );
  }

  PhotoViewGalleryPageOptions _buildBrokenImagePageOption() {
    return PhotoViewGalleryPageOptions.customChild(
      child: _buildBrokenImageView(),
      childSize: const Size(320, 320),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      initialScale: PhotoViewComputedScale.contained,
      basePosition: Alignment.center,
    );
  }

  Widget _buildBrokenImageView() {
    return const Center(
      child: Icon(
        Icons.broken_image,
        key: ValueKey<String>('photo-viewer-broken-image'),
        color: Colors.white54,
        size: 64,
      ),
    );
  }

  Widget _buildGallery() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.items.length,
      onPageChanged: _onPageChanged,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      scrollPhysics: _isCurrentPageZoomed
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      loadingBuilder: (context, event) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      builder: (context, index) => _pageOptionFor(index),
    );
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
    required AppLocalizations l10n,
    required String? caption,
    required int imageCount,
  }) {
    final showIndicator = widget.showIndicator && imageCount > 1;
    final showChatActions =
        _currentItem.roomId?.trim().isNotEmpty == true &&
        (widget.onSendReply != null || widget.onToggleReaction != null);
    if (caption == null && !showIndicator && !showChatActions) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (caption != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        caption,
                        key: const ValueKey<String>('photo-viewer-caption'),
                        textAlign: TextAlign.center,
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
                  ),
                ),
              if (caption != null && showIndicator) const SizedBox(height: 12),
              if (showIndicator)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _PageIndicator(
                      currentIndex: _currentIndex,
                      count: imageCount,
                    ),
                  ),
                ),
              if (showChatActions) const SizedBox(height: 14),
              if (showChatActions)
                _ViewerActionRow(
                  replyEnabled:
                      _currentItem.canChatInteract &&
                      widget.onSendReply != null,
                  emojiEnabled:
                      _currentItem.canChatInteract &&
                      widget.onToggleReaction != null,
                  showReplySentState: _showReplySentState,
                  selectedReactionEmoji: _currentReactionEmoji,
                  replyLabel: l10n.chatReplyAction,
                  replySentLabel: l10n.photoViewerReplySentState,
                  emojiLabel: l10n.photoViewerEmojiAction,
                  onReply: _currentItem.canChatInteract
                      ? _openReplyComposer
                      : null,
                  onEmoji: _currentItem.canChatInteract
                      ? _openReactionSheet
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChromeOverlay({
    required AppLocalizations l10n,
    required String? senderName,
    required DateTime? sentAt,
    required String? caption,
    required int imageCount,
  }) {
    return _ChromeOverlay(
      key: const ValueKey<String>('photo-viewer-chrome'),
      top: _buildTopChrome(l10n: l10n, senderName: senderName, sentAt: sentAt),
      bottom: _buildBottomChrome(
        l10n: l10n,
        caption: caption,
        imageCount: imageCount,
      ),
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
          body: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onRawPointerDown,
            onPointerMove: _onRawPointerMove,
            onPointerUp: _onRawPointerUp,
            onPointerCancel: _onRawPointerCancel,
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
                      _buildGallery(),
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _chromeVisible
                              ? _buildChromeOverlay(
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

class _ViewerActionRow extends StatelessWidget {
  const _ViewerActionRow({
    required this.replyEnabled,
    required this.emojiEnabled,
    required this.showReplySentState,
    required this.selectedReactionEmoji,
    required this.replyLabel,
    required this.replySentLabel,
    required this.emojiLabel,
    required this.onReply,
    required this.onEmoji,
  });

  final bool replyEnabled;
  final bool emojiEnabled;
  final bool showReplySentState;
  final String? selectedReactionEmoji;
  final String replyLabel;
  final String replySentLabel;
  final String emojiLabel;
  final VoidCallback? onReply;
  final VoidCallback? onEmoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ViewerActionButton(
          key: const ValueKey<String>('photo-viewer-reply-button'),
          enabled: replyEnabled,
          label: showReplySentState ? replySentLabel : replyLabel,
          icon: showReplySentState ? Icons.check_rounded : Icons.reply_rounded,
          onTap: showReplySentState ? null : onReply,
        ),
        const Spacer(),
        _ViewerActionButton(
          key: const ValueKey<String>('photo-viewer-emoji-button'),
          enabled: emojiEnabled,
          label: emojiLabel,
          icon: selectedReactionEmoji == null
              ? Icons.emoji_emotions_outlined
              : null,
          iconText: selectedReactionEmoji,
          onTap: onEmoji,
        ),
      ],
    );
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconText,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : Colors.white54;
    final background = enabled
        ? Colors.black.withValues(alpha: 0.54)
        : Colors.black.withValues(alpha: 0.24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconText != null)
                Text(iconText!, style: const TextStyle(fontSize: 20))
              else if (icon != null)
                Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyComposerSheet extends StatelessWidget {
  const _ReplyComposerSheet({
    required this.controller,
    required this.senderName,
    required this.previewText,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? senderName;
  final String previewText;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.photoViewerReplyActionTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              senderName?.trim().isNotEmpty == true
                                  ? senderName!.trim()
                                  : l10n.feedTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('photo-viewer-reply-text-field'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.chatMessageHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey<String>('photo-viewer-reply-send-button'),
                  onPressed: sending ? null : onSend,
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.photoViewerReplySendAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
