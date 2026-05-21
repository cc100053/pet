import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260521143000_add_room_hunger_freeze_debug_override.sql';
  const conflictFixMigrationPath =
      'supabase/migrations/20260521150000_fix_room_hunger_freeze_room_id_conflict.sql';

  test('room hunger freeze migration is room-scoped and admin-gated', () {
    final migration = File(migrationPath).readAsStringSync();

    expect(
      migration,
      contains('create table if not exists public.room_debug_overrides'),
    );
    expect(
      migration,
      contains('room_id uuid primary key references public.rooms(id)'),
    );
    expect(
      migration,
      contains(
        'alter table public.room_debug_overrides enable row level security',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on table public.room_debug_overrides from public, anon, authenticated',
      ),
    );
    expect(
      migration,
      contains('create or replace function public.is_debug_admin()'),
    );
    expect(migration, contains('if not public.is_debug_admin() then'));
    expect(migration, contains("raise exception 'not_debug_admin'"));
    expect(migration, contains('if not public.is_room_member(p_room_id) then'));
  });

  test('frozen rooms do not accumulate catch-up hunger decay', () {
    final migration = File(migrationPath).readAsStringSync();

    final tickFunction = RegExp(
      r'create or replace function public\.tick_pet_state\([\s\S]*?\$function\$;',
      multiLine: true,
    ).firstMatch(migration)!.group(0)!;

    expect(tickFunction, contains('v_hunger_decay_paused := exists'));
    expect(tickFunction, contains('rdo.hunger_decay_paused_until > p_now'));
    expect(tickFunction, contains('if v_hunger_decay_paused then'));
    expect(tickFunction, contains('set hunger = v_hunger,'));
    expect(tickFunction, contains('last_decay_at = p_now,'));
    expect(tickFunction, contains('return;'));
  });

  test('hunger schedule sleeps until the room freeze expires', () {
    final migration = File(migrationPath).readAsStringSync();

    final computeFunction = RegExp(
      r'create or replace function public\.compute_pet_hunger_next_check_at\([\s\S]*?end;\s*\$\$;',
      multiLine: true,
    ).firstMatch(migration)!.group(0)!;

    expect(computeFunction, contains('v_hunger_decay_paused_until'));
    expect(computeFunction, contains('rdo.hunger_decay_paused_until > p_now'));
    expect(computeFunction, contains('return v_hunger_decay_paused_until;'));
  });

  test('freeze RPC avoids room_id output-column conflict in upsert', () {
    final migration = File(conflictFixMigrationPath).readAsStringSync();

    final freezeFunction = RegExp(
      r'create or replace function public\.set_room_hunger_decay_paused\([\s\S]*?end;\s*\$\$;',
      multiLine: true,
    ).firstMatch(migration)!.group(0)!;

    expect(freezeFunction, isNot(contains('on conflict (room_id)')));
    expect(
      freezeFunction,
      contains('on conflict on constraint room_debug_overrides_pkey do update'),
    );
  });
}
