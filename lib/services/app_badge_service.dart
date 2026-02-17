import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBadgeService {
  AppBadgeService._();

  static final AppBadgeService instance = AppBadgeService._();
  static const MethodChannel _channel = MethodChannel('pet/app_badge');

  Future<bool> setBadgeCount(int count) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    try {
      await _channel.invokeMethod<dynamic>('setBadgeCount', <String, dynamic>{
        'count': count < 0 ? 0 : count,
      });
      return true;
    } catch (_) {
      debugPrint('[badge] setBadgeCount failed');
      return false;
    }
  }
}
