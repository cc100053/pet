import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `pg_timezone_names` re-reads the whole IANA tz database on every scan
/// (~792 ms measured on this project). `tick_pet_state` probed it once per
/// call, which is what pushed the RPC into the `authenticated` role's 8 s
/// statement_timeout and surfaced as PostgrestException 57014 in Home.
void main() {
  final migration = File(
    'supabase/migrations/'
    '20260808130000_drop_pg_timezone_names_probe_from_tick_pet_state.sql',
  );

  test('the migration exists and rewrites tick_pet_state', () {
    expect(migration.existsSync(), isTrue);
    expect(
      migration.readAsStringSync(),
      contains('create or replace function public.tick_pet_state'),
    );
  });

  test('the rewritten function never scans pg_timezone_names', () {
    // The comments deliberately name the view they replaced, so check the
    // executable SQL rather than the whole file.
    final executableSql = migration
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');

    expect(executableSql, isNot(contains('pg_timezone_names')));
  });

  test('an unknown room timezone still falls back to UTC', () {
    final sql = migration.readAsStringSync();

    // `at time zone` raises 22023 for an unknown zone, so the exception block
    // is what preserves the old probe's fallback behavior.
    expect(sql, contains('exception'));
    expect(sql, contains('when others then'));
    expect(sql, contains("v_timezone := 'UTC'"));
    expect(sql, contains("p_now at time zone 'UTC'"));
  });

  test('the RPC contract old clients call is unchanged', () {
    final sql = migration.readAsStringSync();

    // Released builds call this with exactly these params; a signature or
    // return-type change would break them immediately.
    expect(sql, contains('p_pet_id uuid'));
    expect(sql, contains('p_now timestamp with time zone'));
    expect(sql, contains('returns void'));
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
  });

  test('both pet_state and room_pet_state are still written', () {
    final sql = migration.readAsStringSync();

    // Multi-pet v2 keeps `room_pet_state` in sync with the canonical row; a
    // rewrite that dropped one of the two updates would desync old clients.
    expect(sql, contains('update public.pet_state'));
    expect(sql, contains('update public.room_pet_state'));
    expect(sql, contains('public.compute_pet_mood'));
    expect(sql, contains('room_debug_overrides'));
  });
}
