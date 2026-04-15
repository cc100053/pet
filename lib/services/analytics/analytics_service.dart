import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../privacy/tracking_consent_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _analyticsOrNull {
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> configureCollection() async {
    try {
      final analytics = _analyticsOrNull;
      if (analytics == null) {
        return;
      }
      if (kIsWeb || !Platform.isIOS) {
        await analytics.setAnalyticsCollectionEnabled(true);
        return;
      }

      final allowTracking = await TrackingConsentService.instance
          .ensureTrackingAuthorization();
      await analytics.setAnalyticsCollectionEnabled(allowTracking);
    } catch (_) {}
  }

  Future<void> setUserId(String? userId) async {
    try {
      final analytics = _analyticsOrNull;
      if (analytics == null) {
        return;
      }
      await analytics.setUserId(id: userId);
    } catch (_) {}
  }

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    try {
      final analytics = _analyticsOrNull;
      if (analytics == null) {
        return;
      }
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
      await analytics.logEvent(name: name, parameters: sanitized);
    } catch (_) {}
  }

  Future<void> logScreenView(String screenName) async {
    try {
      final analytics = _analyticsOrNull;
      if (analytics == null) {
        return;
      }
      await analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }
}
