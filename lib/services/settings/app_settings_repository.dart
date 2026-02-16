import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsRepository {
  AppSettingsRepository._();

  static final AppSettingsRepository instance = AppSettingsRepository._();

  static const String _boxName = 'app_settings';
  static const String _preferredLocaleKey = 'preferred_locale_tag';
  static const String _debugProPlanEnabledKey = 'debug_pro_plan_enabled';
  static const String _reviewFeedSuccessCountKey = 'review_feed_success_count';
  static const String _reviewNextMilestoneIndexKey =
      'review_next_milestone_index';
  static const String _reviewLastPromptAtIsoKey = 'review_last_prompt_at_iso';

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
}
