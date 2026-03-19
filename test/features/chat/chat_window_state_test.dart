import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_window_state.dart';

void main() {
  ChatMessage message(int index) {
    return ChatMessage(
      id: 'm$index',
      roomId: 'room-1',
      senderId: index.isEven ? 'me' : 'other',
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

  group('ChatWindowState', () {
    test('hydrateCache keeps only the latest page', () {
      final state = ChatWindowState(pageSize: 20, maxVisibleMessages: 80);

      state.hydrateCache(
        List<ChatMessage>.generate(40, (index) => message(index + 1)),
      );

      expect(state.visibleMessages.length, 20);
      expect(state.visibleMessages.first.id, 'm21');
      expect(state.visibleMessages.last.id, 'm40');
      expect(state.isLiveMode, isTrue);
    });

    test('prependOlderPage trims the newest tail to the bounded window', () {
      final state = ChatWindowState(pageSize: 20, maxVisibleMessages: 30);

      state.replaceWithLatest(
        List<ChatMessage>.generate(20, (index) => message(index + 21)),
        hasMoreOlder: true,
      );
      state.prependOlderPage(
        List<ChatMessage>.generate(20, (index) => message(index + 1)),
        hasMoreOlder: false,
      );

      expect(state.visibleMessages.length, 30);
      expect(state.visibleMessages.first.id, 'm1');
      expect(state.visibleMessages.last.id, 'm30');
      expect(state.isHistoryMode, isTrue);
      expect(state.hasMoreOlder, isFalse);
    });

    test('upsertVisibleMessage in live mode trims the oldest head', () {
      final state = ChatWindowState(pageSize: 20, maxVisibleMessages: 20);

      state.replaceWithLatest(
        List<ChatMessage>.generate(20, (index) => message(index + 21)),
        hasMoreOlder: true,
      );
      state.upsertVisibleMessage(message(41), keepLatestWindow: true);

      expect(state.visibleMessages.length, 20);
      expect(state.visibleMessages.first.id, 'm22');
      expect(state.visibleMessages.last.id, 'm41');
    });

    test(
      'history mode buffers pending live messages and reset clears them',
      () {
        final state = ChatWindowState(pageSize: 20, maxVisibleMessages: 80);

        state.replaceWithLatest(
          List<ChatMessage>.generate(20, (index) => message(index + 21)),
          hasMoreOlder: true,
        );
        state.prependOlderPage(
          List<ChatMessage>.generate(20, (index) => message(index + 1)),
          hasMoreOlder: true,
        );

        state.bufferLiveMessage(message(41));
        state.bufferLiveMessage(message(42));
        state.bufferLiveMessage(message(41));

        expect(state.pendingLiveMessageCount, 2);

        state.replaceWithLatest(
          List<ChatMessage>.generate(20, (index) => message(index + 23)),
          hasMoreOlder: true,
        );

        expect(state.pendingLiveMessageCount, 0);
        expect(state.isLiveMode, isTrue);
        expect(state.visibleMessages.first.id, 'm23');
        expect(state.visibleMessages.last.id, 'm42');
      },
    );

    test('latestVisibleCanonicalSlice returns the newest canonical page', () {
      final state = ChatWindowState(pageSize: 20, maxVisibleMessages: 80);

      state.replaceWithLatest(
        List<ChatMessage>.generate(30, (index) => message(index + 11)),
        hasMoreOlder: true,
      );

      final latest = state.latestVisibleCanonicalSlice(
        includeMessage: (message) =>
            int.parse(message.id.substring(1)) % 5 != 0,
      );

      expect(latest.length, 16);
      expect(latest.first.id, 'm21');
      expect(latest.last.id, 'm39');
    });
  });
}
