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

  test('feed validate returns authoritative post-feed pet state (additive)', () {
    // Reads the committed room-shared state and returns it so clients no longer
    // depend on a racy realtime/refetch to learn the new satiety value.
    expect(source, contains('.from("room_pet_state")'));
    expect(source, contains('last_decay_at'));
    expect(source, contains('pet_state: feedPetState'));
    expect(source, contains('overfed: feedOverfed'));
    // Backward-compatible: existing response fields must stay present + typed.
    expect(source, contains('coins_awarded: totalReward'));
    expect(source, contains('reward_status: rewardStatus'));
    expect(source, contains('webhook_skipped: false'));
    expect(source, contains('is_active: cooldownIsActive'));
  });
}
