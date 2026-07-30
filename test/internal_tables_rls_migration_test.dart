import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/'
    '20260730143024_enable_rls_on_internal_scheduler_and_cleanup_tables.sql',
  ).readAsStringSync();

  test('enables RLS on both internal service-only tables', () {
    expect(
      migration,
      contains(
        'alter table public.pet_hunger_tick_schedule '
        'enable row level security;',
      ),
    );
    expect(
      migration,
      contains(
        'alter table public.room_cleanup_candidates '
        'enable row level security;',
      ),
    );
  });

  test('keeps client roles denied without adding policies', () {
    expect(
      RegExp(r'revoke all on table public\.').allMatches(migration).length,
      2,
    );
    expect(migration, contains('from public, anon, authenticated;'));
    expect(migration, isNot(contains('create policy')));
    expect(migration, isNot(contains('force row level security')));
    expect(migration, isNot(matches(RegExp(r'^\s*grant\s', multiLine: true))));
  });
}
