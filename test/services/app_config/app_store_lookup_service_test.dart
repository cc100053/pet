import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/app_config/app_store_lookup_service.dart';

void main() {
  test('parses App Store lookup response', () {
    const body = '''
{
  "resultCount": 1,
  "results": [
    {
      "version": "1.0.3",
      "trackViewUrl": "https://apps.apple.com/jp/app/id6757725650"
    }
  ]
}
''';

    final result = AppStoreVersionLookupService.parseLookupResponse(
      body,
      fallbackStoreUrl: 'https://apps.apple.com/app/id6757725650',
    );

    expect(result, isNotNull);
    expect(result!.version, '1.0.3');
    expect(result.storeUrl, 'https://apps.apple.com/jp/app/id6757725650');
  });

  test('falls back to default store URL when lookup omits trackViewUrl', () {
    const body = '''
{
  "resultCount": 1,
  "results": [
    {
      "version": "1.0.3"
    }
  ]
}
''';

    final result = AppStoreVersionLookupService.parseLookupResponse(
      body,
      fallbackStoreUrl: 'https://apps.apple.com/app/id6757725650',
    );

    expect(result, isNotNull);
    expect(result!.storeUrl, 'https://apps.apple.com/app/id6757725650');
  });
}
