import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `pg_timezone_names` re-reads the whole IANA tz database on every scan
/// (~792 ms measured on this project). Seven functions probed it; this covers
/// the six cleaned up after `tick_pet_state`.
void main() {
  final migration = File(
    'supabase/migrations/'
    '20260808150000_drop_pg_timezone_names_probes_from_remaining_functions.sql',
  );

  late String sql;
  late String executableSql;

  setUpAll(() {
    sql = migration.readAsStringSync();
    executableSql = migration
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');
  });

  test('the migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('no executable SQL scans pg_timezone_names', () {
    expect(executableSql, isNot(contains('pg_timezone_names')));
  });

  test('every probing function is rewritten', () {
    for (final function in const <String>[
      'apply_pet_action',
      'apply_room_pet_action',
      'compute_pet_hunger_next_check_at',
      'create_room',
      'ensure_room_owner',
      'get_effective_room_pet_statuses',
    ]) {
      expect(
        sql,
        contains('create or replace function public.$function'),
        reason: function,
      );
    }
  });

  test('the shared fallback still resolves an unknown zone to UTC', () {
    expect(
      sql,
      contains('create or replace function public.normalize_timezone'),
    );
    // `at time zone` raises 22023 for an unknown zone; the handler is what
    // preserves the old probe's fallback.
    expect(sql, contains('when others then'));
    expect(sql, contains("return 'UTC'"));
    // A literal instant rather than now(), so the function stays STABLE.
    expect(sql, contains("timestamptz '2000-01-01 00:00:00+00' at time zone"));
    expect(sql, isNot(contains('perform now() at time zone')));
  });

  test('the fallback is not reachable by anon', () {
    expect(
      sql,
      contains(
        'revoke all on function public.normalize_timezone(text) '
        'from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.normalize_timezone(text) '
        'to authenticated, service_role',
      ),
    );
  });

  test('every rewritten RPC keeps the contract old clients call', () {
    // A signature, return-type, or security-mode change here would break
    // already-installed builds immediately.
    expect(
      sql,
      contains('public.apply_pet_action(p_pet_id uuid, p_action_type text)'),
    );
    expect(
      sql,
      contains(
        'public.apply_room_pet_action(p_room_id uuid, p_action_type text)',
      ),
    );
    expect(sql, contains('public.create_room(p_name text)'));
    expect(sql, contains('returns table(room_id uuid, invite_code text)'));
    expect(
      sql,
      contains('public.get_effective_room_pet_statuses(p_room_ids uuid[])'),
    );
    expect(sql, contains('returns trigger'));

    // `create or replace` preserves grants; a drop/create would silently reset
    // the tightened apply_pet_action ACL from 20260607005904.
    expect(sql, isNot(contains('drop function')));
  });

  test(
    'get_effective_room_pet_statuses stays a STABLE sql invoker function',
    () {
      final body = sql.split('public.get_effective_room_pet_statuses').last;
      expect(body, contains('language sql'));
      expect(body, contains('stable'));
      // SECURITY INVOKER is what keeps room RLS governing this read.
      expect(body, isNot(contains('security definer')));
    },
  );
}
