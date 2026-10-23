import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pet/services/review/review_prompt_service.dart';
import 'package:pet/services/settings/app_settings_repository.dart';

class _FakeSettingsStore implements ReviewPromptSettingsStore {
  @override
  int reviewFeedSuccessCount = 4;
  @override
  int reviewNextMilestoneIndex = 0;
  @override
  DateTime? reviewLastPromptAt;
  @override
  List<String> reviewFeedDays = ['2026-10-23'];

  @override
  Future<void> setReviewFeedSuccessCount(int count) async {
    reviewFeedSuccessCount = count;
  }

  @override
  Future<void> setReviewNextMilestoneIndex(int index) async {
    reviewNextMilestoneIndex = index;
  }

  @override
  Future<void> setReviewLastPromptAt(DateTime? value) async {
    reviewLastPromptAt = value;
  }

  bool throwOnSetDays = false;

  @override
  Future<void> setReviewFeedDays(List<String> days) async {
    if (throwOnSetDays) throw StateError('days write failed');
    reviewFeedDays = days;
  }
}

class _FakeReviewGateway implements AppReviewGateway {
  bool available = true;
  bool throwOnAvailable = false;
  bool throwOnRequest = false;
  bool throwOnOpenStore = false;
  Completer<void>? requestGate;
  void Function()? onAvailable;
  int requestCalls = 0;
  int storeCalls = 0;
  String? storeId;

  @override
  Future<bool> isAvailable() async {
    onAvailable?.call();
    if (throwOnAvailable) throw StateError('availability failed');
    return available;
  }

