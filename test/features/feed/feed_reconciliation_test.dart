import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/feed/feed_reconciliation.dart';

void main() {
  group('matchesFeedIdentity', () {
    test('matches by message id when both sides have ids', () {
      final expectedAt = DateTime.utc(2026, 4, 28, 12);

      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: ' Dinner ',
          expectedClientCreatedAt: expectedAt,
          expectedMessageId: 'message-1',
          roomId: 'room-1',
          senderId: 'user-1',
          caption: 'Dinner',
          messageId: 'message-1',
          createdAt: expectedAt.add(const Duration(minutes: 10)),
        ),
        isTrue,
      );
    });

    test('matches by client-created timestamp within tolerance', () {
      final expectedAt = DateTime.utc(2026, 4, 28, 12);

      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: 'Dinner',
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-1',
          senderId: 'user-1',
          caption: ' Dinner ',
          clientCreatedAt: expectedAt.add(const Duration(seconds: 2)),
        ),
        isTrue,
      );
    });

    test('falls back to server-created timestamp within tolerance', () {
      final expectedAt = DateTime.utc(2026, 4, 28, 12);

      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: null,
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-1',
          senderId: 'user-1',
          caption: '',
          createdAt: expectedAt.add(const Duration(seconds: 45)),
        ),
        isTrue,
      );
    });

    test('rejects mismatched caption, sender, room, and timestamps', () {
      final expectedAt = DateTime.utc(2026, 4, 28, 12);

      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: 'Dinner',
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-1',
          senderId: 'user-1',
          caption: 'Lunch',
          clientCreatedAt: expectedAt,
        ),
        isFalse,
      );
      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: 'Dinner',
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-2',
          senderId: 'user-1',
          caption: 'Dinner',
          clientCreatedAt: expectedAt,
        ),
        isFalse,
      );
      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: 'Dinner',
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-1',
          senderId: 'user-2',
          caption: 'Dinner',
          clientCreatedAt: expectedAt,
        ),
        isFalse,
      );
      expect(
        matchesFeedIdentity(
          expectedRoomId: 'room-1',
          expectedSenderId: 'user-1',
          expectedCaption: 'Dinner',
          expectedClientCreatedAt: expectedAt,
          roomId: 'room-1',
          senderId: 'user-1',
          caption: 'Dinner',
          clientCreatedAt: expectedAt.add(const Duration(seconds: 3)),
          createdAt: expectedAt.add(const Duration(seconds: 46)),
        ),
        isFalse,
      );
    });
  });

  group('parseFeedDate', () {
    test('parses strings and normalizes DateTime values to UTC', () {
      expect(
        parseFeedDate('2026-04-28T12:00:00Z'),
        DateTime.utc(2026, 4, 28, 12),
      );
      expect(
        parseFeedDate(DateTime(2026, 4, 28, 21)),
        DateTime(2026, 4, 28, 21).toUtc(),
      );
      expect(parseFeedDate('not-a-date'), isNull);
    });
  });
}
