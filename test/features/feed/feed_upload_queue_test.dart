import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pet/features/feed/feed_upload_client.dart';
import 'package:pet/features/feed/feed_upload_models.dart';
import 'package:pet/features/feed/feed_upload_queue.dart';
import 'package:pet/features/feed/feed_upload_repository.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late FeedUploadRepository repository;
  late _FakeFeedUploadClient client;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('feed_upload_queue_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('feed_upload_jobs_test');
    repository = FeedUploadRepository(box: box);
    client = _FakeFeedUploadClient();
    container = ProviderContainer(
      overrides: [
        feedUploadRepositoryProvider.overrideWithValue(repository),
        feedUploadClientProvider.overrideWithValue(client),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await box.close();
    await Hive.deleteBoxFromDisk('feed_upload_jobs_test');
    await tempDir.delete(recursive: true);
  });

  test('enqueue persists and uploads a feed job', () async {
    client.uploadResult = const FeedUploadResult(
      tempId: 'ignored',
      coinsAwarded: 10,
      messageId: 'message-1',
      imageUrl: 'https://example.com/feed.webp',
    );

    final notifier = container.read(feedUploadQueueProvider.notifier);
    final job = await notifier.enqueue(
      roomId: 'room-1',
      senderId: 'user-1',
      localImagePath: '/tmp/feed.jpg',
      caption: 'Dinner',
      clientCreatedAt: DateTime.utc(2026, 4, 17, 1),
      labels: const <Map<String, dynamic>>[],
      initialBytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
    );

    expect(box.get(job.tempId), isA<Map>());
    await _pumpUntil(
      () =>
          container
              .read(feedUploadQueueProvider)
              .jobsByTempId[job.tempId]
              ?.status ==
          FeedUploadJobStatus.completed,
    );

    final completed = container
        .read(feedUploadQueueProvider)
        .jobsByTempId[job.tempId]!;
    expect(client.uploadCalls, 1);
    expect(completed.result?.messageId, 'message-1');
    expect(completed.result?.reconciled, isFalse);
  });

  test('failed upload records retryable error state', () async {
    client.uploadError = Exception('network_timeout');

    final notifier = container.read(feedUploadQueueProvider.notifier);
    final job = await notifier.enqueue(
      roomId: 'room-1',
      senderId: 'user-1',
      localImagePath: '/tmp/feed.jpg',
      caption: null,
      clientCreatedAt: DateTime.utc(2026, 4, 17, 2),
      labels: const <Map<String, dynamic>>[],
      initialBytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
    );

    await _pumpUntil(
      () =>
          container
              .read(feedUploadQueueProvider)
              .jobsByTempId[job.tempId]
              ?.status ==
          FeedUploadJobStatus.failed,
    );

    final failed = container
        .read(feedUploadQueueProvider)
        .jobsByTempId[job.tempId]!;
    expect(failed.retryCount, 1);
    expect(failed.lastError, contains('network_timeout'));
  });

  test(
    'reload reconciles a persisted pending job before retrying upload',
    () async {
      final persisted = FeedUploadJob(
        tempId: 'temp-1',
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: '/tmp/feed.jpg',
        caption: 'Dinner',
        clientCreatedAt: DateTime.utc(2026, 4, 17, 3),
        labels: const <Map<String, dynamic>>[],
        status: FeedUploadJobStatus.pending,
        retryCount: 0,
        updatedAt: DateTime.utc(2026, 4, 17, 3),
      );
      await repository.saveJob(persisted);
      client.reconciledResult = const FeedUploadResult(
        tempId: 'temp-1',
        coinsAwarded: 10,
        messageId: 'message-1',
        imageUrl: 'https://example.com/feed.webp',
        reconciled: true,
      );

      container.read(feedUploadQueueProvider);

      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId['temp-1']
                ?.status ==
            FeedUploadJobStatus.completed,
      );

      final completed = container
          .read(feedUploadQueueProvider)
          .jobsByTempId['temp-1']!;
      expect(client.findCalls, greaterThanOrEqualTo(1));
      expect(client.uploadCalls, 0);
      expect(completed.result?.messageId, 'message-1');
      expect(completed.result?.reconciled, isTrue);
    },
  );

  test('acknowledge removes completed jobs from memory and disk', () async {
    client.uploadResult = const FeedUploadResult(
      tempId: 'ignored',
      coinsAwarded: 0,
      messageId: 'message-2',
      imageUrl: 'https://example.com/feed.webp',
    );
    final notifier = container.read(feedUploadQueueProvider.notifier);
    final job = await notifier.enqueue(
      roomId: 'room-1',
      senderId: 'user-1',
      localImagePath: '/tmp/feed.jpg',
      caption: null,
      clientCreatedAt: DateTime.utc(2026, 4, 17, 4),
      labels: const <Map<String, dynamic>>[],
      initialBytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
    );
    await _pumpUntil(
      () =>
          container
              .read(feedUploadQueueProvider)
              .jobsByTempId[job.tempId]
              ?.status ==
          FeedUploadJobStatus.completed,
    );

    await notifier.acknowledge(job.tempId);

    expect(
      container.read(feedUploadQueueProvider).jobsByTempId,
      isNot(contains(job.tempId)),
    );
    expect(box.get(job.tempId), isNull);
  });

  group('FeedUploadQueueEvents', () {
    test('emits optimistic event when a job first becomes active', () {
      final job = _buildJob(status: FeedUploadJobStatus.pending);

      final events = FeedUploadQueueEvents.between(null, _stateWith(job));

      expect(events, hasLength(1));
      expect(events.single, isA<FeedUploadOptimisticReady>());
      expect(events.single.job.tempId, job.tempId);
    });

    test(
      'does not emit duplicate optimistic event for pending to uploading',
      () {
        final previous = _buildJob(status: FeedUploadJobStatus.pending);
        final next = previous.copyWith(status: FeedUploadJobStatus.uploading);

        final events = FeedUploadQueueEvents.between(
          _stateWith(previous),
          _stateWith(next),
        );

        expect(events, isEmpty);
      },
    );

    test('emits optimistic event when a failed job is retried', () {
      final previous = _buildJob(
        status: FeedUploadJobStatus.failed,
        lastError: 'network_timeout',
      );
      final next = previous.copyWith(
        status: FeedUploadJobStatus.pending,
        clearLastError: true,
      );

      final events = FeedUploadQueueEvents.between(
        _stateWith(previous),
        _stateWith(next),
      );

      expect(events, hasLength(1));
      expect(events.single, isA<FeedUploadOptimisticReady>());
    });

    test('emits completed event only when result exists', () {
      final previous = _buildJob(status: FeedUploadJobStatus.uploading);
      final completedWithoutResult = previous.copyWith(
        status: FeedUploadJobStatus.completed,
      );
      final next = previous.copyWith(
        status: FeedUploadJobStatus.completed,
        result: const FeedUploadResult(
          tempId: 'temp-1',
          coinsAwarded: 10,
          messageId: 'message-1',
        ),
      );

      expect(
        FeedUploadQueueEvents.between(
          _stateWith(previous),
          _stateWith(completedWithoutResult),
        ),
        isEmpty,
      );

      final events = FeedUploadQueueEvents.between(
        _stateWith(previous),
        _stateWith(next),
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event, isA<FeedUploadCompleted>());
      expect((event as FeedUploadCompleted).result.messageId, 'message-1');
    });

    test('emits failed event with retryable error', () {
      final previous = _buildJob(status: FeedUploadJobStatus.uploading);
      final next = previous.copyWith(
        status: FeedUploadJobStatus.failed,
        lastError: 'network_timeout',
      );

      final events = FeedUploadQueueEvents.between(
        _stateWith(previous),
        _stateWith(next),
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event, isA<FeedUploadFailed>());
      expect(
        (event as FeedUploadFailed).error.toString(),
        contains('network_timeout'),
      );
    });
  });
}

