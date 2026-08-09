import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/crash/crash_reporting_service.dart';
import 'package:pet/services/performance/memory_diagnostics_service.dart';
import 'package:pet/services/performance/system_memory_pressure_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MemoryDiagnosticsService.instance.clearDebugSnapshots();
    SystemMemoryPressureService.instance.resetDebugState();
  });

  test('memoryWarning records snapshot with current crash context', () async {
    await CrashReportingService.instance.setRoute('home_view');
    await CrashReportingService.instance.setContext(
      feature: 'chat_room_view_v2',
      roomId: 'room-4',
      lastAction: 'switch_room',
    );

    await SystemMemoryPressureService.instance.handleMethodCall(
      const MethodCall('memoryWarning'),
    );

    expect(SystemMemoryPressureService.instance.memoryWarningCount, 1);
    expect(MemoryDiagnosticsService.instance.recentSnapshots, hasLength(1));
    final snapshot = MemoryDiagnosticsService.instance.recentSnapshots.single;
    expect(snapshot.source, 'ios_memory_warning');
    expect(snapshot.route, 'home_view');
    expect(snapshot.roomId, 'room-4');
    expect(snapshot.note, contains('feature=chat_room_view_v2'));
    expect(snapshot.note, contains('count=1'));
  });

  test(
    'memoryWarning releases the image cache instead of only logging',
    () async {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.putIfAbsent(
        'memory-pressure-test',
        () => OneFrameImageStreamCompleter(_decodedFrame()),
      );
      expect(
        imageCache.currentSize + imageCache.liveImageCount,
        greaterThan(0),
      );

      await SystemMemoryPressureService.instance.handleMethodCall(
        const MethodCall('memoryWarning'),
      );

      expect(imageCache.currentSize, 0);
      expect(imageCache.liveImageCount, 0);
      final snapshot = MemoryDiagnosticsService.instance.recentSnapshots.single;
      expect(snapshot.note, contains('pressure_release'));
    },
  );
}

Future<ImageInfo> _decodedFrame() async {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  return ImageInfo(image: image);
}
