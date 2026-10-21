import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('furniture writes retain reservations and recover the captured room', () {
    // Execute the real private extension methods with a deterministic backend;
    // pumping HomeView would also start unrelated platform services/realtime.
    final source = File(
      'lib/features/home/home_view_room_decor.dart',
    ).readAsStringSync();
    final methods =
        [
          '_loadRoomFurniture',
          '_persistFurniturePlacement',
          '_removeFurniture',
        ].map((name) {
          final match = RegExp(
            '  Future<void> $name'
            r'\([\s\S]*?\n  \}',
          ).firstMatch(source);
          expect(match, isNotNull, reason: 'Missing production method $name');
          return match!.group(0)!;
        });
    final template = File(
      'test/features/home/fixtures/furniture_placement_harness.dart.template',
    ).readAsStringSync();
    final directory = Directory.systemTemp.createTempSync('furniture_test_');
    try {
      final harness = File('${directory.path}/harness.dart')
        ..writeAsStringSync(
          template.replaceFirst('// PRODUCTION_METHODS', methods.join('\n')),
        );
      final result = Process.runSync(
        '.fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart',
        [harness.path],
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect('PASS '.allMatches(result.stdout as String), hasLength(5));
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