Future<void> _pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 30; i++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met before timeout.');
}

FeedUploadQueueState _stateWith(FeedUploadJob job) {
  return FeedUploadQueueState(
    jobsByTempId: {job.tempId: job},
    loaded: true,
    revision: 1,
  );
}

FeedUploadJob _buildJob({
  required FeedUploadJobStatus status,
  String? lastError,
}) {
  return FeedUploadJob(
    tempId: 'temp-1',
    roomId: 'room-1',
    senderId: 'user-1',
    localImagePath: '/tmp/feed.jpg',
    caption: 'Dinner',
    clientCreatedAt: DateTime.utc(2026, 4, 17, 1),
    labels: const <Map<String, dynamic>>[],
    status: status,
    retryCount: 0,
    updatedAt: DateTime.utc(2026, 4, 17, 1),
    lastError: lastError,
  );
}

class _FakeFeedUploadClient implements FeedUploadClient {
  FeedUploadResult? reconciledResult;
  FeedUploadResult? uploadResult;
  Object? uploadError;
  int findCalls = 0;
  int uploadCalls = 0;

  @override
  Future<FeedUploadResult?> findCompletedUpload(FeedUploadJob job) async {
    findCalls += 1;
    return reconciledResult;
  }

  @override
  Future<FeedUploadResult> upload(
    FeedUploadJob job, {
    Uint8List? initialBytes,
  }) async {
    uploadCalls += 1;
    final error = uploadError;
    if (error != null) {
      throw error;
    }
    final result = uploadResult;
    if (result == null) {
      throw StateError('uploadResult not configured');
    }
    return result.copyWith(tempId: job.tempId);
  }
}
