import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationIntentTarget { chat, petHome }

enum NotificationRoomAction {
  ignore,
  showRoomSelection,
  showPetHome,
  openChat,
  switchRoomThenShowPetHome,
  switchRoomThenOpenChat,
}

class AppNotificationIntent {
  const AppNotificationIntent({
    required this.roomId,
    required this.messageKind,
    required this.target,
    this.messageId,
  });

  final String roomId;
  final String messageKind;
  final NotificationIntentTarget target;
  final String? messageId;

  String get dedupeKey =>
      '${messageId ?? 'missing'}|$roomId|$messageKind|${target.name}';

  static AppNotificationIntent? fromData(Map<String, dynamic> data) {
    final roomId = _trimmedString(data['room_id']);
    if (roomId == null) {
      return null;
    }
    final messageKind = _resolveMessageKind(data);
    return AppNotificationIntent(
      roomId: roomId,
      messageId: _trimmedString(data['message_id']),
      messageKind: messageKind,
      target: _resolveTarget(messageKind),
    );
  }

  static String _resolveMessageKind(Map<String, dynamic> data) {
    return _trimmedString(data['message_kind']) ??
        _trimmedString(data['message_type']) ??
        'text';
  }

  static NotificationIntentTarget _resolveTarget(String messageKind) {
    return messageKind == 'text'
        ? NotificationIntentTarget.chat
        : NotificationIntentTarget.petHome;
  }

  static String? _trimmedString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

NotificationRoomAction resolveNotificationRoomAction({
  required AppNotificationIntent intent,
  required Iterable<String> roomIds,
  required String? currentRoomId,
  required bool showRoomSelection,
  required bool roomEntryLoading,
}) {
  if (roomEntryLoading) {
    return NotificationRoomAction.ignore;
  }
  final roomIdSet = roomIds.toSet();
  if (!roomIdSet.contains(intent.roomId)) {
    return NotificationRoomAction.showRoomSelection;
  }
  final needsRoomSwitch = showRoomSelection || currentRoomId != intent.roomId;
  if (intent.target == NotificationIntentTarget.chat) {
    return needsRoomSwitch
        ? NotificationRoomAction.switchRoomThenOpenChat
        : NotificationRoomAction.openChat;
  }
  return needsRoomSwitch
      ? NotificationRoomAction.switchRoomThenShowPetHome
      : NotificationRoomAction.showPetHome;
}

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

class FCMService {
  FCMService({Future<NotificationSettings> Function()? requestPermission})
    : _requestPermission = requestPermission;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final Future<NotificationSettings> Function()? _requestPermission;
  final _notificationIntentController =
      StreamController<AppNotificationIntent>.broadcast();
  final _recentIntentKeys = ListQueue<String>();
  final _recentIntentKeySet = <String>{};
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  bool _initialized = false;
  bool _syncInFlight = false;
  bool _tapListenersRegistered = false;
  bool _initialTapCaptured = false;
  Timer? _retryTimer;
  AppNotificationIntent? _pendingNotificationIntent;
  static const _channel = AndroidNotificationChannel(
    'feed_notifications',
    'Feed Notifications',
    description: 'Foreground notifications for feed events.',
    importance: Importance.high,
  );
  static const MethodChannel _notificationTapChannel = MethodChannel(
    'pet/notification_taps',
  );
  static const int _maxRememberedIntentKeys = 64;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  Stream<AppNotificationIntent> get notificationIntents =>
      _notificationIntentController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      await _attemptTokenSync();
      await _captureInitialNotificationTap();
      return;
    }

    final NotificationSettings settings;
    try {
      settings = await _requestNotificationPermission();
    } catch (error, stackTrace) {
      debugPrint(
        'FCM initialize skipped: notification permission request failed: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return;
    }
    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      debugPrint('FCM initialize skipped: notification permission denied');
      return;
    }

    await _messaging.setAutoInitEnabled(true);
    await _initLocalNotifications();
    _registerTapHandlers();
    await _captureInitialNotificationTap();
    await _attemptTokenSync();

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });

    _authStateSubscription?.cancel();
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        unawaited(_attemptTokenSync());
      }
    });

    _initialized = true;
  }

  Future<NotificationSettings> _requestNotificationPermission() {
    final requestPermission = _requestPermission;
    if (requestPermission != null) {
      return requestPermission();
    }
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  AppNotificationIntent? takePendingNotificationIntent() {
    final intent = _pendingNotificationIntent;
    _pendingNotificationIntent = null;
    return intent;
  }

  @visibleForTesting
  bool debugConsumeNotificationDataForTesting(Map<String, dynamic> data) {
    return _consumeNotificationData(data);
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

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
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

  void _registerTapHandlers() {
    if (_tapListenersRegistered) {
      return;
    }
    _tapListenersRegistered = true;

    _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        _consumeNotificationData(message.data);
      },
    );

    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return;
      }
      _showForegroundNotification(message);
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _notificationTapChannel.setMethodCallHandler(_handlePlatformMethodCall);
    }
  }

  Future<void> _captureInitialNotificationTap() async {
    if (_initialTapCaptured) {
      return;
    }
    _initialTapCaptured = true;

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _consumeNotificationData(initialMessage.data);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final initialIntentPayload = await _notificationTapChannel
          .invokeMapMethod<dynamic, dynamic>('consumeInitialNotificationTap');
      if (initialIntentPayload != null) {
        _consumeNotificationData(
          Map<String, dynamic>.from(initialIntentPayload),
        );
      }
    }
  }

  Future<void> _handlePlatformMethodCall(MethodCall call) async {
    if (call.method != 'notificationTap') {
      return;
    }
    final args = call.arguments;
    if (args is Map) {
      _consumeNotificationData(Map<String, dynamic>.from(args));
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _consumeNotificationData(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Ignore malformed local payloads.
    }
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
      payload: jsonEncode(_jsonSafeNotificationData(data)),
    );
  }

  bool _consumeNotificationData(Map<String, dynamic> data) {
    final intent = AppNotificationIntent.fromData(data);
    if (intent == null || _hasSeenIntent(intent.dedupeKey)) {
      return false;
    }
    _rememberIntent(intent.dedupeKey);
    _pendingNotificationIntent = intent;
    _notificationIntentController.add(intent);
    return true;
  }

  bool _hasSeenIntent(String key) => _recentIntentKeySet.contains(key);

  void _rememberIntent(String key) {
    _recentIntentKeys.addLast(key);
    _recentIntentKeySet.add(key);
    while (_recentIntentKeys.length > _maxRememberedIntentKeys) {
      final removed = _recentIntentKeys.removeFirst();
      _recentIntentKeySet.remove(removed);
    }
  }

  Map<String, dynamic> _jsonSafeNotificationData(Map<String, dynamic> data) {
    return {
      for (final entry in data.entries)
        if (entry.key.trim().isNotEmpty)
          entry.key: entry.value?.toString() ?? '',
    };
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
