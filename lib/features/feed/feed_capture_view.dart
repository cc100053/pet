import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/responsive_layout.dart';
import '../../shared/ui/status_bar_style.dart';
import 'feed_upload_models.dart';
import 'feed_upload_queue.dart';

export 'feed_upload_models.dart';

@visibleForTesting
void dispatchFeedCaptureCallback({
  required String callbackName,
  required void Function() callback,
}) {
  try {
    callback();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'feed_capture_view',
        context: ErrorDescription('while running $callbackName'),
      ),
    );
  }
}

class FeedCaptureView extends ConsumerStatefulWidget {
  const FeedCaptureView({
    super.key,
    required this.roomId,
    this.onOptimisticMessage,
    this.onSendStarted,
    this.pickImage,
  });

  final String roomId;
  final ValueChanged<FeedOptimisticMessage>? onOptimisticMessage;
  final ValueChanged<FeedOptimisticMessage>? onSendStarted;
  @visibleForTesting
  final Future<XFile?> Function(ImageSource source)? pickImage;

  @override
  ConsumerState<FeedCaptureView> createState() => _FeedCaptureViewState();
}

class _FeedCaptureViewState extends ConsumerState<FeedCaptureView> {
  static const int _feedInputHardLimitBytes = 30 * 1024 * 1024;

  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _previewBytes;
  XFile? _selectedImage;

  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _error = null;
    });

    AnalyticsService.instance.logEvent(
      'feed_image_pick',
      parameters: {'source': source.name},
    );
    XFile? image;
    Uint8List? previewBytes;
    try {
      image =
          await (widget.pickImage?.call(source) ??
              _picker.pickImage(source: source));
      if (image == null) {
        return;
      }
      previewBytes = await image.readAsBytes();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = userFacingError(
          context,
          error,
          stackTrace: stackTrace,
          source: 'feed_pick_image',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }
    if (previewBytes.length > _feedInputHardLimitBytes) {
      setState(() {
        _error = AppLocalizations.of(context)!.errorImageTooLarge;
      });
      return;
    }

    setState(() {
      _previewBytes = previewBytes;
      _selectedImage = image;
    });
  }

  Future<void> _sendFeed() async {
    final image = _selectedImage;
    final previewBytes = _previewBytes;
    if (image == null || previewBytes == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.feedSelectImageFirst;
      });
      return;
    }
    if (previewBytes.length > _feedInputHardLimitBytes) {
      setState(() {
        _error = AppLocalizations.of(context)!.errorImageTooLarge;
      });
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.authReauthRequired;
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final clientCreatedAt = DateTime.now().toUtc();
      final labelsPayload = <Map<String, dynamic>>[];

      final caption = _captionController.text.trim();

      final job = await ref
          .read(feedUploadQueueProvider.notifier)
          .enqueue(
            roomId: widget.roomId,
            senderId: userId,
            localImagePath: image.path,
            caption: caption.isEmpty ? null : caption,
            clientCreatedAt: clientCreatedAt,
            labels: labelsPayload,
            initialBytes: previewBytes,
          );

      final optimistic = job.toOptimisticMessage();
      final onOptimisticMessage = widget.onOptimisticMessage;
      if (onOptimisticMessage != null) {
        dispatchFeedCaptureCallback(
          callbackName: 'FeedCaptureView.onOptimisticMessage',
          callback: () => onOptimisticMessage(optimistic),
        );
      }
      final onSendStarted = widget.onSendStarted;
      if (onSendStarted != null) {
        dispatchFeedCaptureCallback(
          callbackName: 'FeedCaptureView.onSendStarted',
          callback: () => onSendStarted(optimistic),
        );
      }

      AnalyticsService.instance.logEvent(
        'feed_send_queued',
        parameters: {'room_id': widget.roomId},
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.feedSendFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF3),
        appBar: AppBar(
          systemOverlayStyle: AppStatusBarStyles.light,
          title: Text(
            l10n.feedCameraTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textPrimary,
        ),
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, viewport) {
                final responsive = ResponsiveLayout.fromSize(viewport.biggest);
                return Stack(
                  children: [
                    Positioned(
                      top: responsive.y(-70),
                      left: responsive.x(-50),
                      child: _Blob(
                        size: responsive.s(180),
                        color: const Color(0xFFFFD68D).withValues(alpha: 0.45),
                      ),
                    ),
                    Positioned(
                      right: responsive.x(-42),
                      top: responsive.y(120),
                      child: _Blob(
                        size: responsive.s(130),
                        color: const Color(0xFFAED6B3).withValues(alpha: 0.35),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior:
                                formScrollKeyboardDismissBehavior,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 360,
                                      ),
                                      child: Container(
                                        height: 300,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: Colors.black12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          child: _previewBytes == null
                                              ? const _EmptyPreviewState()
                                              : LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    // Cap the decode to the
                                                    // preview width: picked
                                                    // photos can be full
                                                    // sensor resolution and
                                                    // decoding them whole
                                                    // can exhaust memory.
                                                    final dpr =
                                                        MediaQuery.devicePixelRatioOf(
                                                          context,
                                                        );
                                                    final maxWidth =
                                                        constraints
                                                                .maxWidth
                                                                .isFinite &&
                                                            constraints
                                                                    .maxWidth >
                                                                0
                                                        ? constraints.maxWidth
                                                        : 360.0;
                                                    final cacheWidth =
                                                        (maxWidth * dpr)
                                                            .round()
                                                            .clamp(1, 1080);
                                                    return DecoratedBox(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFFF8F4EF,
                                                            ),
                                                          ),
                                                      child: Image.memory(
                                                        _previewBytes!,
                                                        fit: BoxFit.contain,
                                                        cacheWidth: cacheWidth,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PickSourceCard(
                                          label: l10n.commonGallery,
                                          icon: Icons.photo_library_rounded,
                                          color: const Color(0xFFFFBE8A),
                                          onTap: _sending
                                              ? null
                                              : () => _pickImage(
                                                  ImageSource.gallery,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _PickSourceCard(
                                          label: l10n.commonCamera,
                                          icon: Icons.photo_camera_rounded,
                                          color: const Color(0xFF8ED0A9),
                                          onTap: _sending
                                              ? null
                                              : () => _pickImage(
                                                  ImageSource.camera,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _captionController,
                                    onTapOutside: dismissKeyboardOnTapOutside,
                                    decoration: InputDecoration(
                                      hintText: l10n.feedCaptionLabel,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                    ),
                                    maxLines: 2,
                                    maxLength: 40,
                                    buildCounter:
                                        (
                                          BuildContext context, {
                                          required int currentLength,
                                          required bool isFocused,
                                          required int? maxLength,
                                        }) {
                                          return null;
                                        },
                                  ),
                                  FilledButton(
                                    onPressed:
                                        _sending || _selectedImage == null
                                        ? null
                                        : _sendFeed,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _sending
                                              ? Icons.sync_rounded
                                              : Icons.send_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _sending
                                              ? l10n.commonSending
                                              : l10n.feedSendButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PickSourceCard extends StatelessWidget {
  const _PickSourceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPreviewState extends StatelessWidget {
  const _EmptyPreviewState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF7E8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add_a_photo_rounded,
        size: 34,
        color: Color(0xFF7A6A58),
      ),
    );
  }
}
