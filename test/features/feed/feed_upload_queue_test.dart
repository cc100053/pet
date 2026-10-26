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

  test('enqueue saves preview bytes before exposing the job', () async {
    client.uploadError = const SocketException('offline');
    final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
    final job = await container
        .read(feedUploadQueueProvider.notifier)
        .enqueue(
          roomId: 'room-1',
          senderId: 'user-1',
          localImagePath: '${tempDir.path}/missing_picker.jpg',
          caption: null,
          clientCreatedAt: DateTime.utc(2026, 10, 25),
          labels: const [],
          initialBytes: bytes,
        );

    expect(await File(job.localImagePath).readAsBytes(), bytes);
    expect(
      (box.get(job.tempId) as Map)['local_image_path'],
      job.localImagePath,
    );
    await _pumpUntil(
      () =>
          container
              .read(feedUploadQueueProvider)
              .jobsByTempId[job.tempId]
              ?.retryCount ==
          1,
    );
  });

  test(
    'startup cleans interrupted enqueues but preserves every saved job',
    () async {
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
      final orphan = await repository.saveImage(
        'orphan',
        '/missing.jpg',
        bytes: bytes,
      );
      final directory = File(orphan).parent;
      final staging = await File(
        '${directory.path}/interrupted.image.pending',
      ).writeAsBytes(bytes);
      final other = await File(
        '${directory.path}/unrelated.txt',
      ).writeAsString('keep');
      final savedPhotos = <String>[];
      for (final status in FeedUploadJobStatus.values) {
        final job = FeedUploadJob.fromJson({
          ..._buildJob(status: status).toJson(),
          'temp_id': 'saved_${status.name}',
        });
        final path = await repository.saveImage(
          job.tempId,
          '/missing.jpg',
          bytes: bytes,
        );
        await repository.saveJob(job.copyWith(localImagePath: path));
        savedPhotos.add(path);
      }
      await box.close();
      box = await Hive.openBox<dynamic>('feed_upload_jobs_test');
      repository = FeedUploadRepository(box: box);

      await repository.init();

      expect(await File(orphan).exists(), isFalse);
      expect(await staging.exists(), isFalse);
      expect(await other.exists(), isTrue);
      expect(
        repository.loadJobs(),
        hasLength(FeedUploadJobStatus.values.length),
      );
      for (final path in savedPhotos) {
        expect(await File(path).readAsBytes(), bytes);
      }
    },
  );

  test(
    'repeated init does not sweep a photo between staging and saving its job',
    () async {
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
      final path = await repository.saveImage(
        'new-job',
        '/missing.jpg',
        bytes: bytes,
      );
      await Future.wait([repository.init(), repository.init()]);
      expect(await File(path).readAsBytes(), bytes);
    },
  );

  test(
    'restoration rebases saved photos after an app container move',
    () async {
      final job = _buildJob(status: FeedUploadJobStatus.pending);
      final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
      final path = await repository.saveImage(
        job.tempId,
        '/missing.jpg',
        bytes: bytes,
      );
      await repository.saveJob(
        job.copyWith(
          localImagePath: '/previous-container/feed_upload_images/temp-1.image',
        ),
      );

      final restored = repository.loadJobs().single;
      expect(restored.localImagePath, path);
      expect(await File(restored.localImagePath).readAsBytes(), bytes);
      expect(restored.clientCreatedAt, job.clientCreatedAt);
    },
  );

  test('missing picker without preview bytes is never enqueued', () async {
    final notifier = container.read(feedUploadQueueProvider.notifier);
    await _pumpUntil(() => container.read(feedUploadQueueProvider).loaded);
    await expectLater(
      notifier.enqueue(
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: '${tempDir.path}/missing.jpg',
        caption: null,
        clientCreatedAt: DateTime.utc(2026, 10, 25),
        labels: const [],
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(container.read(feedUploadQueueProvider).jobs, isEmpty);
    expect(box.values, isEmpty);
    expect(
      await Directory('${tempDir.path}/feed_upload_images').list().toList(),
      isEmpty,
    );
    expect(client.uploadCalls, 0);
  });

  test(
    'failed queue persistence removes its photo and exposes no job',
    () async {
      container.dispose();
      repository = _FailingSaveRepository(box: box);
      container = ProviderContainer(
        overrides: [
          feedUploadRepositoryProvider.overrideWithValue(repository),
          feedUploadClientProvider.overrideWithValue(client),
        ],
      );
      final notifier = container.read(feedUploadQueueProvider.notifier);
      await _pumpUntil(() => container.read(feedUploadQueueProvider).loaded);
      await expectLater(
        notifier.enqueue(
          roomId: 'room-1',
          senderId: 'user-1',
          localImagePath: '/missing.jpg',
          caption: null,
          clientCreatedAt: DateTime.utc(2026, 10, 25),
          labels: const [],
          initialBytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
        ),
        throwsStateError,
      );
      expect(container.read(feedUploadQueueProvider).jobs, isEmpty);
      expect(box.values, isEmpty);
      expect(
        await Directory('${tempDir.path}/feed_upload_images').list().toList(),
        isEmpty,
      );
      expect(client.uploadCalls, 0);
    },
  );

  test(
    'retry reads the saved photo after the picker file is deleted',
    () async {
      final picker = File('${tempDir.path}/picker.jpg');
      final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
      await picker.writeAsBytes(bytes);
      client
        ..readImage = true
        ..uploadError = const SocketException('offline');
      final notifier = container.read(feedUploadQueueProvider.notifier);
      final job = await notifier.enqueue(
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: picker.path,
        caption: null,
        clientCreatedAt: DateTime.utc(2026, 10, 25),
        labels: const [],
        initialBytes: bytes,
      );
      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId[job.tempId]
                ?.retryCount ==
            1,
      );
      await picker.delete();
      client
        ..uploadError = null
        ..uploadResult = const FeedUploadResult(
          tempId: 'ignored',
          coinsAwarded: 0,
        );

      await notifier.retry(job.tempId);
      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId[job.tempId]
                ?.status ==
            FeedUploadJobStatus.completed,
      );

      expect(client.uploadedImages, [bytes, bytes]);
      expect(await File(job.localImagePath).readAsBytes(), bytes);
      await notifier.acknowledge(job.tempId);
      expect(await File(job.localImagePath).exists(), isFalse);
    },
  );

  test(
    'reopened queue uploads saved photo without in-memory preview',
    () async {
      final picker = File('${tempDir.path}/picker.jpg');
      final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
      await picker.writeAsBytes(bytes);
      client.uploadError = const SocketException('offline');
      final job = await container
          .read(feedUploadQueueProvider.notifier)
          .enqueue(
            roomId: 'room-1',
            senderId: 'user-1',
            localImagePath: picker.path,
            caption: null,
            clientCreatedAt: DateTime.utc(2026, 10, 25),
            labels: const [],
            initialBytes: bytes,
          );
      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId[job.tempId]
                ?.retryCount ==
            1,
      );
      container.dispose();
      await box.close();
      await picker.delete();
      box = await Hive.openBox<dynamic>('feed_upload_jobs_test');
      repository = FeedUploadRepository(box: box);
      client = _FakeFeedUploadClient()
        ..readImage = true
        ..uploadResult = const FeedUploadResult(
          tempId: 'ignored',
          coinsAwarded: 0,
        );
      container = ProviderContainer(
        overrides: [
          feedUploadRepositoryProvider.overrideWithValue(repository),
          feedUploadClientProvider.overrideWithValue(client),
        ],
      );
      container.read(feedUploadQueueProvider);
      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId[job.tempId]
                ?.status ==
            FeedUploadJobStatus.completed,
      );
      expect(client.uploadedImages.single, bytes);
    },
  );

  test(
    'legacy jobs save readable picker files only after reconciliation',
    () async {
      final picker = File('${tempDir.path}/legacy.jpg');
      final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
      await picker.writeAsBytes(bytes);
      final job = _buildJob(status: FeedUploadJobStatus.pending);
      await repository.saveJob(
        FeedUploadJob.fromJson({
          ...job.toJson(),
          'local_image_path': picker.path,
        }),
      );
      client
        ..readImage = true
        ..uploadResult = const FeedUploadResult(
          tempId: 'ignored',
          coinsAwarded: 0,
        );
      container.read(feedUploadQueueProvider);
      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId[job.tempId]
                ?.status ==
            FeedUploadJobStatus.completed,
      );
      final saved = container
          .read(feedUploadQueueProvider)
          .jobsByTempId[job.tempId]!;
      expect(saved.localImagePath, isNot(picker.path));
      expect(await File(saved.localImagePath).readAsBytes(), bytes);
      await container
          .read(feedUploadQueueProvider.notifier)
          .acknowledge(job.tempId);
      expect(await picker.exists(), isTrue);
      expect(await File(saved.localImagePath).exists(), isFalse);
    },
  );

  test(
    'first upload failure auto-retries silently and stays pending',
    () async {
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

      // After the first failure the job is scheduled for a backoff retry rather
      // than surfaced to the user, so it stays pending with the error recorded.
      await _pumpUntil(
        () =>
            (container
                    .read(feedUploadQueueProvider)
                    .jobsByTempId[job.tempId]
                    ?.retryCount ??
                0) >=
            1,
      );

      final pending = container
          .read(feedUploadQueueProvider)
          .jobsByTempId[job.tempId]!;
      expect(pending.status, FeedUploadJobStatus.pending);
      expect(pending.retryCount, 1);
      expect(pending.lastError, contains('network_timeout'));
    },
  );

  test(
    'upload fails terminally once the auto-retry budget is exhausted',
    () async {
      final picker = await File(
        '${tempDir.path}/picker.jpg',
      ).writeAsBytes([0xff, 0xd8, 0xff]);
      // Persist a job that has already consumed its auto-retry budget so the next
      // failed attempt flips it straight to failed without scheduling a timer.
      final exhausted = FeedUploadJob(
        tempId: 'temp-exhausted',
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: picker.path,
        caption: null,
        clientCreatedAt: DateTime.utc(2026, 4, 17, 5),
        labels: const <Map<String, dynamic>>[],
        status: FeedUploadJobStatus.pending,
        retryCount: 3,
        updatedAt: DateTime.utc(2026, 4, 17, 5),
      );
      await repository.saveJob(exhausted);
      client.uploadError = Exception('network_timeout');

      container.read(feedUploadQueueProvider);

      await _pumpUntil(
        () =>
            container
                .read(feedUploadQueueProvider)
                .jobsByTempId['temp-exhausted']
                ?.status ==
            FeedUploadJobStatus.failed,
      );

      final failed = container
          .read(feedUploadQueueProvider)
          .jobsByTempId['temp-exhausted']!;
      expect(failed.retryCount, 4);
      expect(failed.lastError, contains('network_timeout'));
      expect(client.uploadCalls, 1);
      expect(await File(failed.localImagePath).exists(), isTrue);
      await container
          .read(feedUploadQueueProvider.notifier)
          .acknowledge(failed.tempId);
      expect(await File(failed.localImagePath).exists(), isFalse);
      expect(await picker.exists(), isTrue);
    },
  );

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

  test(
    'reload silently retries a persisted failed job instead of replaying error',
    () async {
      final persisted = FeedUploadJob(
        tempId: 'temp-failed',
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: '/tmp/feed.jpg',
        caption: 'Dinner',
        clientCreatedAt: DateTime.utc(2026, 4, 17, 6),
        labels: const <Map<String, dynamic>>[],
        status: FeedUploadJobStatus.failed,
        retryCount: 4,
        updatedAt: DateTime.utc(2026, 4, 17, 6),
        lastError: 'feed_validate_failed:process_feed_event_failed',
      );
      await repository.saveJob(persisted);
      client.reconciledResult = const FeedUploadResult(
        tempId: 'temp-failed',
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
                .jobsByTempId['temp-failed']
                ?.status ==
            FeedUploadJobStatus.completed,
      );

      final completed = container
          .read(feedUploadQueueProvider)
          .jobsByTempId['temp-failed']!;
      expect(client.findCalls, greaterThanOrEqualTo(1));
      expect(client.uploadCalls, 0);
      expect(completed.lastError, isNull);
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

    test('emits completed event for persisted completed job replay', () {
      final completed = _buildJob(status: FeedUploadJobStatus.completed)
          .copyWith(
            result: const FeedUploadResult(
              tempId: 'temp-1',
              coinsAwarded: 10,
              messageId: 'message-1',
            ),
          );

      final events = FeedUploadQueueEvents.between(null, _stateWith(completed));

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

    test('emits failed event for persisted failed job replay', () {
      final failed = _buildJob(
        status: FeedUploadJobStatus.failed,
        lastError: 'network_timeout',
      );

      final events = FeedUploadQueueEvents.between(null, _stateWith(failed));

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
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
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

class _FailingSaveRepository extends FeedUploadRepository {
  _FailingSaveRepository({required super.box});

  @override
  Future<void> saveJob(FeedUploadJob job) async =>
      throw StateError('disk full');
}

class _FakeFeedUploadClient implements FeedUploadClient {
  FeedUploadResult? reconciledResult;
  FeedUploadResult? uploadResult;
  Object? uploadError;
  int findCalls = 0;
  int uploadCalls = 0;
  bool readImage = false;
  final List<Uint8List> uploadedImages = [];

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
    if (readImage) {
      uploadedImages.add(
        initialBytes ?? await File(job.localImagePath).readAsBytes(),
      );
    }
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
