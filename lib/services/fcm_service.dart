import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

class FCMService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _initialized = false;
  bool _syncInFlight = false;
  Timer? _retryTimer;
  static const _channel = AndroidNotificationChannel(
    'feed_notifications',
    'Feed Notifications',
    description: 'Foreground notifications for feed events.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) {
      await _attemptTokenSync();
      return;
    }

    // 1. Request Permission (Critical for iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      debugPrint('FCM initialize skipped: notification permission denied');
      return;
    }

    await _messaging.setAutoInitEnabled(true);
    await _initLocalNotifications();

    // 2. Fetch the FCM Token (retry until APNS is ready on iOS)
    await _attemptTokenSync();

    // 3. Listen for token refreshes
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });

    // 3b. Re-sync token after auth transitions (fresh installs may
    // initialize FCM before a valid user session is available).
    _authStateSubscription?.cancel();
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        unawaited(_attemptTokenSync());
      }
    });

    // 4. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Android foreground rendering is handled by the native
      // FirebaseMessagingService implementation.
      if (defaultTargetPlatform == TargetPlatform.android) {
        return;
      }
      // Keep a local fallback for iOS foreground to guarantee a visible
      // alert when system foreground presentation is suppressed by device
      // notification settings/focus modes. Background notifications still
      // use the remote communication-notification path.
      _showForegroundNotification(message);
    });
    _initialized = true;
  }

  Future<void> refreshTokenSync() async {
    await _attemptTokenSync();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: settings);
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;
    final title =
        _resolveTitleFromData(data) ?? notification?.title ?? 'PetTomo';
    final body = _resolveBodyFromData(data) ?? notification?.body ?? '';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _attemptTokenSync() async {
    if (_syncInFlight) {
      return;
    }
    _syncInFlight = true;
    const delays = [0, 1, 2, 3, 5, 8];
    try {
      for (final seconds in delays) {
        if (seconds > 0) {
          await Future.delayed(Duration(seconds: seconds));
        }
        final apnsReady = await _isApnsReady();
        if (!apnsReady) {
          continue;
        }
        final token = await _getFcmTokenSafely();
        if (token != null) {
          await _saveTokenToSupabase(token);
          _retryTimer?.cancel();
          _retryTimer = null;
          return;
        }
      }
      _scheduleRetry();
    } finally {
      _syncInFlight = false;
    }
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) {
      return;
    }
    _retryTimer = Timer(const Duration(seconds: 20), () {
      unawaited(_attemptTokenSync());
    });
  }

  Future<bool> _isApnsReady() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    final apnsToken = await _messaging.getAPNSToken();
    if (apnsToken != null && apnsToken.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<String?> _getFcmTokenSafely() async {
    try {
      return await _messaging.getToken();
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': _platformLabel(),
        'device_locale': _systemLocaleTag(),
        'last_seen_at': now,
        'updated_at': now,
      }, onConflict: 'token');
    } catch (error, stack) {
      debugPrint('FCM token sync failed: $error');
      debugPrintStack(stackTrace: stack);
      _scheduleRetry();
    }
  }

  String _resolveMessageType(Map<String, dynamic> data) {
    final messageKind = (data['message_kind'] as String?)?.trim();
    if (messageKind != null && messageKind.isNotEmpty) {
      return messageKind;
    }
    final legacyType = (data['message_type'] as String?)?.trim();
    if (legacyType != null && legacyType.isNotEmpty) {
      return legacyType;
    }
    return 'text';
  }

  String? _resolveBodyFromData(Map<String, dynamic> data) {
    final bodyFull = (data['body_full'] as String?)?.trim();
    if (bodyFull != null && bodyFull.isNotEmpty) {
      return bodyFull;
    }
    final messageType = _resolveMessageType(data);
    if (messageType == 'image_feed') {
      final caption = (data['caption'] as String?)?.trim();
      if (caption != null && caption.isNotEmpty) {
        return '🖼️ $caption';
      }
      final fallback = (data['text_body'] as String?)?.trim();
      if (fallback != null && fallback.isNotEmpty) {
        return '🖼️ $fallback';
      }
      return '🖼️';
    }
    if (messageType == 'text') {
      final raw = (data['text_body'] as String?)?.trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }
    return null;
  }

  String? _resolveTitleFromData(Map<String, dynamic> data) {
    final titleFull = (data['title_full'] as String?)?.trim();
    if (titleFull != null && titleFull.isNotEmpty) {
      return titleFull;
    }
    final appName = (data['title_app_name'] as String?)?.trim();
    final petName = (data['pet_name'] as String?)?.trim();
    final senderName = (data['sender_name'] as String?)?.trim();
    if (appName != null &&
        appName.isNotEmpty &&
        petName != null &&
        petName.isNotEmpty &&
        senderName != null &&
        senderName.isNotEmpty) {
      return '$appName $petName · $senderName';
    }
    if (appName != null &&
        appName.isNotEmpty &&
        petName != null &&
        petName.isNotEmpty) {
      return '$appName $petName';
    }
    return null;
  }

  String _systemLocaleTag() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode.trim();
    final countryCode = locale.countryCode?.trim();
    if (languageCode.isEmpty) {
      return 'en-US';
    }
    if (countryCode == null || countryCode.isEmpty) {
      return languageCode;
    }
    return '$languageCode-$countryCode';
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<void> showTestNotification() async {
    await _showForegroundNotification(
      RemoteMessage(
        notification: const RemoteNotification(
          title: 'Test Notification',
          body: 'Local notification check.',
        ),
      ),
    );
  }
}
