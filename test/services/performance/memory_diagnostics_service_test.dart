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

  test('cacheTrimActionForBytes uses soft and hard thresholds', () {
    expect(
      MemoryDiagnosticsService.cacheTrimActionForBytes(64 * 1024 * 1024),
      isNull,
    );
    expect(
      MemoryDiagnosticsService.cacheTrimActionForBytes(96 * 1024 * 1024),
      'soft_trim',
    );
    expect(
      MemoryDiagnosticsService.cacheTrimActionForBytes(128 * 1024 * 1024),
      'hard_trim',
    );
  });
}
