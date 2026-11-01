import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_main_content.dart';

void main() {
  const roomKey = Key('room');

  Widget build({Widget? bottomOverlay, Widget? galleryOverlay}) {
    return MaterialApp(
      home: Scaffold(
        body: HomeMainContent(
          bottomInset: 0,
          statusBar: const SizedBox(height: 40),
          photoGallery: const SizedBox.expand(),
          petHomeCard: const SizedBox.expand(key: roomKey),
          bottomNavBar: const SizedBox(height: 68, width: double.infinity),
          bottomOverlay: bottomOverlay,
          galleryOverlay: galleryOverlay,
        ),
      ),
    );
  }

  testWidgets('a taller bottom overlay does not resize the room', (
    tester,
  ) async {
    await tester.pumpWidget(build());
    final before = tester.getRect(find.byKey(roomKey));

    await tester.pumpWidget(build(bottomOverlay: const SizedBox(height: 90)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(find.byKey(roomKey)), before);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(roomKey)), before);
  });

  testWidgets(
    'furniture inventory takes the gallery slot without moving the room',
    (tester) async {
      await tester.pumpWidget(build());
      final before = tester.getRect(find.byKey(roomKey));

      const panelKey = Key('panel');
      await tester.pumpWidget(
        build(galleryOverlay: const SizedBox(key: panelKey, height: 2000)),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(roomKey)), before);
      expect(
        tester.getRect(find.byKey(panelKey)).bottom,
        lessThanOrEqualTo(before.top),
      );
    },
  );
}
