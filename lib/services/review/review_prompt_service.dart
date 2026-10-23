import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../analytics/analytics_service.dart';
import 'review_prompt_policy.dart';
import '../settings/app_settings_repository.dart';
import '../../shared/errors/user_facing_error.dart';

typedef ReviewPromptLogEvent =
    Future<void> Function(String name, {Map<String, Object?>? parameters});

abstract class ReviewPromptSettingsStore {
  List<String> get reviewFeedDays;
  Future<void> setReviewFeedDays(List<String> days);
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
  List<String> get reviewFeedDays => _settings.reviewFeedDays;

  @override
  Future<void> setReviewFeedDays(List<String> days) =>
      _settings.setReviewFeedDays(days);

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
    Future<void> Function(Duration)? delay,
  }) : _reviewGateway = reviewGateway ?? InAppReviewGateway(),
       _settingsStore = settingsStore ?? AppSettingsReviewPromptStore(),
       _nowProvider = nowProvider ?? _defaultNowProvider,
       _shouldRunOnCurrentPlatform =
           shouldRunOnCurrentPlatform ?? _defaultShouldRunOnCurrentPlatform,
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent,
       _delay = delay ?? Future<void>.delayed;

  static final ReviewPromptService instance = ReviewPromptService();

  final AppReviewGateway _reviewGateway;
  final ReviewPromptSettingsStore _settingsStore;
  final DateTime Function() _nowProvider;
  final bool Function() _shouldRunOnCurrentPlatform;
  final ReviewPromptLogEvent _logEvent;
  final Future<void> Function(Duration) _delay;
  Future<bool> _recording = Future<bool>.value(true);
  final _recordedFeedIds = <String>{};
  bool _requestInProgress = false;

  Future<void> onFeedCompletedSuccessfully({
    required String feedId,
    required bool Function() canPrompt,
    Future<void> Function()? waitForFeedback,
  }) async {
    final recording = _recording.then((_) => _recordFeed(feedId));
    _recording = recording;
    if (!await recording || !_shouldRunOnCurrentPlatform()) {
      return;
    }

    if (!_decision().shouldPrompt) {
      return;
    }
    var ownsRequest = false;
    try {
      await waitForFeedback?.call();
      await _delay(const Duration(seconds: 2));
      if (!canPrompt() || _requestInProgress) {
        return;
      }
      final decision = _decision();
      if (!decision.shouldPrompt) {
        return;
      }
      _requestInProgress = true;
      ownsRequest = true;
      final milestone = _milestoneForIndex(
        _settingsStore.reviewNextMilestoneIndex,
      );
      if (await _tryPromptInApp(milestone: milestone, canPrompt: canPrompt)) {
        await _markPromptHandled(
          nowUtc: _nowProvider().toUtc(),
          nextMilestoneIndex: decision.nextMilestoneIndex,
        );
      }
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'review_prompt');
    } finally {
      if (ownsRequest) {
        _requestInProgress = false;
      }
    }
  }

  Future<bool> _recordFeed(String feedId) async {
    try {
      if (_recordedFeedIds.contains(feedId)) {
        return true;
      }
      // Count before day: a failed day write can only delay a prompt.
      await _settingsStore.setReviewFeedSuccessCount(
        _settingsStore.reviewFeedSuccessCount + 1,
      );
      final day = _nowProvider().toIso8601String().split('T').first;
      final days = _settingsStore.reviewFeedDays;
      if (days.length < 2 && !days.contains(day)) {
        await _settingsStore.setReviewFeedDays([...days, day]);
      }
      _recordedFeedIds.add(feedId);
      return true;
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'review_feed_count');
      return false;
    }
  }

  ReviewPromptDecision _decision() {
    final now = _nowProvider().toUtc();
    final nextMilestoneIndex = _settingsStore.reviewNextMilestoneIndex;
    return ReviewPromptPolicy.evaluate(
      updatedFeedCount: _settingsStore.reviewFeedSuccessCount,
      activeFeedDays: _settingsStore.reviewFeedDays.length,
      nextMilestoneIndex: nextMilestoneIndex,
      lastPromptAtUtc: _settingsStore.reviewLastPromptAt,
      nowUtc: now,
    );
  }

  Future<bool> _tryPromptInApp({
    required int? milestone,
    required bool Function() canPrompt,
  }) async {
    bool available = false;
    try {
      available = await _reviewGateway.isAvailable();
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'review_available');
      await _logReviewEvent('review_prompt_failed', {
        'stage': 'is_available',
        'milestone': milestone,
      });
      return false;
    }
    if (!available || !canPrompt()) {
      return false;
    }

    try {
      await _reviewGateway.requestReview();
      await _logReviewEvent('review_prompt_requested', {
        'milestone': milestone,
        'feed_count': _settingsStore.reviewFeedSuccessCount,
        'active_feed_days': _settingsStore.reviewFeedDays.length,
      });
      return true;
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'review_request');
      await _logReviewEvent('review_prompt_failed', {
        'stage': 'request_review',
        'milestone': milestone,
      });
      return false;
    }
  }

  Future<void> openStoreForReview() async {
    try {
      await _reviewGateway.openStoreListing(appStoreId: iosAppStoreId);
      await _logReviewEvent('review_store_opened', {'source': 'profile'});
    } catch (_) {
      await _logReviewEvent('review_store_open_failed', {'source': 'profile'});
      rethrow;
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
    try {
      await _logEvent(name, parameters: parameters);
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'review_analytics');
    }
  }

  int? _milestoneForIndex(int index) {
    if (index < 0 || index >= ReviewPromptPolicy.feedMilestones.length) {
      return null;
    }
    return ReviewPromptPolicy.feedMilestones[index];
  }

  static DateTime _defaultNowProvider() => DateTime.now();

  static bool _defaultShouldRunOnCurrentPlatform() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
