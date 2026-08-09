import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'crash_reporting_service.dart';

/// How the previous session ended, as far as we can tell on the next launch.
enum PreviousExitKind {
  /// No prior session recorded (fresh install, or storage was cleared).
  unknown,

  /// The app was shut down through a lifecycle path we observed.
  clean,

  /// The previous run recorded a crash, which Crashlytics already reported.
  crash,

  /// The process disappeared while in the background. Routine on both
  /// platforms: the OS reclaims backgrounded apps constantly.
  backgroundTermination,

  /// The process disappeared while the user was actively looking at it, and no
  /// crash was recorded. Nothing caught it because nothing *can* catch it: an
  /// OOM kill is a SIGKILL. This is the high-signal case.
  foregroundUnclean,
}

/// Detects process deaths that leave no crash report — most importantly
/// out-of-memory kills.
///
/// An OOM kill cannot be caught in-process. The OS sends SIGKILL, no handler
/// runs, and Crashlytics records nothing, so the app simply vanishes from
/// telemetry. The only way to see these is retroactively: write a sentinel
/// while running, clear it on an orderly shutdown, and on the next launch treat
/// a still-open sentinel with no accompanying crash report as a kill.
///
/// The sentinel also carries the last known context (route, memory warnings) so
/// the posthumous report says *where* the app died, not just that it did.
class UncleanExitService with WidgetsBindingObserver {
  UncleanExitService._();

  static final UncleanExitService instance = UncleanExitService._();

  static const MethodChannel _exitReasonChannel = MethodChannel(
    'pet/process_exit_reasons',
  );

  static const String _boxName = 'unclean_exit_sentinel';
  static const String _sessionOpenKey = 'session_open';
  static const String _lifecycleKey = 'lifecycle';
  static const String _routeKey = 'route';
  static const String _featureKey = 'feature';
  static const String _roomIdKey = 'room_id';
  static const String _lastActionKey = 'last_action';
  static const String _memoryWarningCountKey = 'memory_warning_count';
  static const String _appVersionKey = 'app_version';
  static const String _startedAtKey = 'started_at_iso';
  static const String _lastResumedAtKey = 'last_resumed_at_iso';

  Box<dynamic>? _box;
  bool _initialized = false;
  PreviousExitKind _previousExit = PreviousExitKind.unknown;

  PreviousExitKind get previousExit => _previousExit;

  /// Must run after Crashlytics is initialized (it consults
  /// `didCrashOnPreviousExecution`) and before the first frame, so the sentinel
  /// covers the whole session.
  Future<void> initialize({String appVersion = 'unknown'}) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (error, stackTrace) {
      // Without the box we cannot detect anything, but the app must still boot.
      await CrashReportingService.instance.reportError(
        error: error,
        stackTrace: stackTrace,
        source: 'unclean_exit_open_box',
      );
      return;
    }

    // Evaluate before overwriting: the stored values describe the *previous*
    // run.
    _previousExit = await _evaluatePreviousSession();

