import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';

Future<void> _pumpViewer(
  WidgetTester tester, {
  required List<PhotoViewerItem> items,
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
      home: FullScreenPhotoViewer(items: items),
    ),
  );
  await tester.pumpAndSettle();
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
}
