import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 2: notify_friend was split out of a single ~1300-line file into
/// cohesive modules (`l10n.ts`, `pets.ts`) plus the shared http/auth helpers,
/// with the orchestration left in `index.ts`. This is a behavior-preserving
/// refactor — these source-level checks guard the split and the deliberate
/// tiger-avatar fallback that must NOT be "fixed".
void main() {
  String read(String path) =>
      File('supabase/functions/notify_friend/$path').readAsStringSync();

  final index = read('index.ts');
  final l10n = read('l10n.ts');
  final pets = read('pets.ts');

  test('index.ts imports the extracted modules and shared helpers', () {
    expect(index, contains('from "../_shared/http.ts"'));
    expect(index, contains('from "../_shared/auth.ts"'));
    expect(index, contains('from "./pets.ts"'));
    expect(index, contains('from "./l10n.ts"'));
  });

  test('the moved data/tables no longer live in index.ts', () {
    expect(index, isNot(contains('const localizedStoreItemNames')));
    expect(index, isNot(contains('const l10n')));
    expect(index, isNot(contains('PET_AVATAR_URL_BY_TYPE: Record')));
    expect(index, isNot(contains('function getL10n')));
    expect(index, isNot(contains('function normalizeLocale')));
    // The orchestration + FCM path stays in index.ts.
    expect(index, contains('serve(async (req)'));
    expect(index, contains('function getAccessToken'));
  });

  test('l10n module exports the accessors index needs', () {
    expect(l10n, contains('export function getL10n'));
    expect(l10n, contains('export function localizedAppName'));
    expect(l10n, contains('export function localizedStoreItemName'));
    // All five push locales are preserved.
    for (final key in ['en:', 'ja:', 'ko:', 'zh:', '"zh-TW":']) {
      expect(l10n, contains(key));
    }
  });

  test('pets module keeps the deliberate tiger -> ghost avatar fallback', () {
    expect(pets, contains('export const PET_AVATAR_URL_BY_TYPE'));
    expect(pets, contains('export function extractPetType'));
    // tiger has no published gif (R2 404); it must still point at ghost_stay.
    final tigerLine = pets
        .split('\n')
        .skipWhile((l) => !l.trimLeft().startsWith('tiger:'))
        .take(2)
        .join('\n');
    expect(tigerLine, contains('ghost_stay.gif'));
    expect(pets, contains('verified 404'));
  });
}
