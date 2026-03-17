import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../crash/crash_reporting_service.dart';

class MemoryDiagnosticsSnapshot {
  const MemoryDiagnosticsSnapshot({
    required this.capturedAt,
    required this.source,
    required this.route,
    required this.roomId,
    required this.imageCacheCount,
    required this.imageCacheBytes,
    required this.imageCacheLiveImages,
    required this.imageCachePendingImages,
    required this.imageCacheMaxCount,
    required this.imageCacheMaxBytes,
    required this.activeChannels,
    required this.messageCount,
    required this.imageMessageCount,
    required this.optimisticMessageCount,
    this.note,
    this.fullscreenProviderType,
    this.fullscreenItemCount,
    this.deltaImageCacheBytes,
    this.deltaActiveChannels,
    this.deltaMessageCount,
  });

  final DateTime capturedAt;
  final String source;
  final String route;
  final String roomId;
  final int imageCacheCount;
  final int imageCacheBytes;
  final int imageCacheLiveImages;
  final int imageCachePendingImages;
  final int imageCacheMaxCount;
  final int imageCacheMaxBytes;
  final int activeChannels;
  final int messageCount;
  final int imageMessageCount;
  final int optimisticMessageCount;
  final String? note;
  final String? fullscreenProviderType;
  final int? fullscreenItemCount;
  final int? deltaImageCacheBytes;
  final int? deltaActiveChannels;
  final int? deltaMessageCount;

  Map<String, Object> toBreadcrumbData() {
    final data = <String, Object>{
      'source': source,
      'route': route,
      'room_id': roomId,
      'cache_count': imageCacheCount,
      'cache_bytes': imageCacheBytes,
      'cache_live': imageCacheLiveImages,
      'cache_pending': imageCachePendingImages,
      'messages': messageCount,
      'image_messages': imageMessageCount,
      'optimistic_messages': optimisticMessageCount,
    };
    if (activeChannels >= 0) {
      data['channels'] = activeChannels;
    }
    if (note != null && note!.isNotEmpty) {
      data['note'] = note!;
    }
    if (fullscreenProviderType != null && fullscreenProviderType!.isNotEmpty) {
      data['viewer_provider'] = fullscreenProviderType!;
    }
    if (fullscreenItemCount != null) {
      data['viewer_items'] = fullscreenItemCount!;
    }
    if (deltaImageCacheBytes != null) {
      data['delta_cache_bytes'] = deltaImageCacheBytes!;
    }
    if (deltaActiveChannels != null) {
      data['delta_channels'] = deltaActiveChannels!;
    }
    if (deltaMessageCount != null) {
      data['delta_messages'] = deltaMessageCount!;
    }
    return data;
  }

  Map<String, Object?> toCustomKeys() {
    return <String, Object?>{
      'diag_snapshot_source': source,
      'diag_snapshot_route': route,
      'diag_snapshot_room_id': roomId,
      'diag_active_channels': activeChannels >= 0 ? activeChannels : null,
      'diag_image_cache_bytes': imageCacheBytes,
      'diag_image_cache_live': imageCacheLiveImages,
      'diag_message_count': messageCount,
    };
  }

  String get debugSummary {
    final buffer = StringBuffer()
      ..write(_formatTimestamp(capturedAt))
      ..write(' | ')
      ..write(source)
      ..write(' | route=')
      ..write(route)
      ..write(' room=')
      ..write(roomId)
      ..write('\nchannels=')
      ..write(activeChannels >= 0 ? activeChannels : 'unavailable')
      ..write(' messages=')
      ..write(messageCount)
      ..write(' image_messages=')
      ..write(imageMessageCount)
      ..write(' optimistic=')
      ..write(optimisticMessageCount)
      ..write('\ncache=')
      ..write(imageCacheCount)
      ..write('/')
      ..write(imageCacheMaxCount)
      ..write(' items ')
      ..write(_formatMegabytes(imageCacheBytes))
      ..write('/')
      ..write(_formatMegabytes(imageCacheMaxBytes))
      ..write(' MB live=')
      ..write(imageCacheLiveImages)
      ..write(' pending=')
      ..write(imageCachePendingImages);
    if (deltaImageCacheBytes != null ||
        deltaActiveChannels != null ||
        deltaMessageCount != null) {
      buffer
        ..write('\ndelta cache=')
        ..write(_formatSignedMegabytes(deltaImageCacheBytes))
        ..write(' MB channels=')
        ..write(_formatSignedInt(deltaActiveChannels))
        ..write(' messages=')
        ..write(_formatSignedInt(deltaMessageCount));
    }
    if (fullscreenProviderType != null || fullscreenItemCount != null) {
      buffer
        ..write('\nviewer provider=')
        ..write(fullscreenProviderType ?? 'none')
        ..write(' items=')
        ..write(fullscreenItemCount ?? 0);
    }
    if (note != null && note!.isNotEmpty) {
      buffer
        ..write('\nnote=')
        ..write(note);
    }
    return buffer.toString();
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }

