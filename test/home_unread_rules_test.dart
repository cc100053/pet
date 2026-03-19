import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_unread_rules.dart';

void main() {
  group('shouldIncrementHomeUnreadForIncomingMessage', () {
    test('does not increment unread for own image feed action', () {
      expect(
        shouldIncrementHomeUnreadForIncomingMessage(
          roomId: 'room-1',
          openChatRoomId: null,
          currentUserId: 'user-1',
          senderId: 'user-1',
        ),
        isFalse,
      );
    });

    test('does not increment unread for own system action', () {
      expect(
        shouldIncrementHomeUnreadForIncomingMessage(
          roomId: 'room-1',
          openChatRoomId: null,
          currentUserId: 'user-1',
          senderId: 'user-1',
        ),
        isFalse,
      );
    });

    test('does not increment unread when chat is already open for room', () {
      expect(
        shouldIncrementHomeUnreadForIncomingMessage(
          roomId: 'room-1',
          openChatRoomId: 'room-1',
          currentUserId: 'user-1',
          senderId: 'user-2',
        ),
        isFalse,
      );
    });

    test('increments unread for other user text and system messages', () {
      expect(
        shouldIncrementHomeUnreadForIncomingMessage(
          roomId: 'room-1',
          openChatRoomId: null,
          currentUserId: 'user-1',
          senderId: 'user-2',
        ),
        isTrue,
      );
      expect(
        shouldIncrementHomeUnreadForIncomingMessage(
          roomId: 'room-1',
          openChatRoomId: null,
          currentUserId: 'user-1',
          senderId: null,
        ),
        isTrue,
      );
    });
  });
}
