import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/features/feed/feed_capture_view.dart';
import 'package:pet/features/feed/feed_photo_loading.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/juice_wrappers.dart';

class _DelayedPhoto extends XFile {
  _DelayedPhoto(this.bytes) : super('picked.png');

  final Future<Uint8List> bytes;

  @override
  Future<Uint8List> readAsBytes() => bytes;
}

void main() {
  testWidgets(
    'waits for selection and slow preview before loading, blocks replacement send',
    (tester) async {
      var pickerCompleter = Completer<XFile?>();
      final bytesCompleter = Completer<Uint8List>();
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
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(FeedPhotoLoading), findsNothing);
      expect(
        tester
            .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
            .onTap,
        isNull,
      );

      pickerCompleter.complete(_DelayedPhoto(bytesCompleter.future));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 249));
      expect(find.byType(FeedPhotoLoading), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(FeedPhotoLoading), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Lunch');

      await tester.runAsync(() async {
        bytesCompleter.complete(
          File(
            'assets/pet_sequences/cat/stay/cat_stay-01.png',
          ).readAsBytesSync(),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FeedPhotoLoading), findsNothing);
      expect(
        tester
            .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
            .onTap,
        isNotNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Lunch',
      );

      pickerCompleter = Completer<XFile?>();
      await tester.tap(find.byIcon(Icons.photo_library_rounded));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(FeedPhotoLoading), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester
            .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
            .onTap,
        isNull,
      );
      pickerCompleter.complete(null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FeedPhotoLoading), findsNothing);
      expect(
        tester
            .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
            .onTap,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('fast preview never flashes loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) async => XFile.fromData(
              File(
                'assets/pet_sequences/cat/stay/cat_stay-01.png',
              ).readAsBytesSync(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo_library_rounded));
    await tester.pump();
    expect(find.byType(FeedPhotoLoading), findsNothing);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(FeedPhotoLoading), findsNothing);
    expect(
      tester
          .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
          .onTap,
      isNotNull,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FeedPhotoLoading), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during photo read cancels delayed loading', (
    tester,
  ) async {
    final bytesCompleter = Completer<Uint8List>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) async => _DelayedPhoto(bytesCompleter.future),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    bytesCompleter.complete(Uint8List(0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable photo ends loading and allows another pick', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) async {
              attempts++;
              return XFile.fromData(Uint8List.fromList([1, 2, 3]));
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.photo_library_rounded));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FeedPhotoLoading), findsNothing);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(FeedCaptureView)),
    )!;
    expect(find.text(l10n.errorUnexpected), findsOneWidget);
    expect(
      tester
          .widget<HardShadowPressButton>(find.byType(HardShadowPressButton))
          .onTap,
      isNull,
    );
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

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
    await tester.pump(const Duration(milliseconds: 400));
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

  testWidgets('surfaces denied camera access as a permission message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) async =>
                throw PlatformException(code: 'camera_access_denied'),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(FeedCaptureView)),
    )!;
    expect(find.text(l10n.errorMediaPermissionDenied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays silent when a pick is cancelled by a second request', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) async =>
                throw PlatformException(code: 'multiple_request'),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_library_rounded));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(FeedCaptureView)),
    )!;
    expect(find.text(l10n.errorMediaPermissionDenied), findsNothing);
    expect(find.text(l10n.errorUnexpected), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not start a second pick while one is in flight', (
    WidgetTester tester,
  ) async {
    final pickerCompleter = Completer<XFile?>();
    var pickCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedCaptureView(
            roomId: 'room-1',
            pickImage: (_) {
              pickCount++;
              return pickerCompleter.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.photo_library_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();

    expect(pickCount, 1);

    pickerCompleter.complete(null);
    await tester.pumpAndSettle();

    // The guard releases once the in-flight request settles.
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    expect(pickCount, 2);
  });
}
