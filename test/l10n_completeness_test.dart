import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Missing keys silently fall back to English (or zh for zh_TW) at runtime,
// and duplicate keys silently keep only the last value. Catch both here.
void main() {
  final dir = Directory('lib/l10n');
  final arbs = dir.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.arb'),
  );

  List<String> keysOf(File f) {
    final keys = <String>[];
    // Duplicate keys are invisible to jsonDecode; read the raw key lines.
    for (final line in f.readAsLinesSync()) {
      final match = RegExp(r'^  "([^"@][^"]*)":').firstMatch(line);
      if (match != null) keys.add(match.group(1)!);
    }
    return keys;
  }

  final enKeys =
      (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>)
          .keys
          .where((k) => !k.startsWith('@'))
          .toSet();

  for (final arb in arbs) {
    final name = arb.uri.pathSegments.last;
    test('$name has no duplicate keys', () {
      final keys = keysOf(arb);
      final seen = <String>{};
      final dupes = keys.where((k) => !seen.add(k)).toSet();
      expect(dupes, isEmpty);
    });
    test('$name translates every English key', () {
      final missing = enKeys.difference(keysOf(arb).toSet());
      expect(missing, isEmpty);
    });
  }
}
