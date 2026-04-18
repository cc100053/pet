import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/avatar_position_editor_page.dart';

void main() {
  testWidgets('cancel returns null without saving framing', (tester) async {
    final image = await _testImage(width: 2, height: 1);
    AvatarFramingData? result;
    var completed = false;

    await _pumpHarness(
      tester,
      imageProvider: image,
      onResult: (value) {
        result = value;
        completed = true;
      },
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-editor')));
    await _pumpRoute(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-cancel-button')),
    );
    await _pumpRoute(tester);

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('dragging the fixed crop frame updates alignment', (
    tester,
  ) async {
    final image = await _testImage(width: 2, height: 1);
    AvatarFramingData? result;

    await _pumpHarness(
      tester,
      imageProvider: image,
      initialFraming: const AvatarFramingData(
        alignment: Alignment.center,
        scale: 2,
      ),
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-editor')));
    await _pumpRoute(tester);
    await tester.drag(
      find.byKey(const ValueKey<String>('avatar-editor-gesture-area')),
      const Offset(48, 0),
    );
    await _pumpRoute(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-save-button')),
    );
    await _pumpRoute(tester);

    expect(result, isNotNull);
    expect(result!.alignment.x, greaterThan(0));
    expect(result!.alignment.y, closeTo(0, 0.0001));
    expect(result!.scale, closeTo(2, 0.0001));
  });

  testWidgets('pinch gesture increases zoom', (tester) async {
    final image = await _testImage(width: 1, height: 1);
    AvatarFramingData? result;

    await _pumpHarness(
      tester,
      imageProvider: image,
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-editor')));
    await _pumpRoute(tester);

    final gestureArea = find.byKey(
      const ValueKey<String>('avatar-editor-gesture-area'),
    );
    final center = tester.getCenter(gestureArea);
    final first = await tester.startGesture(center - const Offset(24, 0));
    final second = await tester.startGesture(center + const Offset(24, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(72, 0));
    await second.moveTo(center + const Offset(72, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await _pumpRoute(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-save-button')),
    );
    await _pumpRoute(tester);

    expect(result, isNotNull);
    expect(result!.scale, greaterThan(1));
  });

  testWidgets('zoom slider updates saved scale', (tester) async {
    final image = await _testImage(width: 1, height: 1);
    AvatarFramingData? result;

    await _pumpHarness(
      tester,
      imageProvider: image,
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-editor')));
    await _pumpRoute(tester);
    await tester.drag(
      find.byKey(const ValueKey<String>('avatar-editor-zoom-slider')),
      const Offset(120, 0),
    );
    await _pumpRoute(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-save-button')),
    );
    await _pumpRoute(tester);

    expect(result, isNotNull);
    expect(result!.scale, greaterThan(1));
  });

  testWidgets('center action resets alignment and zoom', (tester) async {
    final image = await _testImage(width: 2, height: 1);
    AvatarFramingData? result;

    await _pumpHarness(
      tester,
      imageProvider: image,
      initialFraming: const AvatarFramingData(
        alignment: Alignment(0.9, -0.4),
        scale: 2.4,
      ),
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-editor')));
    await _pumpRoute(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-reset-button')),
    );
    await _pumpRoute(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-editor-save-button')),
    );
    await _pumpRoute(tester);

    expect(result, isNotNull);
    expect(result!.alignment, Alignment.center);
    expect(result!.scale, 1);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required ImageProvider imageProvider,
  required ValueChanged<AvatarFramingData?> onResult,
  AvatarFramingData initialFraming = const AvatarFramingData(
    alignment: Alignment.center,
    scale: 1,
  ),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey<String>('open-editor'),
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<AvatarFramingData>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => AvatarPositionEditorPage(
                            imageProvider: imageProvider,
                            initialFraming: initialFraming,
                            title: 'Edit avatar',
                            applyLabel: 'Save',
                            cancelLabel: 'Cancel',
                            hintLabel: 'Drag to position. Pinch to zoom.',
                            zoomLabel: 'Zoom',
                            resetLabel: 'Center',
                          ),
                        ),
                      );
                  onResult(result);
                },
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<ImageProvider> _testImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = Colors.orange;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  return _StaticImageProvider(image);
}

class _StaticImageProvider extends ImageProvider<_StaticImageProvider> {
  const _StaticImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_StaticImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_StaticImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _StaticImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image)),
    );
  }
}
