import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_sender_name_visibility.dart';

ChatMessage _message({
  required String id,
  required String? senderId,
  String type = 'text',
  DateTime? createdAt,
  DateTime? deletedAt,
}) {
  return ChatMessage(
    id: id,
    roomId: 'room',
    senderId: senderId,
    type: type,
    body: 'body',
    imageUrl: null,
    caption: null,
    coinsAwarded: 0,
    createdAt: createdAt ?? DateTime(2026, 8, 4, 10),
    clientCreatedAt: null,
    labels: const <Map<String, dynamic>>[],
    localImagePath: null,
    deletedAt: deletedAt,
  );
}

void main() {
  group('senderNameVisibleMessageIds', () {
    test('names only the first bubble of a consecutive text run', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(id: 'a2', senderId: 'a'),
        _message(id: 'a3', senderId: 'a'),
      ]);

      expect(ids, {'a1'});
    });

    test('restarts the run after a system message from the same user', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(id: 'sys', senderId: 'a', type: 'system'),
        _message(id: 'a2', senderId: 'a'),
        _message(id: 'a3', senderId: 'a'),
      ]);

      expect(ids, {'a1', 'a2'});
      expect(ids, isNot(contains('sys')));
    });

    test('always names a feed photo, even mid-run', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(id: 'photo', senderId: 'a', type: 'image_feed'),
      ]);

      expect(ids, {'a1', 'photo'});
    });

    test('names a feed photo that follows a system message', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'sys', senderId: 'a', type: 'system'),
        _message(id: 'photo', senderId: 'a', type: 'image_feed'),
      ]);

      expect(ids, {'photo'});
    });

    test('a recalled photo follows the normal grouping rules', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(
          id: 'recalled',
          senderId: 'a',
          type: 'image_feed',
          deletedAt: DateTime(2026, 8, 4, 10, 1),
        ),
      ]);

      expect(ids, {'a1'});
    });

    test('names again once the grouping timeout lapses', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a', createdAt: DateTime(2026, 8, 4, 10)),
        _message(
          id: 'a2',
          senderId: 'a',
          createdAt: DateTime(2026, 8, 4, 10, 6),
        ),
      ]);

      expect(ids, {'a1', 'a2'});
    });

    test('names every sender change and every new local day', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(id: 'b1', senderId: 'b'),
        _message(id: 'b2', senderId: 'b'),
        _message(id: 'b3', senderId: 'b', createdAt: DateTime(2026, 8, 5, 9)),
      ]);

      expect(ids, {'a1', 'b1', 'b3'});
    });

    test('a freshly loaded history boundary always restarts the group', () {
      final ids = senderNameVisibleMessageIds([
        _message(id: 'a1', senderId: 'a'),
        _message(id: 'a2', senderId: 'a'),
      ], historyGroupingBoundaryMessageId: 'a2');

      expect(ids, {'a1', 'a2'});
    });
  });
}
