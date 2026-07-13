import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/fcm_service.dart';

void main() {
  group('AppNotificationIntent.fromData', () {
    test('routes text messages to chat', () {
      final intent = AppNotificationIntent.fromData({
        'room_id': 'room-1',
        'message_id': 'msg-1',
        'message_kind': 'text',
      });

      expect(intent, isNotNull);
      expect(intent!.roomId, 'room-1');
      expect(intent.messageId, 'msg-1');
      expect(intent.messageKind, 'text');
      expect(intent.target, NotificationIntentTarget.chat);
    });

    test('routes feed images to pet home', () {
      final intent = AppNotificationIntent.fromData({
        'room_id': 'room-1',
        'message_kind': 'image_feed',
      });

      expect(intent, isNotNull);
      expect(intent!.target, NotificationIntentTarget.petHome);
    });

    test('routes hunger alerts to pet home', () {
      final intent = AppNotificationIntent.fromData({
        'room_id': 'room-1',
        'message_kind': 'hunger_alert_50',
      });

      expect(intent, isNotNull);
      expect(intent!.target, NotificationIntentTarget.petHome);
      expect(intent.messageKind, 'hunger_alert_50');
    });

    test('routes store purchases to pet home', () {
      final intent = AppNotificationIntent.fromData({
        'room_id': 'room-1',
        'message_id': 'msg-store-1',
        'message_kind': 'store_purchase',
      });

      expect(intent, isNotNull);
      expect(intent!.target, NotificationIntentTarget.petHome);
      expect(intent.messageKind, 'store_purchase');
    });

    test('falls back to legacy message_type', () {
      final intent = AppNotificationIntent.fromData({
        'room_id': 'room-1',
        'message_type': 'image_feed',
      });

      expect(intent, isNotNull);
      expect(intent!.messageKind, 'image_feed');
      expect(intent.target, NotificationIntentTarget.petHome);
    });

    test('returns null when room_id is missing', () {
      final intent = AppNotificationIntent.fromData({'message_kind': 'text'});

      expect(intent, isNull);
    });
  });

  group('FCMService notification dedupe', () {
    test('drops duplicate notification intents', () {
      final service = FCMService();
      final payload = <String, dynamic>{
        'room_id': 'room-1',
        'message_id': 'msg-1',
        'message_kind': 'text',
      };

      expect(service.debugConsumeNotificationDataForTesting(payload), isTrue);
      expect(service.debugConsumeNotificationDataForTesting(payload), isFalse);

      final pending = service.takePendingNotificationIntent();
      expect(pending, isNotNull);
      expect(pending!.roomId, 'room-1');
      expect(service.takePendingNotificationIntent(), isNull);
    });
  });

  group('FCMService initialization', () {
    test('contains notification permission request failures', () async {
      var requestCount = 0;
      final service = FCMService(
        requestPermission: () async {
          requestCount += 1;
          throw PlatformException(
            code: 'unknown',
            message: 'Notifications are not allowed for this application',
          );
        },
      );

      await expectLater(service.initialize(), completes);

      expect(requestCount, 1);
    });
  });

  group('resolveNotificationRoomAction', () {
    test(
      'requests room switch then chat open for text from room selection',
      () {
        final action = resolveNotificationRoomAction(
          intent: const AppNotificationIntent(
            roomId: 'room-2',
            messageId: 'msg-2',
            messageKind: 'text',
            target: NotificationIntentTarget.chat,
          ),
          roomIds: const ['room-1', 'room-2'],
          currentRoomId: 'room-1',
          showRoomSelection: true,
          roomEntryLoading: false,
        );

        expect(action, NotificationRoomAction.switchRoomThenOpenChat);
      },
    );

    test('requests room switch then pet home for feed messages', () {
      final action = resolveNotificationRoomAction(
        intent: const AppNotificationIntent(
          roomId: 'room-2',
          messageId: 'msg-2',
          messageKind: 'image_feed',
          target: NotificationIntentTarget.petHome,
        ),
        roomIds: const ['room-1', 'room-2'],
        currentRoomId: 'room-1',
        showRoomSelection: false,
        roomEntryLoading: false,
      );

      expect(action, NotificationRoomAction.switchRoomThenShowPetHome);
    });

    test('falls back to room selection for stale rooms', () {
      final action = resolveNotificationRoomAction(
        intent: const AppNotificationIntent(
          roomId: 'room-missing',
          messageId: 'msg-3',
          messageKind: 'text',
          target: NotificationIntentTarget.chat,
        ),
        roomIds: const ['room-1'],
        currentRoomId: 'room-1',
        showRoomSelection: false,
        roomEntryLoading: false,
      );

      expect(action, NotificationRoomAction.showRoomSelection);
    });

    test('waits while room entry loading is in progress', () {
      final action = resolveNotificationRoomAction(
        intent: const AppNotificationIntent(
          roomId: 'room-1',
          messageId: 'msg-4',
          messageKind: 'text',
          target: NotificationIntentTarget.chat,
        ),
        roomIds: const ['room-1'],
        currentRoomId: 'room-1',
        showRoomSelection: false,
        roomEntryLoading: true,
      );

      expect(action, NotificationRoomAction.ignore);
    });
  });
}
