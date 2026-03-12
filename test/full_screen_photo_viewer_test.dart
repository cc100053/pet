import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';

Future<void> _pumpViewer(
  WidgetTester tester, {
  required List<PhotoViewerItem> items,
  bool settle = true,
  BaseCacheManager? cacheManager,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FullScreenPhotoViewer(items: items, cacheManager: cacheManager),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('renders fullscreen metadata and caption overlays', (
    tester,
  ) async {
    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        PhotoViewerItem(
          imageUrl: '',
          caption: 'Bedtime memory',
          senderName: 'Alex',
          sentAt: DateTime(2026, 3, 8, 21, 30),
        ),
      ],
    );

    expect(find.text('Bedtime memory'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-meta')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-caption')),
      findsOneWidget,
    );
  });

  testWidgets('omits metadata chrome when viewer item has no extra info', (
    tester,
  ) async {
    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[const PhotoViewerItem(imageUrl: '')],
    );

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-meta')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-caption')),
      findsNothing,
    );
  });

  testWidgets('shows broken image fallback when remote photo returns 404', (
    tester,
  ) async {
    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(imageUrl: 'https://example.com/test.jpg'),
      ],
      settle: false,
      cacheManager: _NotFoundCacheManager(),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-broken-image')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _NotFoundCacheManager implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return Stream<FileResponse>.error(
      HttpExceptionWithStatus(
        404,
        'Invalid statusCode: 404',
        uri: Uri.parse(url),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
