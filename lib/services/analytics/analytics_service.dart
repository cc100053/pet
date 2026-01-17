import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      Map<String, Object>? sanitized;
      if (parameters != null) {
        final cleaned = <String, Object>{};
        for (final entry in parameters.entries) {
          final value = entry.value;
          if (value != null) {
            cleaned[entry.key] = value;
          }
        }
        if (cleaned.isNotEmpty) {
          sanitized = cleaned;
        }
      }
      await _analytics.logEvent(name: name, parameters: sanitized);
    } catch (_) {}
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }
}
