import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/responsive_layout.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/upload_limits.dart';

class FeedCaptureView extends StatefulWidget {
  const FeedCaptureView({
    super.key,
    required this.roomId,
    this.onOptimisticMessage,
    this.onSendStarted,
    this.onUploadCompleted,
    this.onUploadFailed,
  });

  final String roomId;
  final ValueChanged<FeedOptimisticMessage>? onOptimisticMessage;
  final ValueChanged<FeedOptimisticMessage>? onSendStarted;
  final ValueChanged<FeedUploadResult>? onUploadCompleted;
  final void Function(String tempId, Object error)? onUploadFailed;

  @override
  State<FeedCaptureView> createState() => _FeedCaptureViewState();
}

class _FeedCaptureViewState extends State<FeedCaptureView> {
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
    final image = await _picker.pickImage(source: source);
    if (image == null) {
      return;
    }

    final previewBytes = await image.readAsBytes();
    if (previewBytes.length > kMaxUploadImageBytes) {
      if (!mounted) {
        return;
      }
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
    if (previewBytes.length > kMaxUploadImageBytes) {
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
      final clientCreatedAtIso = clientCreatedAt.toIso8601String();
      final tempId = 'temp_${clientCreatedAt.microsecondsSinceEpoch}';
      final labelsPayload = <Map<String, dynamic>>[];

      final caption = _captionController.text.trim();

      final optimistic = FeedOptimisticMessage(
        tempId: tempId,
        roomId: widget.roomId,
        senderId: userId,
        localImagePath: image.path,
        caption: caption.isEmpty ? null : caption,
        clientCreatedAt: clientCreatedAt,
        labels: labelsPayload,
      );
      widget.onOptimisticMessage?.call(optimistic);
      widget.onSendStarted?.call(optimistic);

      unawaited(
        _sendFeedInBackground(
          image: image,
          previewBytes: previewBytes,
          labelsPayload: labelsPayload,
          caption: caption.isEmpty ? null : caption,
          clientCreatedAtIso: clientCreatedAtIso,
          tempId: tempId,
        ),
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

  String _contentTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _detectImageContentType(Uint8List bytes, String path) {
    if (_isPng(bytes)) {
      return 'image/png';
    }
    if (_isJpeg(bytes)) {
      return 'image/jpeg';
    }
    if (_isWebp(bytes)) {
      return 'image/webp';
    }
    if (_isHeicOrHeif(bytes)) {
      return 'image/heic';
    }
    return _contentTypeForPath(path);
  }

  bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  bool _isPng(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  bool _isWebp(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final riff =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46;
    final webp =
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return riff && webp;
  }

  bool _isHeicOrHeif(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final hasFtyp =
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
    if (!hasFtyp) {
      return false;
    }
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    const heifBrands = <String>{
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1',
    };
    return heifBrands.contains(brand);
  }

  Future<_CompressedImage> _compressForUpload(
    XFile image,
    Uint8List originalBytes,
  ) async {
    return _CompressedImage(
      bytes: originalBytes,
      contentType: _detectImageContentType(originalBytes, image.path),
    );
  }

  Future<void> _sendFeedInBackground({
    required XFile image,
    required Uint8List previewBytes,
    required List<Map<String, dynamic>> labelsPayload,
    required String? caption,
    required String clientCreatedAtIso,
    required String tempId,
  }) async {
    try {
      final compressed = await _compressForUpload(image, previewBytes);
      final imageContentType = compressed.contentType;
      final imageBytes = compressed.bytes;
      if (!kAllowedUploadImageContentTypes.contains(imageContentType)) {
        throw Exception('invalid_image_content_type');
      }
      if (imageBytes.length > kMaxUploadImageBytes) {
        throw Exception('image_too_large');
      }
      final dataUri =
          'data:$imageContentType;base64,${base64Encode(imageBytes)}';

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'feed_validate',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'room_id': widget.roomId,
            'labels': labelsPayload,
            'canonical_tags': const <String>[],
            'caption': caption,
            'image_base64': dataUri,
            'image_content_type': imageContentType,
            'client_created_at': clientCreatedAtIso,
          },
        );
      }

      String responseErrorSummary(FunctionResponse response) {
        final data = response.data;
        if (data is Map) {
          final error = data['error']?.toString();
          final detail = data['detail']?.toString();
          if (error != null && error.isNotEmpty) {
            if (detail != null && detail.isNotEmpty) {
              return '$error:$detail';
            }
            return error;
          }
        }
        return 'status_${response.status}';
      }

      int parseInt(dynamic value) {
        if (value is int) {
          return value;
        }
        if (value is num) {
          return value.toInt();
        }
        return 0;
      }

      bool parseBool(dynamic value) {
        if (value is bool) {
          return value;
        }
        return false;
      }

      String? parseString(dynamic value) {
        if (value is String && value.isNotEmpty) {
          return value;
        }
        return null;
      }

      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        throw Exception('missing_session');
      }

      FunctionResponse response;
      try {
        response = await invokeWithToken(accessToken);
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          response = await invokeWithToken(refreshedToken);
        } else {
          rethrow;
        }
      }

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'feed_validate_failed:${responseErrorSummary(response)}',
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('feed_validate_invalid_response');
      }
      final ok = data['ok'] == true;
      if (!ok) {
        throw Exception('feed_validate_rejected');
      }
      final cooldownPayload = data['cooldown'];
      final cooldown = cooldownPayload is Map<String, dynamic>
          ? cooldownPayload
          : <String, dynamic>{};

      final reward = FeedUploadResult(
        tempId: tempId,
        coinsAwarded: parseInt(data['coins_awarded']),
        messageId: parseString(data['message_id']),
        imageUrl: parseString(data['image_url']),
        rewardStatus: parseString(data['reward_status']),
        cooldownActive: parseBool(cooldown['is_active']),
        lastFedAt: parseString(cooldown['last_fed_at']),
        nextEligibleAt: parseString(cooldown['next_eligible_at']),
      );

      AnalyticsService.instance.logEvent(
        'feed_send',
        parameters: {'result': 'success'},
      );

      widget.onUploadCompleted?.call(reward);
    } catch (error) {
      AnalyticsService.instance.logEvent(
        'feed_send',
        parameters: {'result': 'failure'},
      );
      widget.onUploadFailed?.call(tempId, error);
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
                                                  builder:
                                                      (context, constraints) {
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

class _CompressedImage {
  const _CompressedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

class FeedOptimisticMessage {
  const FeedOptimisticMessage({
    required this.tempId,
    required this.roomId,
    required this.senderId,
    required this.localImagePath,
    required this.caption,
    required this.clientCreatedAt,
    required this.labels,
  });

  final String tempId;
  final String roomId;
  final String senderId;
  final String localImagePath;
  final String? caption;
  final DateTime clientCreatedAt;
  final List<Map<String, dynamic>> labels;
}

class FeedUploadResult {
  const FeedUploadResult({
    required this.tempId,
    required this.coinsAwarded,
    this.messageId,
    this.imageUrl,
    this.rewardStatus,
    this.cooldownActive = false,
    this.lastFedAt,
    this.nextEligibleAt,
  });

  final String tempId;
  final int coinsAwarded;
  final String? messageId;
  final String? imageUrl;
  final String? rewardStatus;
  final bool cooldownActive;
  final String? lastFedAt;
  final String? nextEligibleAt;
}
