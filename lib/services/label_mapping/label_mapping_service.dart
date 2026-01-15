import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

class LabelMappingEntry {
  const LabelMappingEntry({
    required this.label,
    required this.canonicalTag,
    required this.priority,
  });

  factory LabelMappingEntry.fromJson(JsonMap json) {
    return LabelMappingEntry(
      label: (json['label_en'] as String?)?.trim() ?? '',
      canonicalTag: (json['canonical_tag'] as String?)?.trim() ?? '',
      priority: (json['priority'] as int?) ?? 0,
    );
  }

  final String label;
  final String canonicalTag;
  final int priority;
}

class LabelObservation {
  const LabelObservation({required this.text, required this.confidence});

  final String text;
  final double confidence;
}

class LabelMatch {
  const LabelMatch({
    required this.text,
    required this.confidence,
    required this.canonicalTag,
  });

  final String text;
  final double confidence;
  final String canonicalTag;
}

class LabelMappingRepository {
  const LabelMappingRepository(this._client);

  final SupabaseClient _client;

  Future<List<LabelMappingEntry>> fetch({String? locale}) async {
    final query = _client.from('label_mappings').select(
          'label_en, canonical_tag, priority',
        );

    final response = locale == null
        ? await query
        : await query.eq('locale', locale);

    return response
        .map((row) => LabelMappingEntry.fromJson(row))
        .where((entry) => entry.label.isNotEmpty)
        .toList();
  }
}

class LabelMappingService {
  LabelMappingService(List<LabelMappingEntry> entries)
      : _entries = entries {
    for (final entry in entries) {
      if (entry.label.isEmpty || entry.canonicalTag.isEmpty) {
        continue;
      }
      final key = normalizeLabel(entry.label);
      final existing = _bestByLabel[key];
      if (existing == null || entry.priority > existing.priority) {
        _bestByLabel[key] = entry;
      }
    }
  }

  final List<LabelMappingEntry> _entries;
  final Map<String, LabelMappingEntry> _bestByLabel = {};

  List<LabelMatch> matchLabels(
    List<LabelObservation> labels, {
    double minConfidence = 0.6,
  }) {
    final matches = <LabelMatch>[];

    for (final label in labels) {
      if (label.confidence < minConfidence) {
        continue;
      }
      final key = normalizeLabel(label.text);
      final mapping = _bestByLabel[key];
      if (mapping == null) {
        continue;
      }
      matches.add(
        LabelMatch(
          text: label.text,
          confidence: label.confidence,
          canonicalTag: mapping.canonicalTag,
        ),
      );
    }

    return matches;
  }

  List<String> matchCanonicalTags(
    List<LabelObservation> labels, {
    double minConfidence = 0.6,
  }) {
    final matches = matchLabels(labels, minConfidence: minConfidence);
    final seen = <String>{};
    final tags = <String>[];
    for (final match in matches) {
      if (seen.add(match.canonicalTag)) {
        tags.add(match.canonicalTag);
      }
    }
    return tags;
  }

  static String normalizeLabel(String text) {
    final trimmed = text.trim().toLowerCase();
    final cleaned = trimmed.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<LabelMappingEntry> get entries => List.unmodifiable(_entries);
}
