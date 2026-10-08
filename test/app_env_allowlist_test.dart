import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every bundled asset ships to users in plain text, so the bundled env file
// must hold exactly the public keys the app reads, never server secrets.
Set<String> _scriptAllowlist() {
  final script = File('scripts/write_app_env.sh').readAsStringSync();
  final block = RegExp(r'ALLOWED_KEYS=\(([^)]*)\)').firstMatch(script)!;
  return block
      .group(1)!
      .split(RegExp(r'\s+'))
      .where((k) => k.isNotEmpty)
      .toSet();
}

void main() {
  test('allowlist matches the keys Env reads', () {
    final env = File('lib/services/env.dart').readAsStringSync();
    final read = RegExp(
      r"_(?:require|optional|optionalInt|optionalBool)\('([A-Z0-9_]+)'\)",
    ).allMatches(env).map((m) => m.group(1)!).toSet();
    expect(_scriptAllowlist(), read);
  });

  test('the bundled env asset is .env.app, never .env', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync().map((l) => l.trim());
    expect(pubspec, contains('- .env.app'));
    expect(pubspec, isNot(contains('- .env')));
  });

  test('a generated .env.app holds only allowlisted keys', () {
    final file = File('.env.app');
    if (!file.existsSync()) {
      markTestSkipped('.env.app not generated in this checkout');
      return;
    }
    final keys = file
        .readAsLinesSync()
        .where((l) => l.contains('=') && !l.trimLeft().startsWith('#'))
        .map((l) => l.split('=').first.trim())
        .toSet();
    expect(_scriptAllowlist().containsAll(keys), isTrue, reason: '$keys');
  });
}
