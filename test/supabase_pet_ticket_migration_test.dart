import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pet-ticket RPC migration avoids pet_id output-column conflict', () {
    final migration = File(
      'supabase/migrations/20260519002602_fix_pet_ticket_pet_id_conflict.sql',
    ).readAsStringSync();

    final petTicketFunctions = RegExp(
      r'create or replace function public\.(?:use_pet_ticket|purchase_and_use_pet_ticket)\([\s\S]*?end;\s*\$\$;',
      multiLine: true,
    ).allMatches(migration).map((match) => match.group(0)!).toList();

    expect(petTicketFunctions, hasLength(2));
    for (final functionSql in petTicketFunctions) {
      expect(functionSql, isNot(contains('on conflict (pet_id)')));
      expect(
        functionSql,
        contains('on conflict on constraint pet_state_pkey do nothing'),
      );
    }
  });
}
