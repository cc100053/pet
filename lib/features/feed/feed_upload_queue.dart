import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/analytics/analytics_service.dart';
import 'feed_upload_client.dart';
import 'feed_upload_models.dart';
import 'feed_upload_repository.dart';

class FeedUploadQueueState {
  const FeedUploadQueueState({
    required this.jobsByTempId,
    required this.loaded,
    required this.revision,
  });

  const FeedUploadQueueState.empty()
    : jobsByTempId = const <String, FeedUploadJob>{},
      loaded = false,
      revision = 0;

  final Map<String, FeedUploadJob> jobsByTempId;
  final bool loaded;
  final int revision;

  List<FeedUploadJob> get jobs => jobsByTempId.values.toList(growable: false);

  FeedUploadQueueState copyWith({
    Map<String, FeedUploadJob>? jobsByTempId,
    bool? loaded,
    int? revision,
  }) {
    return FeedUploadQueueState(
      jobsByTempId: jobsByTempId ?? this.jobsByTempId,
      loaded: loaded ?? this.loaded,
      revision: revision ?? this.revision,
    );
  }
}

sealed class FeedUploadQueueEvent {
  const FeedUploadQueueEvent({required this.job});

  final FeedUploadJob job;
}

class FeedUploadOptimisticReady extends FeedUploadQueueEvent {
  const FeedUploadOptimisticReady({required super.job});
}

class FeedUploadCompleted extends FeedUploadQueueEvent {
  const FeedUploadCompleted({required super.job, required this.result});

  final FeedUploadResult result;
}

class FeedUploadFailed extends FeedUploadQueueEvent {
  const FeedUploadFailed({required super.job, required this.error});

  final Object error;
}

class FeedUploadQueueEvents {
  const FeedUploadQueueEvents._();

  static List<FeedUploadQueueEvent> between(
    FeedUploadQueueState? previous,
    FeedUploadQueueState next,
  ) {
    final events = <FeedUploadQueueEvent>[];
    for (final job in next.jobs) {
      final previousJob = previous?.jobsByTempId[job.tempId];
      final previousStatus = previousJob?.status;
      if (previousStatus == job.status) {
        continue;
      }
      switch (job.status) {
        case FeedUploadJobStatus.pending:
        case FeedUploadJobStatus.uploading:
          if (previousStatus == null ||
              previousStatus == FeedUploadJobStatus.failed ||
              previousStatus == FeedUploadJobStatus.completed) {
            events.add(FeedUploadOptimisticReady(job: job));
          }
          break;
        case FeedUploadJobStatus.completed:
          final result = job.result;
          if (result != null) {
            events.add(FeedUploadCompleted(job: job, result: result));
          }
          break;
        case FeedUploadJobStatus.failed:
          events.add(
            FeedUploadFailed(
              job: job,
              error: Exception(job.lastError ?? 'feed_upload_failed'),
            ),
          );
          break;
      }
    }
    return events;
  }
}

final feedUploadRepositoryProvider = Provider<FeedUploadRepository>(
  (ref) => FeedUploadRepository.instance,
);

final feedUploadClientProvider = Provider<FeedUploadClient>(
  (ref) => SupabaseFeedUploadClient(),
);

final feedUploadQueueProvider =
    NotifierProvider<FeedUploadQueueNotifier, FeedUploadQueueState>(
      FeedUploadQueueNotifier.new,
    );

class FeedUploadQueueNotifier extends Notifier<FeedUploadQueueState> {
  FeedUploadRepository get _repository =>
      ref.read(feedUploadRepositoryProvider);
  FeedUploadClient get _client => ref.read(feedUploadClientProvider);

  /// Number of transparent auto-retries (with exponential backoff) before a
  /// job is marked [FeedUploadJobStatus.failed] and surfaced to the user.
  static const int _maxAutoRetries = 3;

  final Set<String> _inFlightTempIds = <String>{};
  final Map<String, Uint8List> _initialBytesByTempId = <String, Uint8List>{};
  final Map<String, Timer> _autoRetryTimers = <String, Timer>{};
  bool _loadStarted = false;

  @override
  FeedUploadQueueState build() {
    ref.onDispose(() {
      for (final timer in _autoRetryTimers.values) {
        timer.cancel();
      }
      _autoRetryTimers.clear();
    });
    if (!_loadStarted) {
      _loadStarted = true;
      unawaited(_loadPersistedJobs());
    }
    return const FeedUploadQueueState.empty();
  }

  Future<void> _loadPersistedJobs() async {
    await _repository.init();
    final jobs = _repository.loadJobs();
    state = state.copyWith(
      jobsByTempId: {
        for (final job in jobs) job.tempId: _normalizeLoadedJob(job),
        ...state.jobsByTempId,
      },
      loaded: true,
      revision: state.revision + 1,
    );
    unawaited(resumePendingJobs());
  }

  FeedUploadJob _normalizeLoadedJob(FeedUploadJob job) {
    if (job.status == FeedUploadJobStatus.uploading) {
      return job.copyWith(status: FeedUploadJobStatus.pending);
    }
    return job;
  }

