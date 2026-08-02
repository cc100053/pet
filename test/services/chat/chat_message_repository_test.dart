import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pet/features/chat/chat_mentions.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/services/chat/chat_message_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChatMessage message(int index) {
    return ChatMessage(
      id: 'm$index',
      roomId: 'room-1',
      senderId: 'user-$index',
      type: 'text',
      body: 'message $index',
      imageUrl: null,
      caption: null,
      coinsAwarded: 0,
      createdAt: DateTime.utc(2026, 3, 19, 12, index),
      clientCreatedAt: DateTime.utc(2026, 3, 19, 12, index),
      labels: const <Map<String, dynamic>>[],
      localImagePath: null,
    );
  }

  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat-message-repo-test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('chat_messages_test');
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('chat_messages_test');
    await tempDir.delete(recursive: true);
  });

  test(
    'cacheMessages persists only the latest 20 canonical messages',
    () async {
      final repository = ChatMessageRepository(box: box);
      final messages = List<ChatMessage>.generate(
        30,
        (index) => message(index + 1),
      );

      await repository.cacheMessages('room-1', messages);

      final cached = await repository.loadCachedMessages('room-1');
      expect(cached.length, 20);
      expect(cached.first.id, 'm30');
      expect(cached.last.id, 'm11');
    },
  );

  test('loadCachedMessages supports latest-only limits', () async {
    final repository = ChatMessageRepository(box: box);
    await repository.cacheMessages(
      'room-1',
      List<ChatMessage>.generate(25, (index) => message(index + 1)),
    );

    final limited = await repository.loadCachedMessages('room-1', limit: 5);

    expect(limited.map((message) => message.id).toList(), <String>[
      'm25',
      'm24',
      'm23',
      'm22',
      'm21',
    ]);
  });

  test('cacheMessages round-trips edited and deleted message state', () async {
    final repository = ChatMessageRepository(box: box);
    final editedAt = DateTime.utc(2026, 4, 19, 12);
    final deletedAt = DateTime.utc(2026, 4, 19, 12, 5);
    final deleted = message(1).copyWith(
      clearBody: true,
      editedAt: editedAt,
      deletedAt: deletedAt,
      deletedBy: 'user-1',
      replyPreview: ChatReplyPreview(
        id: 'reply-1',
        senderId: 'user-2',
        type: 'text',
        body: null,
        imageUrl: null,
        caption: null,
        deletedAt: deletedAt,
        deletedBy: 'user-2',
      ),
    );

    await repository.cacheMessages('room-1', <ChatMessage>[deleted]);

    final cached = await repository.loadCachedMessages('room-1');
    expect(cached, hasLength(1));
    expect(cached.single.body, isNull);
    expect(cached.single.editedAt, editedAt);
    expect(cached.single.deletedAt, deletedAt);
    expect(cached.single.deletedBy, 'user-1');
    expect(cached.single.isDeleted, isTrue);
    expect(cached.single.replyPreview?.isDeleted, isTrue);
  });

  test(
    'fetchReactionDetails maps rows and keeps newest reactions first',
    () async {
      final repository = ChatMessageRepository(
        box: box,
        reactionDetailsRowsLoader:
            ({required roomId, required messageId}) async =>
                <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message_id': messageId,
                    'user_id': 'user-older',
                    'emoji': '👍',
                    'created_at': '2026-03-31T10:00:00Z',
                  },
                  <String, dynamic>{
                    'message_id': messageId,
                    'user_id': 'user-newer',
                    'emoji': '❤️',
                    'created_at': '2026-03-31T10:01:00Z',
                  },
                ],
      );

      final details = await repository.fetchReactionDetails(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(details, hasLength(2));
      expect(details.first.userId, 'user-newer');
      expect(details.first.emoji, '❤️');
      expect(details.last.userId, 'user-older');
      expect(details.last.emoji, '👍');
    },
  );

  test('blocked user ids round-trip and stay scoped to the blocker', () async {
    final repository = ChatMessageRepository(box: box);

    await repository.cacheBlockedUserIds('me', <String>{'a', 'b'});

    expect(await repository.loadCachedBlockedUserIds('me'), {'a', 'b'});
    // A different account on the same device must not inherit the list.
    expect(await repository.loadCachedBlockedUserIds('someone-else'), isEmpty);
    // The reserved key must not leak into the per-room message cache.
    expect(await repository.loadCachedMessages('room-1'), isEmpty);
  });

  test('mention candidates round-trip per room', () async {
    final repository = ChatMessageRepository(box: box);

    await repository.cacheMentionCandidates('room-1', const [
      ChatMentionCandidate(
        userId: 'alice',
        displayName: 'Alice',
        avatarUrl: 'https://example.test/a.png',
      ),
      ChatMentionCandidate(userId: 'bob', displayName: 'Bob'),
    ]);

    final cached = await repository.loadCachedMentionCandidates('room-1');
    expect(cached.map((candidate) => candidate.userId), ['alice', 'bob']);
    expect(cached.first.avatarUrl, 'https://example.test/a.png');
    expect(cached.last.avatarUrl, isNull);
    expect(await repository.loadCachedMentionCandidates('room-2'), isEmpty);
  });
}
