import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';
import 'package:photo_view/photo_view_gallery.dart';

Future<void> _pumpViewer(
  WidgetTester tester, {
  required List<PhotoViewerItem> items,
  bool settle = true,
  BaseCacheManager? cacheManager,
  PhotoViewerReplyHandler? onSendReply,
  PhotoViewerReactionHandler? onToggleReaction,
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
      home: FullScreenPhotoViewer(
        items: items,
        cacheManager: cacheManager,
        onSendReply: onSendReply,
        onToggleReaction: onToggleReaction,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

void main() {
  test('fullscreen decode target matches viewport pixel bounds', () {
    expect(
      fullscreenPhotoDecodeTargetForViewport(const Size(390, 844), 3.0),
      isA<PhotoViewerDecodeTarget>()
          .having((target) => target.width, 'width', 1170)
          .having((target) => target.height, 'height', 2532),
    );
  });

  testWidgets('fullscreen viewer bounds remote decode to viewport size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(imageUrl: 'https://example.com/test.jpg'),
      ],
      settle: false,
      cacheManager: _NotFoundCacheManager(),
    );

    final gallery = tester.widget<PhotoViewGallery>(
      find.byType(PhotoViewGallery),
    );
    final option = gallery.builder!(
      tester.element(find.byType(PhotoViewGallery)),
      0,
    );
    final provider = option.imageProvider;
    expect(provider, isA<ResizeImage>());

    final resizeImage = provider! as ResizeImage;
    expect(resizeImage.width, 800);
    expect(resizeImage.height, 1600);
    expect(resizeImage.imageProvider, isA<CachedNetworkImageProvider>());
  });

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

  testWidgets('shows reply and emoji actions for chat-backed photos', (
    tester,
  ) async {
    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(
          imageUrl: '',
          roomId: 'room-1',
          messageId: 'message-1',
        ),
      ],
      onSendReply: (item, text) async {},
      onToggleReaction: (item, emoji, currentReactionEmoji) async {},
    );

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-reply-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-emoji-button')),
      findsOneWidget,
    );
  });

  testWidgets('disables reply and emoji actions when message id is missing', (
    tester,
  ) async {
    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(imageUrl: '', roomId: 'room-1'),
      ],
      onSendReply: (item, text) async {},
      onToggleReaction: (item, emoji, currentReactionEmoji) async {},
    );

    final replyButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('photo-viewer-reply-button')),
        matching: find.byType(InkWell),
      ),
    );
    final emojiButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('photo-viewer-emoji-button')),
        matching: find.byType(InkWell),
      ),
    );

    expect(replyButton.onTap, isNull);
    expect(emojiButton.onTap, isNull);
  });

  testWidgets('opens reply sheet and forwards submitted text', (tester) async {
    String? repliedText;

    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(
          imageUrl: '',
          roomId: 'room-1',
          messageId: 'message-1',
        ),
      ],
      onSendReply: (_, text) async {
        repliedText = text;
      },
      onToggleReaction: (item, emoji, currentReactionEmoji) async {},
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('photo-viewer-reply-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-reply-text-field')),
      findsOneWidget,
    );
    final replyField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('photo-viewer-reply-text-field')),
    );
    expect(replyField.textInputAction, isNull);
    await tester.enterText(
      find.byKey(const ValueKey<String>('photo-viewer-reply-text-field')),
      'Quick reply',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('photo-viewer-reply-send-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(repliedText, 'Quick reply');
    expect(find.text('Sent'), findsOneWidget);
  });

  testWidgets('opens emoji picker and forwards selected emoji', (tester) async {
    String? selectedEmoji;

    await _pumpViewer(
      tester,
      items: <PhotoViewerItem>[
        const PhotoViewerItem(
          imageUrl: '',
          roomId: 'room-1',
          messageId: 'message-1',
        ),
      ],
      onSendReply: (item, text) async {},
      onToggleReaction: (item, emoji, currentReactionEmoji) async {
        selectedEmoji = emoji;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('photo-viewer-emoji-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('❤️'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(selectedEmoji, '❤️');
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
