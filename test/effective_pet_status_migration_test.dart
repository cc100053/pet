import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260715164256_add_effective_room_pet_status_rpc.sql',
  ).readAsStringSync();

  test('effective pet status RPC is additive, read-only, and RLS scoped', () {
    expect(
      migration,
      contains(
        'create or replace function public.get_effective_room_pet_statuses',
      ),
    );
    expect(migration, contains('security invoker'));
    expect(migration, contains('stable'));
    expect(migration, contains('join public.room_pet_state'));
    expect(migration, contains('rm.user_id = (select auth.uid())'));
    expect(migration, contains('rm.is_active'));
    expect(migration, isNot(contains('update public.pet_state')));
    expect(migration, isNot(contains('tick_pet_state(')));
  });

  test('server computes hunger using room timezone and current mood rules', () {
    expect(migration, contains('pg_timezone_names'));
    expect(migration, contains('public.compute_pet_mood'));
    expect(migration, contains('effective_hunger'));
    expect(migration, contains('statement_timestamp()'));
  });

  test('only authenticated clients can execute the new RPC', () {
    expect(
      migration,
      contains(
        'revoke all on function public.get_effective_room_pet_statuses(uuid[])',
      ),
    );
    expect(migration, contains('from public, anon'));
    expect(
      migration,
      contains(
        'grant execute on function public.get_effective_room_pet_statuses(uuid[])',
      ),
    );
    expect(migration, contains('to authenticated'));
  });
}
