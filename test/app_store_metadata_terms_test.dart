import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  const locales = <String>['en-US', 'ja', 'ko', 'zh-Hant'];

  test('App Store version descriptions include the direct EULA link', () {
    for (final locale in locales) {
      final path = '.asc/version-localizations/$locale.strings';
      final raw = File(path).readAsStringSync();
      final description = _stringValue(raw, 'description');

      expect(
        description,
        contains('EULA'),
        reason: '$path must label the Terms of Use as the EULA for review.',
      );
      expect(
        description,
        contains(appleStandardEulaUrl),
        reason: '$path must include the direct Apple Standard EULA URL.',
      );
    }
  });
}

String _stringValue(String raw, String key) {
  final match = RegExp(
    '"$key"\\s*=\\s*"((?:\\\\.|[^"\\\\])*)";',
    dotAll: true,
  ).firstMatch(raw);
  if (match == null) {
    throw StateError('Missing "$key" in .strings content.');
  }
  return match.group(1)!.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
}
