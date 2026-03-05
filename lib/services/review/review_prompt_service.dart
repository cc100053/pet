import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../analytics/analytics_service.dart';
import 'review_prompt_policy.dart';
import '../settings/app_settings_repository.dart';

typedef ReviewPromptLogEvent =
    Future<void> Function(String name, {Map<String, Object?>? parameters});

abstract class ReviewPromptSettingsStore {
  int get reviewFeedSuccessCount;
  Future<void> setReviewFeedSuccessCount(int count);
  int get reviewNextMilestoneIndex;
  Future<void> setReviewNextMilestoneIndex(int index);
  DateTime? get reviewLastPromptAt;
  Future<void> setReviewLastPromptAt(DateTime? value);
}

class AppSettingsReviewPromptStore implements ReviewPromptSettingsStore {
  AppSettingsReviewPromptStore({AppSettingsRepository? settings})
    : _settings = settings ?? AppSettingsRepository.instance;

  final AppSettingsRepository _settings;

  @override
  int get reviewFeedSuccessCount => _settings.reviewFeedSuccessCount;

  @override
  Future<void> setReviewFeedSuccessCount(int count) {
    return _settings.setReviewFeedSuccessCount(count);
  }

  @override
  int get reviewNextMilestoneIndex => _settings.reviewNextMilestoneIndex;

  @override
  Future<void> setReviewNextMilestoneIndex(int index) {
    return _settings.setReviewNextMilestoneIndex(index);
  }

  @override
  DateTime? get reviewLastPromptAt => _settings.reviewLastPromptAt;

  @override
  Future<void> setReviewLastPromptAt(DateTime? value) {
    return _settings.setReviewLastPromptAt(value);
  }
}

abstract class AppReviewGateway {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing({required String appStoreId});
}

class InAppReviewGateway implements AppReviewGateway {
  InAppReviewGateway({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();

  @override
  Future<void> openStoreListing({required String appStoreId}) {
    return _inAppReview.openStoreListing(appStoreId: appStoreId);
  }
}

class ReviewPromptService {
  static const String iosAppStoreId = '6757725650';

  ReviewPromptService({
    AppReviewGateway? reviewGateway,
    ReviewPromptSettingsStore? settingsStore,
    DateTime Function()? nowProvider,
    bool Function()? shouldRunOnCurrentPlatform,
    ReviewPromptLogEvent? logEvent,
  }) : _reviewGateway = reviewGateway ?? InAppReviewGateway(),
       _settingsStore = settingsStore ?? AppSettingsReviewPromptStore(),
       _nowProvider = nowProvider ?? _defaultNowProvider,
       _shouldRunOnCurrentPlatform =
           shouldRunOnCurrentPlatform ?? _defaultShouldRunOnCurrentPlatform,
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent;

  static final ReviewPromptService instance = ReviewPromptService();

  final AppReviewGateway _reviewGateway;
  final ReviewPromptSettingsStore _settingsStore;
  final DateTime Function() _nowProvider;
  final bool Function() _shouldRunOnCurrentPlatform;
  final ReviewPromptLogEvent _logEvent;

  Future<void> onFeedCompletedSuccessfully() async {
    final updatedFeedCount = _settingsStore.reviewFeedSuccessCount + 1;
    await _settingsStore.setReviewFeedSuccessCount(updatedFeedCount);

    if (!_shouldRunOnCurrentPlatform()) {
      return;
    }

    final now = _nowProvider().toUtc();
    final nextMilestoneIndex = _settingsStore.reviewNextMilestoneIndex;
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: updatedFeedCount,
      nextMilestoneIndex: nextMilestoneIndex,
      lastPromptAtUtc: _settingsStore.reviewLastPromptAt,
      nowUtc: now,
    );
    if (!decision.shouldPrompt) {
      return;
    }

    final milestone = _milestoneForIndex(nextMilestoneIndex);
    final promptedInApp = await _tryPromptInApp(milestone: milestone);
    if (promptedInApp) {
      await _markPromptHandled(
        nowUtc: now,
        nextMilestoneIndex: decision.nextMilestoneIndex,
      );
      return;
    }

    final openedStore = await _tryOpenStoreFallback(milestone: milestone);
    if (!openedStore) {
      return;
    }

    await _markPromptHandled(
      nowUtc: now,
      nextMilestoneIndex: decision.nextMilestoneIndex,
    );
  }

  Future<bool> _tryPromptInApp({required int? milestone}) async {
    bool available = false;
    try {
      available = await _reviewGateway.isAvailable();
    } catch (_) {
      await _logReviewEvent('review_prompt_failed', {
        'stage': 'is_available',
        'milestone': milestone,
      });
      return false;
    }
    if (!available) {
      return false;
    }

    try {
      await _reviewGateway.requestReview();
      await _logReviewEvent('review_prompt_shown', {'milestone': milestone});
      return true;
    } catch (_) {
      await _logReviewEvent('review_prompt_failed', {
        'stage': 'request_review',
        'milestone': milestone,
      });
      return false;
    }
  }

  Future<bool> _tryOpenStoreFallback({required int? milestone}) async {
    try {
      await _reviewGateway.openStoreListing(appStoreId: iosAppStoreId);
      await _logReviewEvent('review_store_opened', {'milestone': milestone});
      return true;
    } catch (_) {
      await _logReviewEvent('review_store_open_failed', {
        'milestone': milestone,
      });
      return false;
    }
  }

  Future<void> _markPromptHandled({
    required DateTime nowUtc,
    required int nextMilestoneIndex,
  }) async {
    await _settingsStore.setReviewLastPromptAt(nowUtc);
    await _settingsStore.setReviewNextMilestoneIndex(nextMilestoneIndex);
  }

  Future<void> _logReviewEvent(
    String name,
    Map<String, Object?> parameters,
  ) async {
    await _logEvent(name, parameters: parameters);
  }

  int? _milestoneForIndex(int index) {
    if (index < 0 || index >= ReviewPromptPolicy.feedMilestones.length) {
      return null;
    }
    return ReviewPromptPolicy.feedMilestones[index];
  }

  static DateTime _defaultNowProvider() => DateTime.now().toUtc();

  static bool _defaultShouldRunOnCurrentPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
