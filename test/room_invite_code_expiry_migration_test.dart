import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/'
    '20260730120037_standardize_room_invite_codes_to_24_hours.sql',
  ).readAsStringSync();

  test('all first-party invite creation paths default to 24 hours', () {
    expect(
      RegExp(
        r'p_expires_in_minutes int default 1440',
      ).allMatches(migration).length,
      2,
    );
    expect(
      migration,
      contains("v_expires_at timestamptz := now() + interval '24 hours'"),
    );
    expect(
      migration,
      contains('return public.create_room_invite_code(p_room_id, 1440);'),
    );
  });

  test('existing active codes receive a bounded 24-hour transition', () {
    expect(
      migration,
      contains(
        "set expires_at = least(expires_at, now() + interval '24 hours')",
      ),
    );
    expect(
      migration,
      contains("coalesce(invite_expires_at, now() + interval '24 hours')"),
    );
  });

  test('migration keeps reusable unlimited-join contract unchanged', () {
    expect(migration, isNot(contains('join_room_by_code')));
    expect(migration, isNot(contains('max_uses')));
    expect(migration, isNot(contains('use_count')));
    expect(migration, isNot(contains('used_at')));
  });
}
