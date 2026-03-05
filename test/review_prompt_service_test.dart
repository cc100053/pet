import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/review/review_prompt_service.dart';

class _FakeSettingsStore implements ReviewPromptSettingsStore {
  _FakeSettingsStore({
    this.feedSuccessCount = 0,
    this.nextMilestoneIndex = 0,
    this.lastPromptAt,
  });

  int feedSuccessCount;
  int nextMilestoneIndex;
  DateTime? lastPromptAt;

  @override
  int get reviewFeedSuccessCount => feedSuccessCount;

  @override
  Future<void> setReviewFeedSuccessCount(int count) async {
    feedSuccessCount = count;
  }

  @override
  int get reviewNextMilestoneIndex => nextMilestoneIndex;

  @override
  Future<void> setReviewNextMilestoneIndex(int index) async {
    nextMilestoneIndex = index;
  }

  @override
  DateTime? get reviewLastPromptAt => lastPromptAt;

  @override
  Future<void> setReviewLastPromptAt(DateTime? value) async {
    lastPromptAt = value;
  }
}

class _FakeReviewGateway implements AppReviewGateway {
  _FakeReviewGateway({
    required this.available,
    this.throwOnRequestReview = false,
    this.throwOnOpenStore = false,
  });

  bool available;
  bool throwOnRequestReview;
  bool throwOnOpenStore;

  int requestReviewCalls = 0;
  int openStoreCalls = 0;
  String? lastOpenedAppStoreId;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestReviewCalls += 1;
    if (throwOnRequestReview) {
      throw Exception('request review failed');
    }
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {
    openStoreCalls += 1;
    lastOpenedAppStoreId = appStoreId;
    if (throwOnOpenStore) {
      throw Exception('open store failed');
    }
  }
}

void main() {
  test('uses in-app review when available and milestone reached', () async {
    final settings = _FakeSettingsStore(
      feedSuccessCount: 9,
      nextMilestoneIndex: 0,
      lastPromptAt: DateTime.utc(2026, 1, 1),
    );
    final gateway = _FakeReviewGateway(available: true);
    final events = <String>[];
    final now = DateTime.utc(2026, 3, 5, 12);
    final service = ReviewPromptService(
      reviewGateway: gateway,
      settingsStore: settings,
      nowProvider: () => now,
      shouldRunOnCurrentPlatform: () => true,
      logEvent: (name, {parameters}) async => events.add(name),
    );

    await service.onFeedCompletedSuccessfully();

    expect(settings.reviewFeedSuccessCount, 10);
    expect(settings.reviewNextMilestoneIndex, 1);
    expect(settings.reviewLastPromptAt, now);
    expect(gateway.requestReviewCalls, 1);
    expect(gateway.openStoreCalls, 0);
    expect(events, contains('review_prompt_shown'));
  });

  test('opens App Store fallback when in-app review is unavailable', () async {
    final settings = _FakeSettingsStore(
      feedSuccessCount: 9,
      nextMilestoneIndex: 0,
    );
    final gateway = _FakeReviewGateway(available: false);
    final events = <String>[];
    final now = DateTime.utc(2026, 3, 5, 12);
    final service = ReviewPromptService(
      reviewGateway: gateway,
      settingsStore: settings,
      nowProvider: () => now,
      shouldRunOnCurrentPlatform: () => true,
      logEvent: (name, {parameters}) async => events.add(name),
    );

    await service.onFeedCompletedSuccessfully();

    expect(settings.reviewFeedSuccessCount, 10);
    expect(settings.reviewNextMilestoneIndex, 1);
    expect(settings.reviewLastPromptAt, now);
    expect(gateway.requestReviewCalls, 0);
    expect(gateway.openStoreCalls, 1);
    expect(gateway.lastOpenedAppStoreId, ReviewPromptService.iosAppStoreId);
    expect(events, contains('review_store_opened'));
  });

  test('falls back to App Store when requestReview throws', () async {
    final settings = _FakeSettingsStore(
      feedSuccessCount: 9,
      nextMilestoneIndex: 0,
    );
    final gateway = _FakeReviewGateway(
      available: true,
      throwOnRequestReview: true,
    );
    final events = <String>[];
    final now = DateTime.utc(2026, 3, 5, 12);
    final service = ReviewPromptService(
      reviewGateway: gateway,
      settingsStore: settings,
      nowProvider: () => now,
      shouldRunOnCurrentPlatform: () => true,
      logEvent: (name, {parameters}) async => events.add(name),
    );

    await service.onFeedCompletedSuccessfully();

    expect(settings.reviewFeedSuccessCount, 10);
    expect(settings.reviewNextMilestoneIndex, 1);
    expect(settings.reviewLastPromptAt, now);
    expect(gateway.requestReviewCalls, 1);
    expect(gateway.openStoreCalls, 1);
    expect(events, contains('review_prompt_failed'));
    expect(events, contains('review_store_opened'));
  });

  test('does not advance milestone when store fallback also fails', () async {
    final settings = _FakeSettingsStore(
      feedSuccessCount: 9,
      nextMilestoneIndex: 0,
    );
    final gateway = _FakeReviewGateway(
      available: false,
      throwOnOpenStore: true,
    );
    final events = <String>[];
    final now = DateTime.utc(2026, 3, 5, 12);
    final service = ReviewPromptService(
      reviewGateway: gateway,
      settingsStore: settings,
      nowProvider: () => now,
      shouldRunOnCurrentPlatform: () => true,
      logEvent: (name, {parameters}) async => events.add(name),
    );

    await service.onFeedCompletedSuccessfully();

    expect(settings.reviewFeedSuccessCount, 10);
    expect(settings.reviewNextMilestoneIndex, 0);
    expect(settings.reviewLastPromptAt, isNull);
    expect(gateway.requestReviewCalls, 0);
    expect(gateway.openStoreCalls, 1);
    expect(events, contains('review_store_open_failed'));
  });
}
