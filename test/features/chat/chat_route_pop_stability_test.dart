import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the route-pop crash seen after browsing old chat history, jumping to
/// latest, then leaving the room.
///
/// The first failure in the captured log was Flutter's "Duplicate keys found"
/// from an `AnimatedSwitcher` layout stack. Once the tree was in that bad
/// state, popping the chat route cascaded into `_dependents.isEmpty` /
/// "wrong build scope" deactivation assertions. Keep the load-more overlay out
/// of `AnimatedSwitcher`; insert it only while loading.
void main() {
  final viewSource = File(
    'lib/features/chat/chat_room_view_v2.dart',
  ).readAsStringSync();

  test('chat route loading overlay avoids AnimatedSwitcher duplicate keys', () {
    expect(viewSource, isNot(contains('AnimatedSwitcher(')));
    expect(viewSource, contains('if (_loadingMore)'));
    expect(viewSource, contains("ValueKey('chatHistoryLoadOverlay')"));
  });
}
