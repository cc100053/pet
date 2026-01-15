import 'package:flutter_test/flutter_test.dart';

import 'package:pet/services/label_mapping/label_mapping_service.dart';

void main() {
  test('normalizeLabel trims, lowercases, and removes punctuation', () {
    final normalized = LabelMappingService.normalizeLabel(' Ice  Cream!! ');
    expect(normalized, 'ice cream');
  });

  test('matchLabels honors confidence and priority', () {
    final service = LabelMappingService([
      const LabelMappingEntry(
        label: 'Cup',
        canonicalTag: 'beverage.coffee',
        priority: -1,
      ),
      const LabelMappingEntry(
        label: 'Cup',
        canonicalTag: 'beverage.tea',
        priority: 2,
      ),
      const LabelMappingEntry(
        label: 'Coffee',
        canonicalTag: 'beverage.coffee',
        priority: 0,
      ),
    ]);

    final matches = service.matchLabels([
      const LabelObservation(text: 'Cup', confidence: 0.9),
      const LabelObservation(text: 'Coffee', confidence: 0.5),
      const LabelObservation(text: 'Coffee', confidence: 0.8),
    ]);

    expect(matches.length, 2);
    expect(matches.first.canonicalTag, 'beverage.tea');
    expect(matches.last.canonicalTag, 'beverage.coffee');
  });

  test('matchCanonicalTags de-duplicates tags', () {
    final service = LabelMappingService([
      const LabelMappingEntry(
        label: 'Coffee',
        canonicalTag: 'beverage.coffee',
        priority: 0,
      ),
      const LabelMappingEntry(
        label: 'Latte',
        canonicalTag: 'beverage.coffee',
        priority: 0,
      ),
    ]);

    final tags = service.matchCanonicalTags([
      const LabelObservation(text: 'Coffee', confidence: 0.9),
      const LabelObservation(text: 'Latte', confidence: 0.9),
    ]);

    expect(tags, ['beverage.coffee']);
  });
}
