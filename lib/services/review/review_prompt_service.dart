import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'review_prompt_policy.dart';
import '../settings/app_settings_repository.dart';

class ReviewPromptService {
  ReviewPromptService({
    InAppReview? inAppReview,
    AppSettingsRepository? settings,
  }) : _inAppReview = inAppReview ?? InAppReview.instance,
       _settings = settings ?? AppSettingsRepository.instance;

  static final ReviewPromptService instance = ReviewPromptService();

  final InAppReview _inAppReview;
  final AppSettingsRepository _settings;

  Future<void> onFeedCompletedSuccessfully() async {
    final updatedFeedCount = _settings.reviewFeedSuccessCount + 1;
    await _settings.setReviewFeedSuccessCount(updatedFeedCount);

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final now = DateTime.now().toUtc();
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: updatedFeedCount,
      nextMilestoneIndex: _settings.reviewNextMilestoneIndex,
      lastPromptAtUtc: _settings.reviewLastPromptAt,
      nowUtc: now,
    );
    if (!decision.shouldPrompt) {
      return;
    }

    final available = await _inAppReview.isAvailable();
    if (!available) {
      return;
    }

    await _inAppReview.requestReview();
    await _settings.setReviewLastPromptAt(now);
    await _settings.setReviewNextMilestoneIndex(decision.nextMilestoneIndex);
  }
}
