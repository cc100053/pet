import 'package:flutter/widgets.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/adapters/pet_chat_message_adapter.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('PetChatMessageAdapter', () {
    test('maps text messages to package text messages with reply id', () {
      final message = ChatMessage(
        id: 'm1',
        roomId: 'room',
        senderId: 'user-a',
        type: 'text',
        body: 'Hello',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10, 12),
        clientCreatedAt: DateTime.utc(2026, 3, 10, 12),
        labels: const [],
        localImagePath: null,
        replyToMessageId: 'm0',
      );

      final mapped = PetChatMessageAdapter.toUiMessage(message, l10n);

      expect(mapped, isA<fc.TextMessage>());
      expect(mapped.replyToMessageId, 'm0');
      expect((mapped as fc.TextMessage).text, 'Hello');
      expect(mapped.status, fc.MessageStatus.sent);
    });

    test('maps feed messages to custom messages and preserves metadata', () {
      final message = ChatMessage(
        id: 'feed-1',
        roomId: 'room',
        senderId: 'user-a',
        type: 'image_feed',
        body: null,
        imageUrl: 'https://example.com/cat.jpg',
        caption: 'Fresh snack',
        coinsAwarded: 12,
        createdAt: DateTime.utc(2026, 3, 10, 13),
        clientCreatedAt: DateTime.utc(2026, 3, 10, 13),
        labels: const [],
        localImagePath: '/tmp/cat.jpg',
      );

      final mapped = PetChatMessageAdapter.toUiMessage(
        message,
        l10n,
        isOptimistic: true,
      );

      expect(mapped, isA<fc.CustomMessage>());
      expect(mapped.status, fc.MessageStatus.sending);
      expect(
        mapped.metadata?[PetChatMessageAdapter.customTypeKey],
        'feed_card',
      );
      expect(mapped.metadata?[PetChatMessageAdapter.captionKey], 'Fresh snack');
      expect(
        mapped.metadata?[PetChatMessageAdapter.imageUrlKey],
        'https://example.com/cat.jpg',
      );
      expect(
        mapped.metadata?[PetChatMessageAdapter.localImagePathKey],
        '/tmp/cat.jpg',
      );
      expect(mapped.metadata?[PetChatMessageAdapter.coinsAwardedKey], 12);
    });

    test('localizes supported system messages', () {
      final message = ChatMessage(
        id: 'sys-1',
        roomId: 'room',
        senderId: null,
        type: 'system',
        body: 'hunger_alert_10::Mochi',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10, 14),
        clientCreatedAt: null,
        labels: const [],
        localImagePath: null,
      );

      final mapped = PetChatMessageAdapter.toUiMessage(message, l10n);

      expect(mapped, isA<fc.SystemMessage>());
      expect(
        (mapped as fc.SystemMessage).text,
        l10n.chatPetHungryUrgentMessage('Mochi'),
      );
    });
  });
}
