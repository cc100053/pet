import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth/session_utils.dart';

typedef ShopAccessTokenProvider = Future<String?> Function();
typedef ShopNotifyFriendInvoker =
    Future<int> Function({
      required String accessToken,
      required Map<String, dynamic> body,
    });

abstract class ShopPurchaseNotifier {
  Future<ShopPurchaseNotificationResult> notifyStorePurchase({
    required String roomId,
    required String messageId,
  });
}

enum ShopPurchaseNotificationResult {
  delivered,
  skippedMissingAccessToken,
  skippedNonSuccessStatus,
  skippedFailure,
}

class SupabaseShopPurchaseNotifier implements ShopPurchaseNotifier {
  SupabaseShopPurchaseNotifier({
    ShopAccessTokenProvider? accessTokenProvider,
    ShopNotifyFriendInvoker? invokeNotifyFriend,
  }) : _accessTokenProvider = accessTokenProvider ?? ensureValidAccessToken,
       _invokeNotifyFriend = invokeNotifyFriend ?? _supabaseNotifyFriend;

  final ShopAccessTokenProvider _accessTokenProvider;
  final ShopNotifyFriendInvoker _invokeNotifyFriend;

  @override
  Future<ShopPurchaseNotificationResult> notifyStorePurchase({
    required String roomId,
    required String messageId,
  }) async {
    try {
      final accessToken = await _accessTokenProvider();
      if (accessToken == null) {
        return ShopPurchaseNotificationResult.skippedMissingAccessToken;
      }
      final status = await _invokeNotifyFriend(
        accessToken: accessToken,
        body: {
          'type': 'store_purchase',
          'room_id': roomId,
          'message_id': messageId,
        },
      );
      if (status < 200 || status >= 300) {
        return ShopPurchaseNotificationResult.skippedNonSuccessStatus;
      }
      return ShopPurchaseNotificationResult.delivered;
    } catch (_) {
      return ShopPurchaseNotificationResult.skippedFailure;
    }
  }

  static Future<int> _supabaseNotifyFriend({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'notify_friend',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: body,
    );
    return response.status;
  }
}
