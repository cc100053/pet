import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/chat/chat_message_action_service.dart';

void main() {
  group('ChatMessageActionService', () {
    test('sendTextReply inserts reply payload and notifies room', () async {
      Map<String, dynamic>? insertedPayload;
      String? notifiedRoomId;
      String? notifiedMessageId;
      final service = ChatMessageActionService(
        insertReply: (payload) async {
          insertedPayload = payload;
          return <String, dynamic>{'id': 'message-123'};
        },
        notifyTextMessage: ({required roomId, required messageId}) async {
          notifiedRoomId = roomId;
          notifiedMessageId = messageId;
        },
      );

      final messageId = await service.sendTextReply(
        roomId: 'room-1',
        replyToMessageId: 'photo-1',
        text: 'Nice photo',
        userId: 'user-1',
      );

      expect(messageId, 'message-123');
      expect(insertedPayload?['room_id'], 'room-1');
      expect(insertedPayload?['sender_id'], 'user-1');
      expect(insertedPayload?['type'], 'text');
      expect(insertedPayload?['body'], 'Nice photo');
      expect(insertedPayload?['reply_to_message_id'], 'photo-1');
      expect(insertedPayload?['client_created_at'], isA<String>());
      expect(notifiedRoomId, 'room-1');
      expect(notifiedMessageId, 'message-123');
    });

    test('toggleReaction deletes when emoji is already selected', () async {
      String? deletedMessageId;
      String? deletedUserId;
      Map<String, dynamic>? upsertedPayload;
      final service = ChatMessageActionService(
        deleteReaction: ({required messageId, required userId}) async {
          deletedMessageId = messageId;
          deletedUserId = userId;
        },
        upsertReaction: (payload) async {
          upsertedPayload = payload;
        },
      );

      await service.toggleReaction(
        roomId: 'room-1',
        messageId: 'message-1',
        emoji: '❤️',
        currentReactionEmoji: '❤️',
        userId: 'user-1',
      );

      expect(deletedMessageId, 'message-1');
      expect(deletedUserId, 'user-1');
      expect(upsertedPayload, isNull);
    });

    test('toggleReaction upserts when selecting a new emoji', () async {
      Map<String, dynamic>? upsertedPayload;
      final service = ChatMessageActionService(
        upsertReaction: (payload) async {
          upsertedPayload = payload;
        },
      );

      await service.toggleReaction(
        roomId: 'room-1',
        messageId: 'message-1',
        emoji: '😂',
        currentReactionEmoji: '❤️',
        userId: 'user-1',
      );

      expect(upsertedPayload, isNotNull);
      expect(upsertedPayload?['room_id'], 'room-1');
      expect(upsertedPayload?['message_id'], 'message-1');
      expect(upsertedPayload?['user_id'], 'user-1');
      expect(upsertedPayload?['emoji'], '😂');
    });
  });
}
