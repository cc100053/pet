import '../analytics/analytics_service.dart';

class PerformanceService {
  PerformanceService._();

  static final PerformanceService instance = PerformanceService._();

  DateTime? _appStartTime;
  bool _startupLogged = false;
  bool _chatColdLogged = false;

  void markAppStart(DateTime time) {
    _appStartTime ??= time;
  }

  void markFirstFrameRendered() {
    if (_startupLogged) {
      return;
    }
    final start = _appStartTime;
    if (start == null) {
      return;
    }
    _startupLogged = true;
    final duration = DateTime.now().difference(start);
    AnalyticsService.instance.logEvent('startup_time', parameters: {
      'duration_ms': duration.inMilliseconds,
    });
  }

  void markChatColdLoaded({
    required int messageCount,
    required String source,
    required bool success,
  }) {
    if (_chatColdLogged) {
      return;
    }
    final start = _appStartTime;
    if (start == null) {
      return;
    }
    _chatColdLogged = true;
    final duration = DateTime.now().difference(start);
    AnalyticsService.instance.logEvent('chat_cold_load', parameters: {
      'duration_ms': duration.inMilliseconds,
      'message_count': messageCount,
      'source': source,
      'result': success ? 'success' : 'failure',
    });
  }
}
