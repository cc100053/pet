import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsRepository {
  AppSettingsRepository._();

  static final AppSettingsRepository instance = AppSettingsRepository._();

  static const String _boxName = 'app_settings';
  static const String _preferredLocaleKey = 'preferred_locale_tag';
  static const String _debugProPlanEnabledKey = 'debug_pro_plan_enabled';
  static const String _debugAlwaysShowOnboardingKey =
      'debug_always_show_onboarding';
  static const String _reviewFeedSuccessCountKey = 'review_feed_success_count';
  static const String _reviewNextMilestoneIndexKey =
      'review_next_milestone_index';
  static const String _reviewLastPromptAtIsoKey = 'review_last_prompt_at_iso';
  static const String _ugcTermsAcceptedKey = 'ugc_terms_accepted';
  static const String _onboardingBasicCurrentStepKey =
      'onboarding_basic_current_step';
  static const String _onboardingBasicDismissedKey =
      'onboarding_basic_dismissed';
  static const String _onboardingBasicCompletedKey =
      'onboarding_basic_completed';
  static const String _onboardingBasicStartedAtIsoKey =
      'onboarding_basic_started_at_iso';
  static const String _onboardingBasicCompletedAtIsoKey =
      'onboarding_basic_completed_at_iso';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  /// Stored as a BCP-47 language tag (e.g. "en", "ja", "ko", "zh-Hans", "zh-TW").
  String? get preferredLocaleTag => _box?.get(_preferredLocaleKey) as String?;

  Future<void> setPreferredLocaleTag(String? tag) async {
    if (tag == null) {
      await _box?.delete(_preferredLocaleKey);
    } else {
      await _box?.put(_preferredLocaleKey, tag);
    }
  }

  bool get debugProPlanEnabled =>
      (_box?.get(_debugProPlanEnabledKey) as bool?) ?? false;

  Future<void> setDebugProPlanEnabled(bool enabled) async {
    await _box?.put(_debugProPlanEnabledKey, enabled);
  }

  bool get debugAlwaysShowOnboarding =>
      (_box?.get(_debugAlwaysShowOnboardingKey) as bool?) ?? false;

  Future<void> setDebugAlwaysShowOnboarding(bool enabled) async {
    await _box?.put(_debugAlwaysShowOnboardingKey, enabled);
  }

  int get reviewFeedSuccessCount =>
      (_box?.get(_reviewFeedSuccessCountKey) as int?) ?? 0;

  Future<void> setReviewFeedSuccessCount(int count) async {
    final safeCount = count < 0 ? 0 : count;
    await _box?.put(_reviewFeedSuccessCountKey, safeCount);
  }

  int get reviewNextMilestoneIndex =>
      (_box?.get(_reviewNextMilestoneIndexKey) as int?) ?? 0;

  Future<void> setReviewNextMilestoneIndex(int index) async {
    final safeIndex = index < 0 ? 0 : index;
    await _box?.put(_reviewNextMilestoneIndexKey, safeIndex);
  }

  DateTime? get reviewLastPromptAt {
    final iso = _box?.get(_reviewLastPromptAtIsoKey) as String?;
    if (iso == null || iso.isEmpty) {
      return null;
    }
    return DateTime.tryParse(iso)?.toUtc();
  }

  Future<void> setReviewLastPromptAt(DateTime? value) async {
    if (value == null) {
      await _box?.delete(_reviewLastPromptAtIsoKey);
      return;
    }
    await _box?.put(_reviewLastPromptAtIsoKey, value.toUtc().toIso8601String());
  }

  bool get ugcTermsAccepted =>
      (_box?.get(_ugcTermsAcceptedKey) as bool?) ?? false;

  Future<void> setUgcTermsAccepted(bool accepted) async {
    await _box?.put(_ugcTermsAcceptedKey, accepted);
  }

  String? get onboardingBasicCurrentStep =>
      _box?.get(_onboardingBasicCurrentStepKey) as String?;

  Future<void> setOnboardingBasicCurrentStep(String? step) async {
    if (step == null || step.isEmpty) {
      await _box?.delete(_onboardingBasicCurrentStepKey);
      return;
    }
    await _box?.put(_onboardingBasicCurrentStepKey, step);
  }

  bool get onboardingBasicDismissed =>
      (_box?.get(_onboardingBasicDismissedKey) as bool?) ?? false;

  Future<void> setOnboardingBasicDismissed(bool dismissed) async {
    await _box?.put(_onboardingBasicDismissedKey, dismissed);
  }

  bool get onboardingBasicCompleted =>
      (_box?.get(_onboardingBasicCompletedKey) as bool?) ?? false;

  Future<void> setOnboardingBasicCompleted(bool completed) async {
    await _box?.put(_onboardingBasicCompletedKey, completed);
  }

  DateTime? get onboardingBasicStartedAt {
    final iso = _box?.get(_onboardingBasicStartedAtIsoKey) as String?;
    if (iso == null || iso.isEmpty) {
      return null;
    }
    return DateTime.tryParse(iso)?.toUtc();
  }

  Future<void> setOnboardingBasicStartedAt(DateTime? value) async {
    if (value == null) {
      await _box?.delete(_onboardingBasicStartedAtIsoKey);
      return;
    }
    await _box?.put(
      _onboardingBasicStartedAtIsoKey,
      value.toUtc().toIso8601String(),
    );
  }

  DateTime? get onboardingBasicCompletedAt {
    final iso = _box?.get(_onboardingBasicCompletedAtIsoKey) as String?;
    if (iso == null || iso.isEmpty) {
      return null;
    }
    return DateTime.tryParse(iso)?.toUtc();
  }

  Future<void> setOnboardingBasicCompletedAt(DateTime? value) async {
    if (value == null) {
      await _box?.delete(_onboardingBasicCompletedAtIsoKey);
      return;
    }
    await _box?.put(
      _onboardingBasicCompletedAtIsoKey,
      value.toUtc().toIso8601String(),
    );
  }
}
