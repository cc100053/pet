import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/feed/feed_capture_view.dart';

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
}
