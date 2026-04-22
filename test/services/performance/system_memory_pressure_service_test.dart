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
}
