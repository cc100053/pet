import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `leave_room` raised `not_member` when the caller had no active membership,
/// so a stale client — one relaunched after a background termination with a
/// room list that still shows a room it already left — turned a redundant
/// leave into a "leave failed / permission denied" toast
/// (Crashlytics `f4438f674b044c57fa149a1c26ea60d6`, first seen 3.0.2).
void main() {
  final migration = File(
    'supabase/migrations/20260903120000_make_leave_room_idempotent.sql',
  );

  String executableSql() => migration
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('--'))
      .join('\n');

  test('the migration exists and rewrites leave_room', () {
    expect(migration.existsSync(), isTrue);
    expect(
      migration.readAsStringSync(),
      contains('create or replace function public.leave_room(p_room_id uuid)'),
    );
  });

  test('leaving a room you are not in is no longer an error', () {
    // The comments name the exception they removed, so check executable SQL.
    expect(executableSql(), isNot(contains('not_member')));
  });

  test('an already-inactive membership is not re-stamped', () {
    // Without this filter the UPDATE would overwrite the original left_at
    // every time a stale client retried the leave.
    expect(executableSql(), contains('and is_active'));
  });

  test('the RPC contract old clients call is unchanged', () {
    final sql = executableSql();

    expect(sql, contains('returns void'));
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
    expect(sql, contains('grant execute on function public.leave_room(uuid)'));
    // Anonymous callers must still be rejected.
    expect(sql, contains("raise exception 'not_authenticated'"));
    // Owner demotion on leave is part of the contract, not the bug.
    expect(sql, contains("role = case when role = 'owner' then 'member'"));
  });
}
