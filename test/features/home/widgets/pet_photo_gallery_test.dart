import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/pet_photo_gallery.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<String> createImageUrls(int count) {
    return List<String>.generate(
      count,
      (index) => 'https://example.com/image_$index.jpg',
      growable: false,
    );
  }

  Widget buildGallery({
    String? roomId = 'room-1',
    required List<String> imageUrls,
    required List<String?> captions,
    List<String?>? messageIds,
    int jumpToLatestEventId = 0,
    double width = 360,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PetPhotoGallery(
              roomId: roomId,
              imageUrls: imageUrls,
              captions: captions,
              sentAts: List<DateTime?>.generate(
                imageUrls.length,
                (index) => DateTime.utc(2026, 3, 12, 0, index),
              ),
              messageIds:
                  messageIds ??
                  List<String?>.generate(
                    imageUrls.length,
                    (index) => 'message-$index',
                  ),
              isRefreshing: false,
              jumpToLatestEventId: jumpToLatestEventId,
              senderAvatars: List<String?>.filled(imageUrls.length, null),
              senderFallbackTexts: List<String?>.generate(
                imageUrls.length,
                (index) => 'sender $index',
              ),
              onPlaceholderTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  Finder galleryItem(int index) =>
      find.byKey(ValueKey('pet-photo-gallery-item-$index'));

  SliverChildBuilderDelegate pageDelegate(WidgetTester tester) {
    final pageView = tester.widget<PageView>(
      find.byKey(const ValueKey('pet-photo-gallery-page-view')),
    );
    return pageView.childrenDelegate as SliverChildBuilderDelegate;
  }

  testWidgets('renders up to 10 recent photos', (WidgetTester tester) async {
    final imageUrls = createImageUrls(12);
    final captions = List<String?>.filled(imageUrls.length, null);

    await tester.pumpWidget(
      buildGallery(imageUrls: imageUrls, captions: captions),
    );
    await tester.pump();
    expect(pageDelegate(tester).childCount, 10);
  });

  testWidgets('keeps a minimum 3-slot gallery with placeholders', (
    WidgetTester tester,
  ) async {
    final imageUrls = createImageUrls(1);

    await tester.pumpWidget(
      buildGallery(
        imageUrls: imageUrls,
        captions: const <String?>['caption 0'],
      ),
    );
    await tester.pump();
    expect(pageDelegate(tester).childCount, 3);
  });

  testWidgets('jumps back to the newest photo after own feed success', (
    WidgetTester tester,
  ) async {
    final imageUrls = createImageUrls(4);
    final captions = List<String?>.generate(
      imageUrls.length,
      (index) => 'caption $index',
    );

    await tester.pumpWidget(
      buildGallery(imageUrls: imageUrls, captions: captions),
    );
    await tester.pump();
    final initialPageView = tester.widget<PageView>(
      find.byKey(const ValueKey('pet-photo-gallery-page-view')),
    );
    initialPageView.controller!.jumpToPage(2);
    await tester.pump();
    expect(initialPageView.controller!.page, 2);

    await tester.pumpWidget(
      buildGallery(
        imageUrls: imageUrls,
        captions: captions,
        jumpToLatestEventId: 1,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));

    final updatedPageView = tester.widget<PageView>(
      find.byKey(const ValueKey('pet-photo-gallery-page-view')),
    );
    expect(updatedPageView.controller!.page, 0);
  });

  testWidgets('uses single-line ellipsis and keeps caption above card bottom', (
    WidgetTester tester,
  ) async {
    const longCaption =
        'This caption is intentionally long so it must collapse with ellipsis instead of wrapping to a second line';
    final imageUrls = createImageUrls(1);

    await tester.pumpWidget(
      buildGallery(
        imageUrls: imageUrls,
        captions: const <String?>[longCaption],
        width: 320,
      ),
    );
    await tester.pump();

    final captionText = tester.widget<Text>(find.text(longCaption));
    expect(captionText.maxLines, 1);
    expect(captionText.softWrap, isFalse);
    expect(captionText.overflow, TextOverflow.ellipsis);

    final captionRect = tester.getRect(find.text(longCaption));
    final itemRect = tester.getRect(galleryItem(0));
    expect(itemRect.bottom - captionRect.bottom, greaterThan(6));
  });

  testWidgets('passes room and message linkage into fullscreen viewer', (
    WidgetTester tester,
  ) async {
    final imageUrls = createImageUrls(2);

    await tester.pumpWidget(
      buildGallery(
        roomId: 'room-42',
        imageUrls: imageUrls,
        captions: const <String?>['caption 0', 'caption 1'],
        messageIds: const <String?>['message-0', 'message-1'],
      ),
    );
    await tester.pump();

    await tester.tap(galleryItem(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final viewer = tester.widget<FullScreenPhotoViewer>(
      find.byType(FullScreenPhotoViewer),
    );
    expect(viewer.items.first.roomId, 'room-42');
    expect(viewer.items.first.messageId, 'message-0');
  });

  testWidgets('fullscreen viewer disables actions for unsynced local photos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildGallery(
        imageUrls: const <String>['/tmp/photo.jpg'],
        captions: const <String?>['caption 0'],
        messageIds: const <String?>[null],
      ),
    );
    await tester.pump();

    await tester.tap(galleryItem(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

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
}
