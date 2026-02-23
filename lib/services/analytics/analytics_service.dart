import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../privacy/tracking_consent_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> configureCollection() async {
    try {
      if (kIsWeb || !Platform.isIOS) {
        await _analytics.setAnalyticsCollectionEnabled(true);
        return;
      }

      final allowTracking = await TrackingConsentService.instance
          .ensureTrackingAuthorization();
      await _analytics.setAnalyticsCollectionEnabled(allowTracking);
    } catch (_) {}
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
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