  Future<FeedUploadJob> enqueue({
    required String roomId,
    required String senderId,
    required String localImagePath,
    required String? caption,
    required DateTime clientCreatedAt,
    required List<Map<String, dynamic>> labels,
    Uint8List? initialBytes,
  }) async {
    if (!state.loaded) {
      await _repository.init();
    }
    final tempId = 'temp_${clientCreatedAt.microsecondsSinceEpoch}';
    final job = FeedUploadJob(
      tempId: tempId,
      roomId: roomId,
      senderId: senderId,
      localImagePath: localImagePath,
      caption: caption,
      clientCreatedAt: clientCreatedAt.toUtc(),
      labels: labels,
      status: FeedUploadJobStatus.pending,
      retryCount: 0,
      updatedAt: DateTime.now().toUtc(),
    );
    if (initialBytes != null) {
      _initialBytesByTempId[tempId] = initialBytes;
    }
    await _upsertJob(job);
    unawaited(_processJob(tempId));
    return job;
  }

  Future<void> resumePendingJobs() async {
    final pendingJobs = state.jobs.where(
      (job) =>
          job.status == FeedUploadJobStatus.pending ||
          job.status == FeedUploadJobStatus.uploading,
    );
    for (final job in pendingJobs) {
      unawaited(_processJob(job.tempId));
    }
  }

  Future<void> retry(String tempId) async {
    final job = state.jobsByTempId[tempId];
    if (job == null) {
      return;
    }
    _cancelAutoRetry(tempId);
    final next = job.copyWith(
      status: FeedUploadJobStatus.pending,
      clearLastError: true,
      clearResult: true,
    );
    await _upsertJob(next);
    unawaited(_processJob(tempId));
  }

  Future<void> acknowledge(String tempId) async {
    _cancelAutoRetry(tempId);
    final nextJobs = Map<String, FeedUploadJob>.from(state.jobsByTempId)
      ..remove(tempId);
    state = state.copyWith(
      jobsByTempId: nextJobs,
      revision: state.revision + 1,
    );
    _initialBytesByTempId.remove(tempId);
    await _repository.deleteJob(tempId);
  }

  Future<void> _processJob(String tempId) async {
    if (!_inFlightTempIds.add(tempId)) {
      return;
    }
    try {
      var job = state.jobsByTempId[tempId];
      if (job == null ||
          job.status == FeedUploadJobStatus.completed ||
          job.status == FeedUploadJobStatus.failed) {
        return;
      }

      final uploading = job.copyWith(
        status: FeedUploadJobStatus.uploading,
        clearLastError: true,
      );
      await _upsertJob(uploading);
      job = uploading;

      final reconciled = await _client.findCompletedUpload(job);
      if (reconciled != null) {
        await _completeJob(job, reconciled.copyWith(reconciled: true));
        return;
      }

      final result = await _client.upload(
        job,
        initialBytes: _initialBytesByTempId.remove(tempId),
      );
      await _completeJob(job, result);
      AnalyticsService.instance.logEvent(
        'feed_send',
        parameters: {'result': 'success'},
      );
    } catch (error) {
      AnalyticsService.instance.logEvent(
        'feed_send',
        parameters: {'result': 'failure'},
      );
      final job = state.jobsByTempId[tempId];
      if (job == null) {
        return;
      }
      final attempts = job.retryCount + 1;
      if (attempts <= _maxAutoRetries) {
        // Keep the optimistic photo visible as "sending" and retry silently
        // with exponential backoff. Staying in [pending] avoids firing a
        // user-facing FeedUploadFailed event for transient failures.
        final backingOff = job.copyWith(
          status: FeedUploadJobStatus.pending,
          retryCount: attempts,
          lastError: error.toString(),
        );
        await _upsertJob(backingOff);
        _scheduleAutoRetry(tempId, attempts);
      } else {
        // Auto-retry budget exhausted: surface the failure to the user.
        final failed = job.copyWith(
          status: FeedUploadJobStatus.failed,
          retryCount: attempts,
          lastError: error.toString(),
        );
        await _upsertJob(failed);
      }
    } finally {
      _inFlightTempIds.remove(tempId);
    }
  }

  void _scheduleAutoRetry(String tempId, int attempt) {
    _autoRetryTimers.remove(tempId)?.cancel();
    _autoRetryTimers[tempId] = Timer(_backoffDelay(attempt), () {
      _autoRetryTimers.remove(tempId);
      final job = state.jobsByTempId[tempId];
      if (job == null || job.status != FeedUploadJobStatus.pending) {
        return;
      }
      unawaited(_processJob(tempId));
    });
  }

  void _cancelAutoRetry(String tempId) {
    _autoRetryTimers.remove(tempId)?.cancel();
  }

  /// Exponential backoff: ~2s, 4s, 8s, capped at 30s.
  Duration _backoffDelay(int attempt) {
    final seconds = math.min(1 << attempt, 30);
    return Duration(seconds: seconds);
  }

  Future<void> _completeJob(FeedUploadJob job, FeedUploadResult result) async {
    final completed = job.copyWith(
      status: FeedUploadJobStatus.completed,
      clearLastError: true,
      result: result,
    );
    await _upsertJob(completed);
  }

  Future<void> _upsertJob(FeedUploadJob job) async {
    final nextJobs = Map<String, FeedUploadJob>.from(state.jobsByTempId);
    nextJobs[job.tempId] = job;
    state = state.copyWith(
      jobsByTempId: nextJobs,
      loaded: true,
      revision: state.revision + 1,
    );
    await _repository.saveJob(job);
  }
}
