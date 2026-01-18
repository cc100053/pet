import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../services/image_labeling/image_labeling.dart';
import '../../services/label_mapping/label_mapping_service.dart';

class FeedCaptureView extends StatefulWidget {
  const FeedCaptureView({
    super.key,
    required this.roomId,
    this.onOptimisticMessage,
    this.onUploadCompleted,
    this.onUploadFailed,
  });

  final String roomId;
  final ValueChanged<FeedOptimisticMessage>? onOptimisticMessage;
  final ValueChanged<String>? onUploadCompleted;
  final void Function(String tempId, Object error)? onUploadFailed;

  @override
  State<FeedCaptureView> createState() => _FeedCaptureViewState();
}

class _FeedCaptureViewState extends State<FeedCaptureView> {
  static const int _uploadMaxDimension = 2048;
  static const int _webpQuality = 60;

  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  late final ImageLabelingService _labeler;

  LabelMappingService? _mappingService;
  bool _loadingMappings = false;
  String? _mappingError;

  Uint8List? _previewBytes;
  XFile? _selectedImage;

  bool _analyzing = false;
  bool _sending = false;
  String? _error;
  String? _result;

  List<LabelObservation> _observations = const [];
  List<LabelMatch> _matches = const [];
  List<String> _canonicalTags = const [];
  int _imageRequestId = 0;

  @override
  void initState() {
    super.initState();
    _labeler = createImageLabelingService(confidenceThreshold: 0.6);
    _loadMappings();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _labeler.dispose();
    super.dispose();
  }

  Future<void> _loadMappings() async {
    setState(() {
      _loadingMappings = true;
      _mappingError = null;
    });

    try {
      final repository = LabelMappingRepository(Supabase.instance.client);
      final entries = await repository.fetch();
      if (!mounted) {
        return;
      }
      setState(() {
        _mappingService = LabelMappingService(entries);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mappingError = 'Failed to load label mappings: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMappings = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _error = null;
      _result = null;
    });

    AnalyticsService.instance.logEvent('feed_image_pick', parameters: {
      'source': source.name,
    });
    final image = await _picker.pickImage(
      source: source,
    );
    if (image == null) {
      return;
    }

    final previewBytes = await image.readAsBytes();
    final requestId = ++_imageRequestId;

    setState(() {
      _previewBytes = previewBytes;
      _selectedImage = image;
      _observations = const [];
      _matches = const [];
      _canonicalTags = const [];
    });

    await _analyzeImage(image, requestId);
  }

  Future<void> _analyzeImage(XFile image, int requestId) async {
    if (kIsWeb) {
      setState(() {
        _error = 'ML Kit image labeling is not supported on web.';
      });
      return;
    }

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final labels = await _labeler.analyzeImage(image.path);
      final observations = labels
          .map(
            (label) => LabelObservation(
              text: label.label,
              confidence: label.confidence,
            ),
          )
          .toList();

      final mappingService = _mappingService;
      final matches = mappingService?.matchLabels(observations) ?? const [];
      final tags = mappingService?.matchCanonicalTags(observations) ?? const [];

      if (!mounted || _imageRequestId != requestId) {
        return;
      }

      setState(() {
        _observations = observations;
        _matches = matches;
        _canonicalTags = tags;
      });
    } catch (error) {
      if (!mounted || _imageRequestId != requestId) {
        return;
      }
      setState(() {
        _error = 'Labeling failed: $error';
      });
    } finally {
      if (mounted && _imageRequestId == requestId) {
        setState(() {
          _analyzing = false;
        });
      }
    }
  }

  Future<void> _sendFeed() async {
    final image = _selectedImage;
    final previewBytes = _previewBytes;
    if (image == null || previewBytes == null) {
      setState(() {
        _error = 'Select an image first.';
      });
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'No active session. Please sign in again.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _result = null;
    });