  @override
  Future<void> requestReview() async {
    requestCalls++;
    await requestGate?.future;
    if (throwOnRequest) throw StateError('request failed');
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {
    storeCalls++;
    storeId = appStoreId;
    if (throwOnOpenStore) throw StateError('store failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeSettingsStore settings;
  late _FakeReviewGateway gateway;
  late ReviewPromptService service;
  late DateTime now;
  late Map<String, Map<String, Object?>?> events;
  late bool canPrompt;
  late bool supported;
  late bool failAnalytics;
  late List<Duration> delays;
  late Future<void> Function(Duration) delay;

  setUp(() {
    settings = _FakeSettingsStore();
    gateway = _FakeReviewGateway();
    now = DateTime(2026, 10, 24, 12);
    events = {};
    canPrompt = true;
    supported = true;
    failAnalytics = false;
    delays = [];
    delay = (duration) async {
      delays.add(duration);
    };
    service = ReviewPromptService(
      settingsStore: settings,
      reviewGateway: gateway,
      nowProvider: () => now,
      shouldRunOnCurrentPlatform: () => supported,
      delay: (duration) => delay(duration),
      logEvent: (name, {parameters}) async {
        if (failAnalytics) throw StateError('analytics unavailable');
        events[name] = parameters;
      },
    );
  });

  Future<void> feed(String id, {Future<void> Function()? feedback}) =>
      service.onFeedCompletedSuccessfully(
        feedId: id,
        canPrompt: () => canPrompt,
        waitForFeedback: feedback,
      );

  test(
    'requests native review after fifth feed on second day, then records cooldown',
    () async {
      await feed('a');
      expect(settings.reviewFeedSuccessCount, 5);
      expect(settings.reviewFeedDays, ['2026-10-23', '2026-10-24']);
      expect(settings.reviewNextMilestoneIndex, 1);
      expect(settings.reviewLastPromptAt, now.toUtc());
      expect(gateway.requestCalls, 1);
      expect(gateway.storeCalls, 0);
      expect(delays, [const Duration(seconds: 2)]);
      expect(events['review_prompt_requested']?['feed_count'], 5);
      expect(events, isNot(contains('review_prompt_shown')));
    },
  );

  test('failed day write still counts the feed but cannot prompt', () async {
    settings.throwOnSetDays = true;
    await feed('a');
    expect(settings.reviewFeedSuccessCount, 5);
    expect(settings.reviewFeedDays, ['2026-10-23']);
    expect(gateway.requestCalls, 0);
  });

  test(
    'same-day feeds do not qualify; date change does, and storage stops at two days',
    () async {
      settings.reviewFeedDays = [];
      for (var i = 0; i < 6; i++) {
        await feed('day1-$i');
      }
      expect(settings.reviewFeedDays, ['2026-10-24']);
      expect(gateway.requestCalls, 0);
      now = DateTime(2026, 10, 25);
      await feed('day2');
      expect(gateway.requestCalls, 1);
      now = DateTime(2026, 10, 26);
      await feed('day3');
      expect(settings.reviewFeedDays, ['2026-10-24', '2026-10-25']);
      expect(gateway.requestCalls, 1);
    },
  );

  test(
    'duplicate and interleaved Home/Chat callbacks count each feed once',
    () async {
      await Future.wait([feed('a'), feed('b'), feed('a'), feed('b')]);
      expect(settings.reviewFeedSuccessCount, 6);
      expect(gateway.requestCalls, 1);
      expect(settings.reviewNextMilestoneIndex, 1);
    },
  );

  test(
    'waits for feedback and settling; abandoning screen does not spend request',
    () async {
      final feedback = Completer<void>();
      final settling = Completer<void>();
      delay = (_) => settling.future;
      final pending = feed('a', feedback: () => feedback.future);
      await Future<void>.delayed(Duration.zero);
      expect(gateway.requestCalls, 0);
      feedback.complete();
      await Future<void>.delayed(Duration.zero);
      expect(gateway.requestCalls, 0);
      canPrompt = false;
      settling.complete();
      await pending;
      expect(gateway.requestCalls, 0);
      expect(settings.reviewLastPromptAt, isNull);
      expect(settings.reviewNextMilestoneIndex, 0);
    },
  );

  test('rechecks screen after async availability lookup', () async {
    gateway.onAvailable = () => canPrompt = false;
    await feed('a');
    expect(gateway.requestCalls, 0);
    expect(settings.reviewLastPromptAt, isNull);
  });

  test(
    'only one native request can run while duplicate callback completes',
    () async {
      gateway.requestGate = Completer<void>();
      final first = feed('a');
      await Future<void>.delayed(Duration.zero);
      await feed('a');
      await feed('b');
      expect(gateway.requestCalls, 1);
      gateway.requestGate!.complete();
      await first;
      expect(settings.reviewFeedSuccessCount, 6);
    },
  );

  for (final failure in ['unavailable', 'availability', 'request']) {
    test(
      '$failure never opens store or consumes milestone; next feed can retry',
      () async {
        gateway.available = failure != 'unavailable';
        gateway.throwOnAvailable = failure == 'availability';
        gateway.throwOnRequest = failure == 'request';
        await feed('a');
        expect(gateway.storeCalls, 0);
        expect(settings.reviewLastPromptAt, isNull);
        expect(settings.reviewNextMilestoneIndex, 0);
        gateway.available = true;
        gateway.throwOnAvailable = gateway.throwOnRequest = false;
        await feed('b');
        expect(settings.reviewNextMilestoneIndex, 1);
      },
    );
  }

  test(
    'preserves upgraded count/index/date and resumes beyond lifetime milestones',
    () async {
      settings.reviewFeedSuccessCount = 200;
      settings.reviewNextMilestoneIndex = 5;
      settings.reviewLastPromptAt = now.toUtc().subtract(
        const Duration(days: 89),
      );
      await feed('a');
      expect(gateway.requestCalls, 0);
      expect(settings.reviewFeedSuccessCount, 201);
      now = now.add(const Duration(days: 1));
      await feed('b');
      expect(gateway.requestCalls, 1);
      expect(settings.reviewNextMilestoneIndex, 5);
    },
  );

  test(
    'manual store link opens review page without changing automatic eligibility',
    () async {
      await service.openStoreForReview();
      expect(gateway.storeCalls, 1);
      expect(gateway.storeId, ReviewPromptService.iosAppStoreId);
      expect(gateway.requestCalls, 0);
      expect(settings.reviewLastPromptAt, isNull);
      expect(settings.reviewNextMilestoneIndex, 0);
      expect(events['review_store_opened']?['source'], 'profile');
      gateway.throwOnOpenStore = true;
      await expectLater(service.openStoreForReview(), throwsStateError);
      expect(events, contains('review_store_open_failed'));
    },
  );

  test(
    'unsupported platform records feeds without review or store requests',
    () async {
      supported = false;
      await feed('a');
      expect(settings.reviewFeedSuccessCount, 5);
      expect(gateway.requestCalls, 0);
      expect(gateway.storeCalls, 0);
      expect(delays, isEmpty);
    },
  );

  test(
    'analytics failure cannot undo a native request or allow repeat requests',
    () async {
      failAnalytics = true;
      await feed('a');
      await feed('b');
      expect(gateway.requestCalls, 1);
      expect(settings.reviewLastPromptAt, now.toUtc());
      expect(settings.reviewNextMilestoneIndex, 1);
    },
  );

  test(
    'Hive adapter preserves legacy history while persisting new feed days',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'review-settings-',
      );
      Hive.init(directory.path);
      final priorRequest = now.toUtc().subtract(const Duration(days: 10));
      final box = await Hive.openBox<dynamic>('app_settings');
      await box.putAll({
        'review_feed_success_count': 200,
        'review_next_milestone_index': 5,
        'review_last_prompt_at_iso': priorRequest.toIso8601String(),
      });
      await box.close();
      try {
        await AppSettingsRepository.instance.init();
        final store = AppSettingsReviewPromptStore();
        final persistedService = ReviewPromptService(
          settingsStore: store,
          reviewGateway: gateway,
          nowProvider: () => now,
          shouldRunOnCurrentPlatform: () => true,
          delay: delay,
          logEvent: (name, {parameters}) async {},
        );
        await persistedService.onFeedCompletedSuccessfully(
          feedId: 'a',
          canPrompt: () => true,
        );
        now = now.add(const Duration(days: 1));
        await persistedService.onFeedCompletedSuccessfully(
          feedId: 'b',
          canPrompt: () => true,
        );
        expect(store.reviewFeedSuccessCount, 202);
        expect(store.reviewNextMilestoneIndex, 5);
        expect(store.reviewLastPromptAt, priorRequest);
        expect(Hive.box<dynamic>('app_settings').get('review_feed_days'), [
          '2026-10-24',
          '2026-10-25',
        ]);
        expect(gateway.requestCalls, 0);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
