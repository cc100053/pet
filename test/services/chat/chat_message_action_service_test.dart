import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/chat/chat_message_action_service.dart';

void main() {
  group('ChatMessageActionService', () {
    test('sendTextMessageRow returns inserted message row', () async {
      Map<String, dynamic>? insertedPayload;
      final service = ChatMessageActionService(
        insertText: (payload) async {
          insertedPayload = payload;
          return <String, dynamic>{
            'id': 'message-456',
            'room_id': payload['room_id'],
            'sender_id': payload['sender_id'],
            'type': payload['type'],
            'body': payload['body'],
            'created_at': '2026-03-31T12:00:00.000Z',
          };
        },
      );

      final row = await service.sendTextMessageRow(
        roomId: 'room-1',
        text: 'Hello',
        userId: 'user-1',
      );

      expect(row['id'], 'message-456');
      expect(row['body'], 'Hello');
      expect(insertedPayload?['room_id'], 'room-1');
      expect(insertedPayload?['sender_id'], 'user-1');
      expect(insertedPayload?['client_created_at'], isA<String>());
    });

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

    test('editTextMessageRow trims text and returns updated row', () async {
      String? editedRoomId;
      String? editedMessageId;
      String? editedText;
      final service = ChatMessageActionService(
        editText: ({required roomId, required messageId, required text}) async {
          editedRoomId = roomId;
          editedMessageId = messageId;
          editedText = text;
          return <String, dynamic>{
            'id': messageId,
            'room_id': roomId,
            'sender_id': 'user-1',
            'type': 'text',
            'body': text,
            'edited_at': '2026-04-19T12:00:00Z',
          };
        },
      );

      final row = await service.editTextMessageRow(
        roomId: 'room-1',
        messageId: 'message-1',
        text: '  Updated  ',
      );

      expect(row['id'], 'message-1');
      expect(row['body'], 'Updated');
      expect(editedRoomId, 'room-1');
      expect(editedMessageId, 'message-1');
      expect(editedText, 'Updated');
    });

    test('editTextMessageRow rejects empty text', () async {
      final service = ChatMessageActionService(
        editText:
            ({required roomId, required messageId, required text}) async =>
                <String, dynamic>{'id': messageId},
      );

      expect(
        () => service.editTextMessageRow(
          roomId: 'room-1',
          messageId: 'message-1',
          text: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteTextMessageRow returns deleted row', () async {
      String? deletedRoomId;
      String? deletedMessageId;
      final service = ChatMessageActionService(
        deleteText: ({required roomId, required messageId}) async {
          deletedRoomId = roomId;
          deletedMessageId = messageId;
          return <String, dynamic>{
            'id': messageId,
            'room_id': roomId,
            'sender_id': 'user-1',
            'type': 'text',
            'body': null,
            'deleted_at': '2026-04-19T12:00:00Z',
            'deleted_by': 'user-1',
          };
        },
      );

      final row = await service.deleteTextMessageRow(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(row['id'], 'message-1');
      expect(row['body'], isNull);
      expect(deletedRoomId, 'room-1');
      expect(deletedMessageId, 'message-1');
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
