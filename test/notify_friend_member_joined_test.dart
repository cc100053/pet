import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// member_joined has no message row behind it. These pin the properties that
// keep it safe for spam and for installed clients that do not know the type.
void main() {
  final index = File(
    'supabase/functions/notify_friend/index.ts',
  ).readAsStringSync();
  final l10n = File(
    'supabase/functions/notify_friend/l10n.ts',
  ).readAsStringSync();

  test('only the joining user can send it, soon after joining', () {
    expect(index, contains('member_joined_requires_user'));
    expect(index, contains('memberJoinedWindowMs = 10 * 60 * 1000'));
    expect(index, contains('not_recent_join'));
  });

  test('sent once per keeper per room', () {
    expect(
      index,
      contains(r'payload.message_id = `member_joined:${senderId}`'),
    );
    expect(index, contains('if (isHungerAlert || isMemberJoined) {'));
  });

  test('devices get no message id to look up', () {
    expect(
      index,
      contains('message_id: isMemberJoined ? "" : payload.message_id'),
    );
  });

  test('every push locale has the joined copy', () {
    expect(RegExp(r'memberJoinedTemplate: "').allMatches(l10n).length, 5);
  });
}
