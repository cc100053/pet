import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';

void main() {
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
