import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/image_labeling/image_labeling.dart';
import '../../services/label_mapping/label_mapping_service.dart';

class FeedCaptureView extends StatefulWidget {
  const FeedCaptureView({super.key, required this.roomId});

  final String roomId;

  @override
  State<FeedCaptureView> createState() => _FeedCaptureViewState();
}

class _FeedCaptureViewState extends State<FeedCaptureView> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  late final ImageLabelingService _labeler;

  LabelMappingService? _mappingService;
  bool _loadingMappings = false;
  String? _mappingError;

  Uint8List? _imageBytes;
  String? _imageContentType;

  bool _analyzing = false;
  bool _sending = false;
  String? _error;
  String? _result;

  List<LabelObservation> _observations = const [];
  List<LabelMatch> _matches = const [];
  List<String> _canonicalTags = const [];

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

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final contentType = _contentTypeForPath(image.path);

    setState(() {
      _imageBytes = bytes;
      _imageContentType = contentType;
      _observations = const [];
      _matches = const [];
      _canonicalTags = const [];
    });

    await _analyzeImage(image);
  }

  Future<void> _analyzeImage(XFile image) async {
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

      if (!mounted) {
        return;
      }

      setState(() {
        _observations = observations;
        _matches = matches;
        _canonicalTags = tags;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Labeling failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _analyzing = false;
        });
      }
    }
  }

  Future<void> _sendFeed() async {
    final imageBytes = _imageBytes;
    final imageContentType = _imageContentType;
    if (imageBytes == null || imageContentType == null) {
      setState(() {
        _error = 'Select an image first.';
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
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
      Supabase.instance.client.functions.setAuth(session.accessToken);

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

      final dataUri =
          'data:$imageContentType;base64,${base64Encode(imageBytes)}';
      final caption = _captionController.text.trim();

      final response = await Supabase.instance.client.functions.invoke(
        'feed_validate',
        body: {
          'room_id': widget.roomId,
          'labels': labelsPayload,
          'canonical_tags': _canonicalTags,
          'caption': caption.isEmpty ? null : caption,
          'image_base64': dataUri,
          'image_content_type': imageContentType,
          'client_created_at': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = jsonEncode({
          'status': response.status,
          'data': response.data,
        });
      });
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
          if (_imageBytes != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _imageBytes!,
                height: 240,
                fit: BoxFit.cover,
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
            onPressed: _sending ? null : _sendFeed,
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