    try {
      final clientCreatedAt = DateTime.now().toUtc();
      final clientCreatedAtIso = clientCreatedAt.toIso8601String();
      final tempId = 'temp_${clientCreatedAt.microsecondsSinceEpoch}';
      final matchByLabel = <String, String>{};
      for (final match in _matches) {
        matchByLabel[LabelMappingService.normalizeLabel(match.text)] =
            match.canonicalTag;
      }

      final labelsPayload = _observations
          .map(
            (label) => {
              'text': label.text,
              'confidence': label.confidence,
              if (matchByLabel
                  .containsKey(LabelMappingService.normalizeLabel(label.text)))
                'canonical_tag':
                    matchByLabel[LabelMappingService.normalizeLabel(label.text)],
            },
          )
          .toList();

      final caption = _captionController.text.trim();

      widget.onOptimisticMessage?.call(
        FeedOptimisticMessage(
          tempId: tempId,
          roomId: widget.roomId,
          senderId: userId,
          localImagePath: image.path,
          caption: caption.isEmpty ? null : caption,
          clientCreatedAt: clientCreatedAt,
          labels: labelsPayload,
        ),
      );

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
        _error = 'Send failed: $error';
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
      default:
        return 'image/jpeg';
    }
  }

  Future<_CompressedImage> _compressForUpload(
    XFile image,
    Uint8List originalBytes,
  ) async {
    if (kIsWeb) {
      return _CompressedImage(
        bytes: originalBytes,
        contentType: _contentTypeForPath(image.path),
      );
    }

    try {
      final dimensions = await _readImageDimensions(originalBytes);
      if (dimensions == null) {
        return _CompressedImage(
          bytes: originalBytes,
          contentType: _contentTypeForPath(image.path),
        );
      }

      final width = dimensions.width;
      final height = dimensions.height;

      final longestSide = width > height ? width : height;
      final scale = longestSide > _uploadMaxDimension
          ? _uploadMaxDimension / longestSide
          : 1.0;
      final targetWidth = (width * scale).round();
      final targetHeight = (height * scale).round();

      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        format: CompressFormat.webp,
        quality: _webpQuality,
        minWidth: targetWidth.clamp(1, width),
        minHeight: targetHeight.clamp(1, height),
        keepExif: false,
      );
      if (compressed != null && compressed.isNotEmpty) {
        return _CompressedImage(
          bytes: Uint8List.fromList(compressed),
          contentType: 'image/webp',
        );
      }
    } catch (_) {
      // Fallback to original bytes + content type when compression fails.
    }

    return _CompressedImage(
      bytes: originalBytes,
      contentType: _contentTypeForPath(image.path),
    );
  }

  Future<_ImageDimensions?> _readImageDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final dimensions = _ImageDimensions(image.width, image.height);
      image.dispose();
      return dimensions;
    } catch (_) {
      return null;
    }
  }

  int? _cacheDimension(BuildContext context, double value) {
    if (!value.isFinite || value <= 0) {
      return null;
    }
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final target = (value * dpr).round();
    return target > 0 ? target : null;
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
      final dataUri =
          'data:$imageContentType;base64,${base64Encode(imageBytes)}';

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'feed_validate',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'room_id': widget.roomId,
            'labels': labelsPayload,
            'canonical_tags': _canonicalTags,
            'caption': caption,
            'image_base64': dataUri,
            'image_content_type': imageContentType,
            'client_created_at': clientCreatedAtIso,
          },
        );
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

      AnalyticsService.instance.logEvent('feed_send', parameters: {
        'result': 'success',
      });

      if (mounted) {
        setState(() {
          _result = jsonEncode({
            'status': response.status,
            'data': response.data,
          });
        });
      }

      widget.onUploadCompleted?.call(tempId);
    } catch (error) {
      AnalyticsService.instance.logEvent('feed_send', parameters: {
        'result': 'failure',
      });
      widget.onUploadFailed?.call(tempId, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mappingStatus = _loadingMappings
        ? 'Loading label mappings...'
        : (_mappingError ??
            (_mappingService == null
                ? 'Label mappings unavailable.'
                : 'Label mappings ready.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Camera'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Capture a feed photo and review labels before sending.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            mappingStatus,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _sending ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                onPressed: _sending ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
          if (_previewBytes != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cacheWidth =
                      _cacheDimension(context, constraints.maxWidth);
                  final cacheHeight = _cacheDimension(context, 240);
                  return Image.memory(
                    _previewBytes!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_analyzing)
            const LinearProgressIndicator()
          else if (_observations.isNotEmpty)
            _LabelsPreview(
              observations: _observations,
              matches: _matches,
            )
          else
            Text(
              'No labels detected yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Caption (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sending || _analyzing ? null : _sendFeed,
            child: Text(_sending ? 'Sending...' : 'Send Feed'),
          ),
          if (_canonicalTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Canonical tags: ${_canonicalTags.join(', ')}'),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text('Response: $_result'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompressedImage {
  const _CompressedImage({
    required this.bytes,
    required this.contentType,
  });

  final Uint8List bytes;
  final String contentType;
}

class _ImageDimensions {
  const _ImageDimensions(this.width, this.height);

  final int width;
  final int height;
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

class _LabelsPreview extends StatelessWidget {
  const _LabelsPreview({
    required this.observations,
    required this.matches,
  });

  final List<LabelObservation> observations;
  final List<LabelMatch> matches;

  @override
  Widget build(BuildContext context) {
    final matchByLabel = <String, String>{
      for (final match in matches)
        LabelMappingService.normalizeLabel(match.text): match.canonicalTag,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected labels',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: observations
              .map(
                (label) => Chip(
                  label: Text(
                    '${label.text} (${(label.confidence * 100).round()}%)'
                    '${matchByLabel.containsKey(
                          LabelMappingService.normalizeLabel(label.text),
                        )
                        ? ' -> ${matchByLabel[LabelMappingService.normalizeLabel(label.text)]}'
                        : ''}',
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
