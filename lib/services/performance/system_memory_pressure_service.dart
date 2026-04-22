import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../crash/crash_reporting_service.dart';
import 'memory_diagnostics_service.dart';

class SystemMemoryPressureService {
  SystemMemoryPressureService._();

  static final SystemMemoryPressureService instance =
      SystemMemoryPressureService._();
  static const MethodChannel _channel = MethodChannel(
    'pet/system_memory_pressure',
  );

  bool _initialized = false;
  int _memoryWarningCount = 0;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'memoryWarning':
        await _recordMemoryWarning();
        return null;
      default:
        return null;
    }
  }

  Future<void> _recordMemoryWarning() async {
    _memoryWarningCount += 1;
    final route = CrashReportingService.instance.currentRoute;
    final feature = CrashReportingService.instance.currentFeature;
    final roomId = CrashReportingService.instance.currentRoomId;
    await CrashReportingService.instance.setCustomKeys(<String, Object?>{
      'memory_warning_count': _memoryWarningCount,
      'memory_warning_route': route,
      'memory_warning_feature': feature,
      'memory_warning_room_id': roomId,
    });
    await CrashReportingService.instance.setContext(
      lastAction: 'memory_warning',
    );
    await CrashReportingService.instance.breadcrumb(
      'memory_warning',
      data: <String, Object?>{
        'count': _memoryWarningCount,
        'route': route,
        'feature': feature,
        'room_id': roomId,
      },
    );
    await MemoryDiagnosticsService.instance.captureSnapshot(
      source: 'ios_memory_warning',
      route: route,
      roomId: roomId,
      note: 'feature=$feature count=$_memoryWarningCount',
    );
  }

  @visibleForTesting
  Future<void> handleMethodCall(MethodCall call) => _handleMethodCall(call);

  @visibleForTesting
  int get memoryWarningCount => _memoryWarningCount;

  @visibleForTesting
  void resetDebugState() {
    _memoryWarningCount = 0;
  }
}
