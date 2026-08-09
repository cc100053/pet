import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/performance/memory_diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MemoryDiagnosticsService.instance.clearDebugSnapshots();
  });

  test('captureSnapshot stores snapshots and tracks deltas', () async {
    final service = MemoryDiagnosticsService.instance;

    final first = await service.captureSnapshot(
      source: 'chat_init_state',
      route: 'chat_room_view_v2',
      roomId: 'room-1',
      messageCount: 2,
      imageMessageCount: 1,
      optimisticMessageCount: 0,
    );
    final second = await service.captureSnapshot(
      source: 'chat_initial_messages_loaded',
      route: 'chat_room_view_v2',
      roomId: 'room-1',
      messageCount: 5,
      imageMessageCount: 3,
      optimisticMessageCount: 1,
      note: 'network',
    );

    expect(service.recentSnapshots, hasLength(2));
    expect(first.deltaMessageCount, isNull);
    expect(second.deltaMessageCount, 3);
    expect(second.roomId, 'room-1');
    expect(second.debugSummary, contains('chat_initial_messages_loaded'));
    expect(second.debugSummary, contains('messages=5'));
    expect(second.toBreadcrumbData()['note'], 'network');
  });

  test('clearDebugSnapshots resets the in-memory buffer', () async {
    final service = MemoryDiagnosticsService.instance;

    await service.captureSnapshot(
      source: 'home_debug_manual_capture',
      route: 'home_view',
      roomId: 'room-1',
    );
    expect(service.recentSnapshots, isNotEmpty);

    service.clearDebugSnapshots();

    expect(service.recentSnapshots, isEmpty);
  });

  String? actionFor({
    int currentSizeBytes = 0,
    int maximumSizeBytes = 64 * 1024 * 1024,
    int liveImageCount = 0,
    int maximumSize = 80,
  }) {
    return MemoryDiagnosticsService.cacheTrimAction(
      currentSizeBytes: currentSizeBytes,
      maximumSizeBytes: maximumSizeBytes,
      liveImageCount: liveImageCount,
      maximumSize: maximumSize,
    );
  }

  test('cacheTrimAction scales with the configured byte cap', () {
    // 50% of the cap: still comfortable.
    expect(actionFor(currentSizeBytes: 32 * 1024 * 1024), isNull);
    // 60% and 85% of the cap are the soft and hard thresholds.
    expect(actionFor(currentSizeBytes: 40 * 1024 * 1024), 'soft_trim');
    expect(actionFor(currentSizeBytes: 56 * 1024 * 1024), 'hard_trim');
  });

  test('cacheTrimAction tracks the cap instead of absolute bytes', () {
    // The same 40 MB is harmless against a 128 MB cap and a soft trim against
    // a 64 MB one. Absolute thresholds could not express this, which is how
    // the old 96 MB threshold became unreachable under a 64 MB cap.
    expect(
      actionFor(
        currentSizeBytes: 40 * 1024 * 1024,
        maximumSizeBytes: 128 * 1024 * 1024,
      ),
      isNull,
    );
    expect(actionFor(currentSizeBytes: 40 * 1024 * 1024), 'soft_trim');
  });

  test('cacheTrimAction trims on live-image pressure alone', () {
    // Bytes look fine, but 76 live images against an 80-entry cap is the shape
    // of the sessions that were killed: live images are pinned by mounted
    // widgets and never counted against the byte budget.
    expect(actionFor(currentSizeBytes: 1024, liveImageCount: 76), 'hard_trim');
    expect(actionFor(currentSizeBytes: 1024, liveImageCount: 52), 'soft_trim');
    expect(actionFor(currentSizeBytes: 1024, liveImageCount: 8), isNull);
  });

  test('cacheTrimAction tolerates unset caps', () {
    expect(
      actionFor(
        currentSizeBytes: 40 * 1024 * 1024,
        maximumSizeBytes: 0,
        maximumSize: 0,
      ),
      isNull,
    );
  });
}
