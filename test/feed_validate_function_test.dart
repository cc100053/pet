import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const functionPath =
      'supabase/functions/notify_friend/feed_validate/index.ts';

  late String source;

  setUpAll(() {
    source = File(functionPath).readAsStringSync();
  });

  test('feed validate returns before partner notification completes', () {
    expect(source, contains('function queueBackgroundTask'));
    expect(source, contains('EdgeRuntime'));
    expect(source, contains('waitUntil(guardedTask)'));
    expect(source, contains('webhook_queued: webhookQueued'));
    expect(source, contains('webhook_skipped: false'));
    expect(
      source,
      isNot(contains('const webhookResult = await notifyPartner')),
    );
  });

  test('feed validate logs response and notification timings separately', () {
    expect(source, contains('[feed_validate] response_ready'));
    expect(source, contains('process_feed_duration_ms: processFeedDurationMs'));
    expect(source, contains('[feed_validate] notify_partner_complete'));
  });
}
