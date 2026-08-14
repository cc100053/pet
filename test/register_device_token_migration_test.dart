import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260802103000_add_register_device_token_rpc.sql',
  ).readAsStringSync();
  final fcmService = File('lib/services/fcm_service.dart').readAsStringSync();

  test('claims the token for the caller instead of trusting client input', () {
    // A client-supplied user_id would let any caller register a token against
    // someone else's account, which the definer rights would not stop.
    expect(migration, contains('v_user_id uuid := auth.uid();'));
    expect(migration, contains('set user_id = excluded.user_id'));
    expect(migration, isNot(contains('p_user_id')));
  });

  test('is definer-scoped, authenticated-only, and search_path pinned', () {
    expect(migration, contains('security definer'));
    // An unpinned search_path on a definer function is a privilege-escalation
    // vector and is flagged by Supabase advisors.
    expect(migration, contains('set search_path = public'));
    expect(
      migration,
      contains(
        'revoke all on function public.register_device_token(text, text, text)\n'
        '  from public, anon, authenticated;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.register_device_token(text, text, text)\n'
        '  to authenticated;',
      ),
    );
  });

  test('rejects unauthenticated and empty-token calls', () {
    expect(migration, contains("errcode = '42501'"));
    expect(migration, contains("errcode = '22023'"));
  });

  test('leaves the device_tokens policies untouched', () {
    // The whole point of the RPC is that table policies stay as strict as they
    // are today; a policy change here would silently widen client access.
    expect(migration, isNot(contains('create policy')));
    expect(migration, isNot(contains('alter policy')));
    expect(migration, isNot(contains('drop policy')));
  });

  test('client registers via the RPC but can still fall back', () {
    expect(
      fcmService,
      contains("_supabase.rpc(\n        'register_device_token'"),
    );
    // A build reaching a backend without the migration must not lose push
    // registration entirely.
    expect(fcmService, contains("error.code == 'PGRST202'"));
    expect(fcmService, contains("error.code == '42883'"));
    expect(fcmService, contains('_saveTokenViaLegacyUpsert'));
  });
}
