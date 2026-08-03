import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pet/services/crash/unclean_exit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> box;
  var boxCounter = 0;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('unclean_exit_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    UncleanExitService.instance.resetDebugState();
    box = await Hive.openBox<dynamic>('sentinel_${boxCounter++}');
  });

  group('UncleanExitService', () {
    test('reports unknown on a first launch with no stored session', () async {
      await UncleanExitService.instance.debugInitializeWith(box: box);

      expect(
        UncleanExitService.instance.previousExit,
        PreviousExitKind.unknown,
      );
    });

    test('treats a closed session as a clean exit', () async {
      // First run, shut down in an orderly way.
      await UncleanExitService.instance.debugInitializeWith(box: box);
      await UncleanExitService.instance.debugCloseSession();

      // Second run reads what the first one left behind.
      UncleanExitService.instance.resetDebugState();
      await UncleanExitService.instance.debugInitializeWith(box: box);

      expect(UncleanExitService.instance.previousExit, PreviousExitKind.clean);
    });

    test('flags a session that was still open while in the foreground', () async {
      // Open a session and never close it: the process "died" mid-use.
      await UncleanExitService.instance.debugInitializeWith(box: box);

      UncleanExitService.instance.resetDebugState();
      await UncleanExitService.instance.debugInitializeWith(box: box);

      expect(
        UncleanExitService.instance.previousExit,
        PreviousExitKind.foregroundUnclean,
      );
    });

    test('treats a background death as routine OS reclamation', () async {
      await UncleanExitService.instance.debugInitializeWith(box: box);
      // Simulate the app having been backgrounded before it was killed.
      await box.put('lifecycle', 'paused');

      UncleanExitService.instance.resetDebugState();
      await UncleanExitService.instance.debugInitializeWith(box: box);

      expect(
        UncleanExitService.instance.previousExit,
        PreviousExitKind.backgroundTermination,
      );
    });

    test('persists memory warnings for the next launch to read', () async {
      await UncleanExitService.instance.debugInitializeWith(box: box);
      await UncleanExitService.instance.recordMemoryWarning(3);

      expect(box.get('memory_warning_count'), 3);
    });

    test('opening a new session resets the memory warning count', () async {
      await UncleanExitService.instance.debugInitializeWith(box: box);
      await UncleanExitService.instance.recordMemoryWarning(5);

      UncleanExitService.instance.resetDebugState();
      await UncleanExitService.instance.debugInitializeWith(box: box);

      expect(box.get('memory_warning_count'), 0);
    });
  });

  group('UncleanExitException', () {
    test('describes cause and route for Crashlytics grouping', () {
      const exception = UncleanExitException(
        route: 'chat_room_view_v2',
        memoryWarnings: 2,
        suspectedCause: 'out_of_memory',
      );

      expect(exception.toString(), contains('out_of_memory'));
      expect(exception.toString(), contains('chat_room_view_v2'));
    });
  });
}