    WidgetsBinding.instance.addObserver(this);
    await _openSession(appVersion: appVersion);
    await _reportAndroidExitReason();
  }

  /// Android 11+ records why the previous process died. That beats the
  /// sentinel's inference, so when it is available we attach it as context.
  Future<void> _reportAndroidExitReason() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final info = await _exitReasonChannel.invokeMapMethod<String, dynamic>(
        'getLastExitReason',
      );
      if (info == null) {
        return;
      }
      final reasonName = (info['reason_name'] as String?) ?? 'unknown';
      final wasForeground = info['was_foreground'] == true;

      await CrashReportingService.instance.setCustomKeys(<String, Object?>{
        'android_exit_reason': reasonName,
        'android_exit_was_foreground': wasForeground,
        'android_exit_rss_kb': info['rss_kb'],
        'android_exit_pss_kb': info['pss_kb'],
      });
      await CrashReportingService.instance.breadcrumb(
        'android_previous_exit',
        data: <String, Object?>{
          'reason': reasonName,
          'was_foreground': wasForeground,
          'description': info['description'],
        },
      );
    } catch (_) {
      // Older devices and non-standard ROMs simply do not provide this.
    }
  }

  Future<PreviousExitKind> _evaluatePreviousSession() async {
    final box = _box;
    if (box == null || box.isEmpty) {
      return PreviousExitKind.unknown;
    }

    final sessionWasOpen = box.get(_sessionOpenKey) == true;
    if (!sessionWasOpen) {
      return PreviousExitKind.clean;
    }

    // A recorded crash is already in Crashlytics; reporting it again here would
    // double-count it.
    if (await CrashReportingService.instance.didCrashOnPreviousExecution()) {
      await CrashReportingService.instance.breadcrumb(
        'previous_session_crashed',
        data: <String, Object?>{'route': box.get(_routeKey)},
      );
      return PreviousExitKind.crash;
    }

    final lifecycle = (box.get(_lifecycleKey) as String?) ?? 'unknown';
    final wasForeground = lifecycle == 'resumed';
    final kind = wasForeground
        ? PreviousExitKind.foregroundUnclean
        : PreviousExitKind.backgroundTermination;

    await _reportUncleanExit(box: box, kind: kind, lifecycle: lifecycle);
    return kind;
  }

  Future<void> _reportUncleanExit({
    required Box<dynamic> box,
    required PreviousExitKind kind,
    required String lifecycle,
  }) async {
    final route = (box.get(_routeKey) as String?) ?? 'unknown';
    final feature = (box.get(_featureKey) as String?) ?? 'unknown';
    final roomId = (box.get(_roomIdKey) as String?) ?? 'none';
    final lastAction = (box.get(_lastActionKey) as String?) ?? 'unknown';
    final memoryWarnings = (box.get(_memoryWarningCountKey) as int?) ?? 0;
    final appVersion = (box.get(_appVersionKey) as String?) ?? 'unknown';
    final startedAt = (box.get(_startedAtKey) as String?) ?? 'unknown';
    final lastResumedAt = (box.get(_lastResumedAtKey) as String?) ?? 'unknown';

    await CrashReportingService.instance.setCustomKeys(<String, Object?>{
      'previous_exit': kind.name,
      'previous_exit_route': route,
      'previous_exit_lifecycle': lifecycle,
      'previous_exit_memory_warnings': memoryWarnings,
      'previous_exit_app_version': appVersion,
      // `started_at` is process start, which on iOS can predate the kill by
      // more than a day of suspend/resume cycles. Without the last resume the
      // two are indistinguishable, and a long-suspended session that died on
      // resume reads identically to a session that grew until it was killed.
      'previous_exit_last_resumed_at': lastResumedAt,
    });

    // A backgrounded app being reclaimed is normal OS behaviour and would be
    // pure noise as a report; a breadcrumb is enough to correlate it later.
    if (kind != PreviousExitKind.foregroundUnclean) {
      await CrashReportingService.instance.breadcrumb(
        'previous_background_termination',
        data: <String, Object?>{
          'route': route,
          'memory_warnings': memoryWarnings,
        },
      );
      return;
    }

    // Memory warnings immediately before a foreground kill are the signature of
    // an OOM; without them the cause is more likely a native crash or a
    // watchdog termination.
    final suspectedCause = memoryWarnings > 0
        ? 'out_of_memory'
        : 'unknown_process_kill';

    await CrashReportingService.instance.reportError(
      error: UncleanExitException(
        route: route,
        memoryWarnings: memoryWarnings,
        suspectedCause: suspectedCause,
      ),
      // Synthesized on the next launch: the real stack died with the process.
      // Grouping comes from the exception's route and cause instead.
      stackTrace: StackTrace.current,
      source: 'unclean_exit',
      reason: 'unclean_exit/$suspectedCause/$route',
      information: <Object>[
        'suspected_cause: $suspectedCause',
        'route: $route',
        'feature: $feature',
        'room_id: $roomId',
        'last_action: $lastAction',
        'memory_warnings: $memoryWarnings',
        'lifecycle_at_death: $lifecycle',
        'app_version: $appVersion',
        'session_started_at: $startedAt',
        'last_resumed_at: $lastResumedAt',
      ],
    );
  }

  Future<void> _openSession({required String appVersion}) async {
    final startedAt = DateTime.now().toUtc().toIso8601String();
    await _write(<String, Object?>{
      _sessionOpenKey: true,
      _lifecycleKey: 'resumed',
      _appVersionKey: appVersion,
      _startedAtKey: startedAt,
      _lastResumedAtKey: startedAt,
      _memoryWarningCountKey: 0,
      _routeKey: CrashReportingService.instance.currentRoute,
      _featureKey: CrashReportingService.instance.currentFeature,
      _roomIdKey: CrashReportingService.instance.currentRoomId,
      _lastActionKey: CrashReportingService.instance.currentLastAction,
    });
  }

  /// Refreshes the stored context so a later kill reports where it happened.
  Future<void> recordContext() async {
    if (_box == null) {
      return;
    }
    await _write(<String, Object?>{
      _routeKey: CrashReportingService.instance.currentRoute,
      _featureKey: CrashReportingService.instance.currentFeature,
      _roomIdKey: CrashReportingService.instance.currentRoomId,
      _lastActionKey: CrashReportingService.instance.currentLastAction,
    });
  }

  /// Records an OS memory warning. The count is what separates a suspected OOM
  /// from an unexplained kill on the next launch.
  Future<void> recordMemoryWarning(int count) async {
    await _write(<String, Object?>{_memoryWarningCountKey: count});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_recordLifecycle(state));
    if (state == AppLifecycleState.detached) {
      // The one lifecycle callback that means an orderly shutdown.
      unawaited(_closeSession());
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _recordLifecycle(AppLifecycleState state) async {
    final values = <String, Object?>{_lifecycleKey: state.name};
    if (state == AppLifecycleState.resumed) {
      values[_lastResumedAtKey] = DateTime.now().toUtc().toIso8601String();
    }
    await _write(values);
    // The whole foreground/background classification rests on this value being
    // on disk when the process dies. A queued write is not, and the callback is
    // synchronous so it cannot be awaited by the framework, so force the flush
    // here while the app still has time to run.
    await _flush();
  }

  Future<void> _flush() async {
    try {
      await _box?.flush();
    } catch (_) {
      // Best-effort durability; a failed flush must never break the app.
    }
  }

  Future<void> _closeSession() async {
    await _write(<String, Object?>{_sessionOpenKey: false});
  }

  Future<void> _write(Map<String, Object?> values) async {
    final box = _box;
    if (box == null) {
      return;
    }
    try {
      await box.putAll(values);
    } catch (_) {
      // Sentinel bookkeeping is best-effort and must never break the app.
    }
  }

  @visibleForTesting
  Future<void> debugInitializeWith({
    required Box<dynamic> box,
    String appVersion = 'test',
  }) async {
    _box = box;
    _previousExit = await _evaluatePreviousSession();
    await _openSession(appVersion: appVersion);
  }

  @visibleForTesting
  Future<void> debugCloseSession() => _closeSession();

  @visibleForTesting
  void resetDebugState() {
    _initialized = false;
    _box = null;
    _previousExit = PreviousExitKind.unknown;
  }
}

/// Synthetic error used to surface a process death that produced no crash
/// report. It is raised on the launch *after* the death.
class UncleanExitException implements Exception {
  const UncleanExitException({
    required this.route,
    required this.memoryWarnings,
    required this.suspectedCause,
  });

  final String route;
  final int memoryWarnings;
  final String suspectedCause;

  @override
  String toString() =>
      'UncleanExitException($suspectedCause at $route, '
      'memoryWarnings=$memoryWarnings)';
}
