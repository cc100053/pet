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

    test('maps deleted text messages to deleted placeholder', () {
      final message = ChatMessage(
        id: 'm-deleted',
        roomId: 'room',
        senderId: 'user-a',
        type: 'text',
        body: null,
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10, 12),
        clientCreatedAt: DateTime.utc(2026, 3, 10, 12),
        labels: const [],
        localImagePath: null,
        deletedAt: DateTime.utc(2026, 4, 19, 12),
        deletedBy: 'user-a',
      );

      final mapped = PetChatMessageAdapter.toUiMessage(message, l10n);

      expect((mapped as fc.TextMessage).text, l10n.chatMessageDeleted);
      expect(mapped.metadata?[PetChatMessageAdapter.isDeletedKey], isTrue);
      expect(
        PetChatMessageAdapter.previewTextForMessage(message, l10n),
        l10n.chatMessageDeleted,
      );
    });

    test('deleted reply previews use deleted placeholder', () {
      final preview = ChatReplyPreview(
        id: 'reply-1',
        senderId: 'user-a',
        type: 'text',
        body: null,
        imageUrl: null,
        caption: null,
        deletedAt: DateTime.utc(2026, 4, 19, 12),
        deletedBy: 'user-a',
      );

      expect(
        PetChatMessageAdapter.previewTextForReply(preview, l10n),
        l10n.chatMessageDeleted,
      );
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
        coinsAwarded: 40,
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
      expect(mapped.metadata?[PetChatMessageAdapter.coinsAwardedKey], 40);
    });

    test('maps recalled (deleted) feed photos to deleted placeholder', () {
      final message = ChatMessage(
        id: 'feed-deleted',
        roomId: 'room',
        senderId: 'user-a',
        type: 'image_feed',
        body: null,
        imageUrl: null,
        caption: null,
        coinsAwarded: 40,
        createdAt: DateTime.utc(2026, 3, 10, 13),
        clientCreatedAt: DateTime.utc(2026, 3, 10, 13),
        labels: const [],
        localImagePath: null,
        deletedAt: DateTime.utc(2026, 5, 21, 12),
        deletedBy: 'user-a',
      );

      final mapped = PetChatMessageAdapter.toUiMessage(message, l10n);

      // A recalled photo must render as the tombstone text, not an image card.
      expect(mapped, isA<fc.TextMessage>());
      expect((mapped as fc.TextMessage).text, l10n.chatMessageDeleted);
      expect(mapped.metadata?[PetChatMessageAdapter.isDeletedKey], isTrue);
      expect(
        PetChatMessageAdapter.previewTextForMessage(message, l10n),
        l10n.chatMessageDeleted,
      );
    });

    test('formats feed reward labels with localized candy text', () {
      final zh = lookupAppLocalizations(const Locale('zh'));

      expect(PetChatMessageAdapter.feedRewardLabel(20, l10n), '+20 candy');
      expect(PetChatMessageAdapter.feedRewardLabel(20, zh), '糖果 +20');
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

    test('localizes structured store purchase system messages by item name', () {
      final furnitureMessage = ChatMessage(
        id: 'sys-store-1',
        roomId: 'room',
        senderId: null,
        type: 'system',
        body:
            '{"kind":"store_purchase","user_id":"user-a","user_name":"Alice","pet_name":"Mochi","item_sku":"furniture_emoji_sofa","item_category":"furniture"}',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10, 15),
        clientCreatedAt: null,
        labels: const [],
        localImagePath: null,
      );
      final backgroundMessage = ChatMessage(
        id: 'sys-store-2',
        roomId: 'room',
        senderId: null,
        type: 'system',
        body:
            '{"kind":"store_purchase","user_id":"user-a","user_name":"Alice","pet_name":"Mochi","item_sku":"background_test1","item_category":"background"}',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10, 16),
        clientCreatedAt: null,
        labels: const [],
        localImagePath: null,
      );

      final furnitureMapped = PetChatMessageAdapter.toUiMessage(
        furnitureMessage,
        l10n,
      );
      final backgroundMapped = PetChatMessageAdapter.toUiMessage(
        backgroundMessage,
        l10n,
      );

      expect(
        (furnitureMapped as fc.SystemMessage).text,
        l10n.chatBoughtStoreItemMessage(
          'Alice',
          l10n.storeItemNameFurnitureSofa,
          'Mochi',
        ),
      );
      expect(
        (backgroundMapped as fc.SystemMessage).text,
        l10n.chatBoughtStoreItemMessage(
          'Alice',
          l10n.storeItemNameBackgroundMoonlight,
          'Mochi',
        ),
      );
    });
  });
}
