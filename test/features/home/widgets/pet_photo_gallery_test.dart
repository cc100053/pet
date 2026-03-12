import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/pet_photo_gallery.dart';
import 'package:pet/l10n/app_localizations.dart';

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
    required List<String> imageUrls,
    required List<String?> captions,
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
              imageUrls: imageUrls,
              captions: captions,
              sentAts: List<DateTime?>.generate(
                imageUrls.length,
                (index) => DateTime.utc(2026, 3, 12, 0, index),
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
}
