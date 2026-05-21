import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';
import 'package:pet/shared/utils/avatar_display_position.dart';

void main() {
  testWidgets('sizes remote image cache to rendered layout bounds', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 80,
              child: CachedNetworkImageView(
                imageUrl: 'https://example.com/image.jpg',
                cacheManager: _NotFoundCacheManager(),
              ),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 240);
    expect(image.memCacheHeight, 160);
    expect(image.maxWidthDiskCache, 240);
    expect(image.maxHeightDiskCache, 160);
  });

  testWidgets('shows error widget when remote image returns 404', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CachedNetworkImageView(
                imageUrl: 'https://example.com/missing.jpg',
                cacheManager: _NotFoundCacheManager(),
                errorWidget: const ColoredBox(
                  key: ValueKey<String>('cached-network-image-error'),
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey<String>('cached-network-image-error')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores infinite explicit width when resolving cache size', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: CachedNetworkImageView(
              imageUrl: 'https://example.com/image.jpg',
              width: double.infinity,
              height: 200,
              cacheManager: _NotFoundCacheManager(),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 360);
    expect(image.memCacheHeight, 400);
    expect(tester.takeException(), isNull);
  });

  group('shouldUseAvatarFraming', () {
    // Regression: a full-width letterboxed image (e.g. the memory calendar day
    // sheet uses width: double.infinity, height: 200) must NOT engage avatar
    // framing. The framing path clamps the infinite viewport to ~1px and the
    // image disappears, so it must fall through to the plain BoxFit path.
    test('does not frame when width is infinite', () {
      expect(
        shouldUseAvatarFraming(
          avatarScaleMode: AvatarScaleMode.relativeZoom,
          width: double.infinity,
          height: 200,
        ),
        isFalse,
      );
    });

    test('does not frame when height is infinite', () {
      expect(
        shouldUseAvatarFraming(
          avatarScaleMode: AvatarScaleMode.relativeZoom,
          width: 200,
          height: double.infinity,
        ),
        isFalse,
      );
    });

    test('frames finite relative-zoom dimensions (e.g. circular avatars)', () {
      expect(
        shouldUseAvatarFraming(
          avatarScaleMode: AvatarScaleMode.relativeZoom,
          width: 48,
          height: 48,
        ),
        isTrue,
      );
    });

    test('does not frame legacy-absolute mode', () {
      expect(
        shouldUseAvatarFraming(
          avatarScaleMode: AvatarScaleMode.legacyAbsolute,
          width: 48,
          height: 48,
        ),
        isFalse,
      );
    });

    test('does not frame when a dimension is null', () {
      expect(
        shouldUseAvatarFraming(
          avatarScaleMode: AvatarScaleMode.relativeZoom,
          width: 48,
          height: null,
        ),
        isFalse,
      );
    });
  });

  testWidgets('skips cache sizing when scale is NaN', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 80,
            child: CachedNetworkImageView(
              imageUrl: 'https://example.com/image.jpg',
              scale: double.nan,
              cacheManager: _NotFoundCacheManager(),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, isNull);
    expect(image.memCacheHeight, isNull);
    expect(image.maxWidthDiskCache, isNull);
    expect(image.maxHeightDiskCache, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skips cache sizing when scale is infinite', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 80,
            child: CachedNetworkImageView(
              imageUrl: 'https://example.com/image.jpg',
              scale: double.infinity,
              cacheManager: _NotFoundCacheManager(),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, isNull);
    expect(image.memCacheHeight, isNull);
    expect(image.maxWidthDiskCache, isNull);
    expect(image.maxHeightDiskCache, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caps oversized cache dimensions per side', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: CachedNetworkImageView(
              imageUrl: 'https://example.com/image.jpg',
              scale: 4,
              cacheManager: _NotFoundCacheManager(),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 2048);
    expect(image.memCacheHeight, 2048);
    expect(image.maxWidthDiskCache, 2048);
    expect(image.maxHeightDiskCache, 2048);
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
