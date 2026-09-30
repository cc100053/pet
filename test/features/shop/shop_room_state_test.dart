import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // A self-referential `late` initializer (`_roomId = _roomId`) compiles and
  // analyzes clean but stack-overflows on first read, failing every shop load.
  test('switchable shop room starts from the route room id', () {
    final source = File('lib/features/shop/shop_view.dart').readAsStringSync();

    expect(source, contains('late String? _roomId = widget.roomId;'));
  });
}