  static String _formatMegabytes(int bytes) {
    return (bytes / (1024 * 1024)).toStringAsFixed(1);
  }

  static String _formatSignedMegabytes(int? bytes) {
    if (bytes == null) {
      return 'n/a';
    }
    final megabytes = bytes / (1024 * 1024);
    return megabytes >= 0
        ? '+${megabytes.toStringAsFixed(1)}'
        : megabytes.toStringAsFixed(1);
  }

  static String _formatSignedInt(int? value) {
    if (value == null) {
      return 'n/a';
    }
    if (value > 0) {
      return '+$value';
    }
    return value.toString();
  }
}

class MemoryDiagnosticsService {
  MemoryDiagnosticsService._();

  static final MemoryDiagnosticsService instance = MemoryDiagnosticsService._();
  static const int _maxSnapshots = 30;

  final ValueNotifier<List<MemoryDiagnosticsSnapshot>> _snapshots =
      ValueNotifier<List<MemoryDiagnosticsSnapshot>>(
        const <MemoryDiagnosticsSnapshot>[],
      );

  ValueListenable<List<MemoryDiagnosticsSnapshot>> get snapshotsListenable =>
      _snapshots;

  List<MemoryDiagnosticsSnapshot> get recentSnapshots => _snapshots.value;

  Future<MemoryDiagnosticsSnapshot> captureSnapshot({
    required String source,
    required String route,
    String? roomId,
    int messageCount = 0,
    int imageMessageCount = 0,
    int optimisticMessageCount = 0,
    String? note,
    String? fullscreenProviderType,
    int? fullscreenItemCount,
  }) async {
    final imageCache = PaintingBinding.instance.imageCache;
    final previous = recentSnapshots.isEmpty ? null : recentSnapshots.last;
    final activeChannels = _activeChannelCount();
    final snapshot = MemoryDiagnosticsSnapshot(
      capturedAt: DateTime.now(),
      source: source,
      route: route,
      roomId: _normalizeRoomId(roomId),
      imageCacheCount: imageCache.currentSize,
      imageCacheBytes: imageCache.currentSizeBytes,
      imageCacheLiveImages: imageCache.liveImageCount,
      imageCachePendingImages: imageCache.pendingImageCount,
      imageCacheMaxCount: imageCache.maximumSize,
      imageCacheMaxBytes: imageCache.maximumSizeBytes,
      activeChannels: activeChannels,
      messageCount: messageCount,
      imageMessageCount: imageMessageCount,
      optimisticMessageCount: optimisticMessageCount,
      note: _normalizeNote(note),
      fullscreenProviderType: fullscreenProviderType,
      fullscreenItemCount: fullscreenItemCount,
      deltaImageCacheBytes: previous == null
          ? null
          : imageCache.currentSizeBytes - previous.imageCacheBytes,
      deltaActiveChannels: previous == null || activeChannels < 0
          ? null
          : activeChannels - previous.activeChannels,
      deltaMessageCount: previous == null
          ? null
          : messageCount - previous.messageCount,
    );
    _appendSnapshot(snapshot);
    if (kDebugMode || kProfileMode) {
      debugPrint('[memory_diag] ${snapshot.debugSummary}');
    }
    try {
      await CrashReportingService.instance.breadcrumb(
        'memory_snapshot',
        data: snapshot.toBreadcrumbData(),
      );
      await CrashReportingService.instance.setCustomKeys(
        snapshot.toCustomKeys(),
      );
    } catch (_) {
      // Diagnostics must never fail the primary user flow.
    }
    return snapshot;
  }

  Future<MemoryDiagnosticsSnapshot> clearImageCacheAndCapture({
    required String source,
    required String route,
    String? roomId,
    int messageCount = 0,
    int imageMessageCount = 0,
    int optimisticMessageCount = 0,
    String? note,
  }) async {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    return captureSnapshot(
      source: source,
      route: route,
      roomId: roomId,
      messageCount: messageCount,
      imageMessageCount: imageMessageCount,
      optimisticMessageCount: optimisticMessageCount,
      note: note == null || note.isEmpty
          ? 'image_cache_cleared'
          : 'image_cache_cleared:$note',
    );
  }

  void clearDebugSnapshots() {
    if (_snapshots.value.isEmpty) {
      return;
    }
    _snapshots.value = const <MemoryDiagnosticsSnapshot>[];
  }

  void _appendSnapshot(MemoryDiagnosticsSnapshot snapshot) {
    final next = List<MemoryDiagnosticsSnapshot>.from(_snapshots.value)
      ..add(snapshot);
    if (next.length > _maxSnapshots) {
      next.removeRange(0, next.length - _maxSnapshots);
    }
    _snapshots.value = List<MemoryDiagnosticsSnapshot>.unmodifiable(next);
  }

  int _activeChannelCount() {
    try {
      return Supabase.instance.client.getChannels().length;
    } catch (_) {
      return -1;
    }
  }

  String _normalizeRoomId(String? roomId) {
    final trimmed = roomId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'none';
    }
    return trimmed;
  }

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
