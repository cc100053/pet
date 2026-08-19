import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the Crashlytics non-fatal where a transient network
/// failure during a room-decor reload replaced frames the user could already
/// see with an error banner.
///
/// Both loaders are re-run by the `room_backgrounds` / `room_background_state`
/// realtime callbacks, so most calls are revalidations rather than first loads.
/// This is the same defect `_refreshPetState` had, and — like the neighbouring
/// Home tests — it asserts on the source, because these methods live in an
/// extension on a `_HomeViewState` that needs a live Supabase client to pump.
void main() {
  String loaderBody(String name) {
    final source = File(
      'lib/features/home/home_view_room_decor.dart',
    ).readAsStringSync();
    final body =
        RegExp(
          'Future<void> $name'
          r'\(String roomId\) async \{([\s\S]*?)\n  \}',
          multiLine: true,
        ).firstMatch(source)?.group(1) ??
        '';
    expect(body, isNotEmpty, reason: '$name should be findable');
    return body;
  }

  const loaders = {
    '_loadRoomBackgrounds': (
      guard: '_ownedBackgroundsByRoom.containsKey(roomId)',
      source: 'home_load_room_backgrounds',
    ),
    '_loadRoomBackgroundState': (
      guard: '_activeBackgroundByRoom.containsKey(roomId)',
      source: 'home_load_room_background_state',
    ),
  };

  for (final entry in loaders.entries) {
    final name = entry.key;
    final guard = entry.value.guard;
    final source = entry.value.source;

    group(name, () {
      test('a failed reload keeps decor the user can already see', () {
        final body = loaderBody(name);

        // The guard must come before the error is rendered, otherwise the
        // banner still wins.
        final guardIndex = body.indexOf(guard);
        final errorIndex = body.indexOf('shopLoadFailed');

        expect(guardIndex, greaterThan(-1));
        expect(errorIndex, greaterThan(-1));
        expect(guardIndex, lessThan(errorIndex));
      });

      test('a swallowed reload failure is still reported', () {
        final body = loaderBody(name);

        // Degrading silently in the UI must not mean degrading silently in
        // Crashlytics.
        expect(body, contains('reportSwallowedError'));
        expect(body, contains("source: '$source',"));
        expect(body, contains('catch (error, stackTrace)'));
      });

      test('a first load with nothing to show still surfaces the error', () {
        final body = loaderBody(name);

        // The early return must be conditional; an unconditional one would
        // hide genuine failures on a cold room entry.
        expect(body, contains('if ($guard) {'));
        expect(
          body,
          contains('shopLoadFailed(userFacingError(context, error))'),
        );
      });

      test('a successful load retires a stale error banner', () {
        final body = loaderBody(name);

        // Without this, a banner from a failed cold load outlives the retry
        // that fixed it and sits next to fully loaded decor.
        final clearIndex = body.indexOf('_backgroundError = null;');
        final catchIndex = body.indexOf('} catch (error, stackTrace) {');

        expect(clearIndex, greaterThan(-1));
        expect(catchIndex, greaterThan(-1));
        expect(
          clearIndex,
          lessThan(catchIndex),
          reason: 'the clear belongs on the success path',
        );
      });
    });
  }
}
