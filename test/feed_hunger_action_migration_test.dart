import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260607005751_anchor_decay_after_pet_action.sql';
  const grantMigrationPath =
      'supabase/migrations/20260607005904_restrict_apply_pet_action_execute.sql';

  String applyPetActionFunction() {
    final migration = File(migrationPath).readAsStringSync();
    return RegExp(
      r'create or replace function public\.apply_pet_action\([\s\S]*?\$function\$;',
      multiLine: true,
    ).firstMatch(migration)!.group(0)!;
  }

  test('successful feed anchors passive hunger decay at feed time', () {
    final function = applyPetActionFunction();

    expect(function, contains('v_anchor_decay_after_feed boolean := false'));
    expect(function, contains('v_anchor_decay_after_feed := true;'));
    expect(function, contains('when v_anchor_decay_after_feed then v_now'));
  });

  test('feed decay anchor is mirrored to room pet state', () {
    final function = applyPetActionFunction();
    final roomPetStateUpdate = RegExp(
      r'update public\.room_pet_state[\s\S]*?where room_id = v_room_id;',
      multiLine: true,
    ).firstMatch(function)!.group(0)!;

    expect(roomPetStateUpdate, contains('last_decay_at = case'));
    expect(
      roomPetStateUpdate,
      contains('when v_anchor_decay_after_feed then v_now'),
    );
  });

  test('apply pet action remains authenticated-only through Data API', () {
    final migration = File(grantMigrationPath).readAsStringSync();

    expect(
      migration,
      contains(
        'revoke all on function public.apply_pet_action(uuid, text)\n'
        '  from public, anon, authenticated;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.apply_pet_action(uuid, text)\n'
        '  to authenticated;',
      ),
    );
  });
}
