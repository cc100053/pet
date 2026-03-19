import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
}
