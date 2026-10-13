import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Home's private part extension needs live app state; guard the RPC wiring
  // here and exercise authorization/arithmetic in the transactional SQL test.
  final source = File(
    'lib/features/home/home_view_debug.dart',
  ).readAsStringSync().split('Future<void> _debugAdjustPetHunger').first;

  test('debug balances use the admin RPC instead of protected columns', () {
    expect(source, contains("'debug_adjust_profile_balances'"));
    expect(source, contains("'p_coin_delta': coinDelta"));
    expect(source, contains("'p_diamond_delta': diamondDelta"));
    expect(source, isNot(contains(".from('profiles')")));
    expect(source, contains('_ensureDebugAdminAccess()'));
    expect(source, contains('_ensureOnlineForWrite()'));
    expect(source, contains('await _loadCoins('));
  });

  test('debug balance failures are shown and reported', () {
    expect(source, contains('catch (error, stackTrace)'));
    expect(source, contains('showJuiceSnackbar('));
    expect(source, contains('userFacingError('));
    expect(source, contains("source: 'home_debug_update_profile_balances'"));
  });
}
