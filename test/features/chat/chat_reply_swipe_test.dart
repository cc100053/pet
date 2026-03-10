import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_room_view_v2.dart';

void main() {
  group('reply swipe rules', () {
    test('allows swipe reply for own non-system messages', () {
      final ownMessage = ChatMessage(
        id: 'm1',
        roomId: 'room-1',
        senderId: 'me',
        type: 'text',
        body: 'hello',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10),
        clientCreatedAt: DateTime.utc(2026, 3, 10),
        labels: const <Map<String, dynamic>>[],
        localImagePath: null,
      );
      final systemMessage = ChatMessage(
        id: 'm2',
        roomId: 'room-1',
        senderId: null,
        type: 'system',
        body: 'system',
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.utc(2026, 3, 10),
        clientCreatedAt: DateTime.utc(2026, 3, 10),
        labels: const <Map<String, dynamic>>[],
        localImagePath: null,
      );

      expect(canSwipeReplyToMessage(ownMessage), isTrue);
      expect(canSwipeReplyToMessage(systemMessage), isFalse);
    });
  });

  group('ReplySwipeWrapper', () {
    testWidgets('left swipe triggers reply before gesture ends', (
      tester,
    ) async {
      var triggerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ReplySwipeWrapper(
                onTriggered: () => triggerCount += 1,
                child: const SizedBox(width: 220, height: 64),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ReplySwipeWrapper)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(triggerCount, 1);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(triggerCount, 1);
    });

    testWidgets('right swipe does not trigger reply', (tester) async {
      var triggerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ReplySwipeWrapper(
                onTriggered: () => triggerCount += 1,
                child: const SizedBox(width: 220, height: 64),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ReplySwipeWrapper), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(triggerCount, 0);
    });
  });
}
