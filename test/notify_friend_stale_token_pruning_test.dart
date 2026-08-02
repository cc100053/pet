import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FCM HTTP v1 pretty-prints its error JSON, so it returns
/// `"errorCode": "UNREGISTERED"` with a space after the colon. The original
/// matcher looked for the compact `"errorCode":"UNREGISTERED"` shape and for
/// legacy/Admin-SDK strings, so it never fired against the live API and dead
/// tokens were retried indefinitely instead of being pruned.
void main() {
  final index = File(
    'supabase/functions/notify_friend/index.ts',
  ).readAsStringSync();

  test('staleness is decided from the structured errorCode field', () {
    expect(index, contains('function parseFcmErrorPayload('));
    expect(index, contains('code.toUpperCase() === "UNREGISTERED"'));
  });

  test('legacy substring fallback is whitespace-insensitive', () {
    // Without the strip, the pretty-printed body cannot match the compact
    // patterns kept for older/proxied error shapes.
    expect(
      index,
      contains('(errorText ?? "").toLowerCase().replace(/\\s+/g, "")'),
    );
  });

  test('INVALID_ARGUMENT must never prune tokens', () {
    // A malformed message also returns 400, so treating it as staleness would
    // let a single bad payload delete every recipient's registration.
    expect(index, isNot(contains('INVALID_ARGUMENT"')));
    expect(index, contains('INVALID_ARGUMENT is deliberately NOT treated'));
  });

  test('pruning still runs off isStaleTokenFailure at the send site', () {
    expect(index, contains('.filter((f) => isStaleTokenFailure(f.error))'));
    expect(index, contains('.from("device_tokens")\n      .delete()'));
  });
}
