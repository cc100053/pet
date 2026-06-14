import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/features/feed/feed_capture_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  test('dispatchFeedCaptureCallback runs the callback', () {
    var called = false;

    dispatchFeedCaptureCallback(
      callbackName: 'test_callback',
      callback: () => called = true,
    );

    expect(called, isTrue);
  });

  test('dispatchFeedCaptureCallback swallows callback errors', () {
    final reportedErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    var called = false;

    expect(
      () => dispatchFeedCaptureCallback(
        callbackName: 'test_callback',
        callback: () {
          called = true;
          throw StateError('boom');
        },
      ),
      returnsNormally,
    );

    expect(called, isTrue);
    expect(reportedErrors, hasLength(1));
    expect(reportedErrors.single.exception, isA<StateError>());
    expect(
      reportedErrors.single.context!.toDescription(),
      contains('while running test_callback'),
    );
  });

  test('dispatchFeedCaptureAsyncCallback swallows callback errors', () async {
    final reportedErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    var called = false;

    await dispatchFeedCaptureAsyncCallback(
      callbackName: 'test_async_callback',
      callback: () async {
        called = true;
        throw StateError('boom');
      },
    );

    expect(called, isTrue);
    expect(reportedErrors, hasLength(1));
    expect(reportedErrors.single.exception, isA<StateError>());
    expect(
      reportedErrors.single.context!.toDescription(),
      contains('while running test_async_callback'),
    );
  });

  test(
    'dispatchFeedCaptureAsyncCallback waits for callback completion',
    () async {
      final completer = Completer<void>();
      var completed = false;

      final future = dispatchFeedCaptureAsyncCallback(
        callbackName: 'test_async_callback',
        callback: () => completer.future,
      ).then((_) => completed = true);

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      completer.complete();
      await future;

      expect(completed, isTrue);
    },
  );

  testWidgets('ignores picked images after the capture route is disposed', (
    WidgetTester tester,
  ) async {
    final pickerCompleter = Completer<XFile?>();
    final reportedErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) => pickerCompleter.future,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_library_rounded));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    pickerCompleter.complete(
      XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'picked.jpg',
        mimeType: 'image/jpeg',
      ),
    );
    await tester.pump();

    expect(reportedErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
