import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the Crashlytics non-fatal where a transient
/// `tick_pet_state` statement timeout (PostgrestException 57014) replaced a
/// perfectly good pet with an error banner.
///
/// `_refreshPetState` lives inside a very large `_HomeViewState` that needs a
/// live Supabase client to pump, so this asserts on the source at the seam the
/// same way the neighbouring Home tests do.
void main() {
  String refreshPetStateBody() {
    final source = File('lib/features/home/home_view.dart').readAsStringSync();
    final body =
        RegExp(
          // Step past the named-parameter list before capturing the body,
          // otherwise `}) async {` terminates the match immediately.
          r'Future<void> _refreshPetState\(\{[\s\S]*?\}\) async \{([\s\S]*?)\n  \}',
          multiLine: true,
        ).firstMatch(source)?.group(1) ??
        '';
    expect(body, isNotEmpty, reason: '_refreshPetState should be findable');
    return body;
  }

  test('a failed pet refresh keeps state the user can already see', () {
    final body = refreshPetStateBody();

    // The guard must come before the error is rendered, otherwise the banner
    // still wins.
    final guardIndex = body.indexOf('_petStateReady && _petState != null');
    final errorIndex = body.indexOf('petSyncFailed');

    expect(guardIndex, greaterThan(-1));
    expect(errorIndex, greaterThan(-1));
    expect(guardIndex, lessThan(errorIndex));
  });

  test('a swallowed pet refresh failure is still reported', () {
    final body = refreshPetStateBody();

    // Degrading silently in the UI must not mean degrading silently in
    // Crashlytics.
    expect(body, contains('reportSwallowedError'));
    expect(body, contains("source: 'home_refresh_pet_state'"));
    expect(body, contains('catch (error, stackTrace)'));
  });

  test('a first load with nothing to show still surfaces the error', () {
    final body = refreshPetStateBody();

    // The early return must be conditional; an unconditional one would hide
    // genuine failures on a cold room entry.
    expect(body, contains('if (_petStateReady && _petState != null) {'));
    expect(body, contains('petSyncFailed(userFacingError(context, error))'));
  });
}
