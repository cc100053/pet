import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/services/shop_purchase_notifier.dart';

void main() {
  group('SupabaseShopPurchaseNotifier', () {
    test('delivers store purchase notification payload', () async {
      final invoker = _FakeNotifyFriendInvoker(status: 202);
      final notifier = SupabaseShopPurchaseNotifier(
        accessTokenProvider: () async => 'access-token',
        invokeNotifyFriend: invoker.call,
      );

      final result = await notifier.notifyStorePurchase(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(result, ShopPurchaseNotificationResult.delivered);
      expect(invoker.calls, [
        _NotifyFriendCall(
          accessToken: 'access-token',
          body: {
            'type': 'store_purchase',
            'room_id': 'room-1',
            'message_id': 'message-1',
          },
        ),
      ]);
    });

    test('skips delivery when access token is missing', () async {
      final invoker = _FakeNotifyFriendInvoker(status: 200);
      final notifier = SupabaseShopPurchaseNotifier(
        accessTokenProvider: () async => null,
        invokeNotifyFriend: invoker.call,
      );

      final result = await notifier.notifyStorePurchase(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(result, ShopPurchaseNotificationResult.skippedMissingAccessToken);
      expect(invoker.calls, isEmpty);
    });

    test('reports non-success status without throwing', () async {
      final notifier = SupabaseShopPurchaseNotifier(
        accessTokenProvider: () async => 'access-token',
        invokeNotifyFriend: _FakeNotifyFriendInvoker(status: 500).call,
      );

      final result = await notifier.notifyStorePurchase(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(result, ShopPurchaseNotificationResult.skippedNonSuccessStatus);
    });

    test('swallows delivery failures', () async {
      final notifier = SupabaseShopPurchaseNotifier(
        accessTokenProvider: () async => 'access-token',
        invokeNotifyFriend:
            ({
              required String accessToken,
              required Map<String, dynamic> body,
            }) async {
              throw StateError('network failed');
            },
      );

      final result = await notifier.notifyStorePurchase(
        roomId: 'room-1',
        messageId: 'message-1',
      );

      expect(result, ShopPurchaseNotificationResult.skippedFailure);
    });
  });
}

class _FakeNotifyFriendInvoker {
  _FakeNotifyFriendInvoker({required this.status});

  final int status;
  final List<_NotifyFriendCall> calls = [];

  Future<int> call({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    calls.add(_NotifyFriendCall(accessToken: accessToken, body: body));
    return status;
  }
}

class _NotifyFriendCall {
  const _NotifyFriendCall({required this.accessToken, required this.body});

  final String accessToken;
  final Map<String, dynamic> body;

  @override
  bool operator ==(Object other) {
    return other is _NotifyFriendCall &&
        other.accessToken == accessToken &&
        _mapsEqual(other.body, body);
  }

  @override
  int get hashCode => Object.hash(accessToken, Object.hashAll(body.entries));
}

bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
