import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  String _route = 'unknown';
  String _feature = 'app';
  String _roomId = 'none';
  String _lastAction = 'app_start';
  String _networkState = 'unknown';

  Future<void> initialize() async {
    String appVersion = 'unknown';
    String buildNumber = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // Ignore package info failure and continue with unknown version metadata.
    }
    await _setCustomKey('app_version', appVersion);
    await _setCustomKey('build_number', buildNumber);
    await _setCustomKey('app_version_full', '$appVersion+$buildNumber');
    await _setCustomKey('route', _route);
    await _setCustomKey('feature', _feature);
    await _setCustomKey('room_id', _roomId);
    await _setCustomKey('last_action', _lastAction);
    await _setCustomKey('network_state', _networkState);
    await breadcrumb(
      'crash_reporting_initialized',
      data: {'app_version': appVersion, 'build_number': buildNumber},
    );
  }

  Future<void> setUserId(String? userId) async {
    final normalized = (userId == null || userId.isEmpty)
        ? 'signed_out'
        : userId;
    await _crashlytics.setUserIdentifier(normalized);
    await _setCustomKey(
      'auth_state',
      normalized == 'signed_out' ? 'signed_out' : 'signed_in',
    );
  }

  Future<void> setRoute(String route) async {
    final normalized = _truncate(route.trim().isEmpty ? 'unknown' : route);
    if (_route == normalized) {
      return;
    }
    _route = normalized;
    await _setCustomKey('route', normalized);
  }

  Future<void> setContext({
    String? feature,
    String? roomId,
    String? lastAction,
    String? networkState,
  }) async {
    if (feature != null) {
      final normalized = _truncate(
        feature.trim().isEmpty ? _feature : feature.trim(),
      );
      if (normalized != _feature) {
        _feature = normalized;
        await _setCustomKey('feature', normalized);
      }
    }
    if (roomId != null) {
      final normalized = _truncate(roomId.trim().isEmpty ? 'none' : roomId);
      if (normalized != _roomId) {
        _roomId = normalized;
        await _setCustomKey('room_id', normalized);
      }
    }
    if (lastAction != null) {
      final normalized = _truncate(
        lastAction.trim().isEmpty ? _lastAction : lastAction.trim(),
      );
      if (normalized != _lastAction) {
        _lastAction = normalized;
        await _setCustomKey('last_action', normalized);
      }
    }
    if (networkState != null) {
      final normalized = _truncate(
        networkState.trim().isEmpty ? _networkState : networkState.trim(),
      );
      if (normalized != _networkState) {
        _networkState = normalized;
        await _setCustomKey('network_state', normalized);
      }
    }
  }

  Future<void> breadcrumb(String message, {Map<String, Object?>? data}) async {
    final normalized = message.trim().isEmpty ? 'event' : message.trim();
    final payload = data == null || data.isEmpty
        ? normalized
        : _formatLog(normalized, data);
    _crashlytics.log(_truncate(payload));
  }

  Future<void> setCustomKeys(Map<String, Object?> values) async {
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      await _setCustomKey(entry.key, value);
    }
  }

  Future<void> reportError({
    required Object error,
    required StackTrace stackTrace,
    required String source,
    bool fatal = false,
    String? reason,
    Iterable<Object> information = const <Object>[],
  }) async {
    final normalizedSource = _truncate(
      source.trim().isEmpty ? 'unknown_source' : source.trim(),
    );
    final effectiveFatal = shouldRecordAsFatal(error, requestedFatal: fatal);
    await _setCustomKey('last_error_source', normalizedSource);
    await breadcrumb(
      'captured_error',
      data: {
        'source': normalizedSource,
        'fatal': effectiveFatal,
        'error_type': error.runtimeType.toString(),
      },
    );
    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: effectiveFatal,
      reason: reason ?? normalizedSource,
      information: information,
    );
  }

  Future<void> reportFlutterFatalError({
    required FlutterErrorDetails details,
    required String source,
  }) async {
    final normalizedSource = _truncate(
      source.trim().isEmpty ? 'flutter_error' : source.trim(),
    );
    await _setCustomKey('last_error_source', normalizedSource);
    await breadcrumb(
      'captured_flutter_fatal_error',
      data: {'source': normalizedSource},
    );
    await _crashlytics.recordFlutterFatalError(details);
  }

  Future<void> triggerTestCrash() async {
    await setContext(lastAction: 'debug_test_crash');
    await breadcrumb('debug_test_crash_triggered');
    _crashlytics.crash();
  }

  String _formatLog(String message, Map<String, Object?> data) {
    try {
      final sanitized = <String, Object>{};
      for (final entry in data.entries) {
        final value = entry.value;
        if (value == null) {
          continue;
        }
        sanitized[entry.key] = value;
      }
      if (sanitized.isEmpty) {
        return message;
      }
      return '$message ${jsonEncode(sanitized)}';
    } catch (_) {
      return message;
    }
  }

  Future<void> _setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, _truncate(value.toString()));
  }

  String _truncate(String value, {int maxLength = 1024}) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }

  @visibleForTesting
  static bool shouldRecordAsFatal(
    Object error, {
    required bool requestedFatal,
  }) {
    if (!requestedFatal) {
      return false;
    }
    return !_isRetryableNetworkError(error);
  }

  static bool _isRetryableNetworkError(Object error) {
    if (error is TimeoutException) {
      return true;
    }

    final text = error.toString().toLowerCase();
    if (text.contains('authretryablefetchexception') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection closed before full header was received') ||
        text.contains('connection reset by peer') ||
        text.contains('connection terminated during handshake') ||
        text.contains('software caused connection abort') ||
        text.contains('temporary failure in name resolution') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection timed out') ||
        text.contains('operation timed out') ||
        text.contains('timed out') ||
        text.contains('bad file descriptor')) {
      return true;
    }

    return false;
  }
}

class CrashRouteObserver extends NavigatorObserver {
  CrashRouteObserver._();

  static final CrashRouteObserver instance = CrashRouteObserver._();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(route, action: 'route_push');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(previousRoute, action: 'route_pop');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _sync(newRoute, action: 'route_replace');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _sync(Route<dynamic>? route, {required String action}) {
    final routeName = _resolveRouteName(route);
    unawaited(CrashReportingService.instance.setRoute(routeName));
    unawaited(
      CrashReportingService.instance.setContext(
        feature: routeName,
        lastAction: action,
      ),
    );
    unawaited(
      CrashReportingService.instance.breadcrumb(
        action,
        data: {'route': routeName},
      ),
    );
  }

  String _resolveRouteName(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final routeType = route?.runtimeType.toString();
    if (routeType != null && routeType.trim().isNotEmpty) {
      return routeType;
    }
    return 'unknown_route';
  }
}
