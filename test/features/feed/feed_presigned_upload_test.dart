import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/app_config/app_config_service.dart';

/// Phase 3: direct-to-R2 presigned feed upload. The path is server-controlled
/// (default OFF via app_config) with a base64 fallback, and all server pieces
/// are additive + backward-compatible. These cover the flag parsing plus
/// source-level contracts for the edge functions and client wiring.
void main() {
  group('AppConfigService.fetchBoolFlag', () {
    Future<bool> resolve(Object? value, {bool defaultValue = false}) {
      final service = AppConfigService(configValueLoader: (_) async => value);
      return service.fetchBoolFlag(
        'feed_presigned_upload_enabled',
        defaultValue: defaultValue,
      );
    }

    test('missing key falls back to the default (off)', () async {
      expect(await resolve(null), isFalse);
      expect(await resolve(null, defaultValue: true), isTrue);
    });

    test('parses native bools and string forms', () async {
      expect(await resolve(true), isTrue);
      expect(await resolve(false), isFalse);
      expect(await resolve('true'), isTrue);
      expect(await resolve('false'), isFalse);
      expect(await resolve('1'), isTrue);
      expect(await resolve('0'), isFalse);
    });

    test('unparseable value keeps the default', () async {
      expect(await resolve('maybe'), isFalse);
      expect(await resolve('maybe', defaultValue: true), isTrue);
    });

    test('respects a platform map shape', () async {
      // _valueForPlatform picks default/all when no platform-specific key.
      expect(await resolve({'all': 'true'}), isTrue);
      expect(await resolve({'default': false}), isFalse);
    });
  });

  group('edge function contracts', () {
    String fn(String path) =>
        File('supabase/functions/$path').readAsStringSync();

    test(
      'feed_upload_url verifies membership and scopes the key to the room',
      () {
        final src = fn('feed_upload_url/index.ts');
        expect(src, contains('.from("room_members")'));
        expect(src, contains('rooms/\${roomId}/'));
        expect(src, contains('presignR2PutUrl(key'));
        expect(src, contains('ALLOWED_IMAGE_CONTENT_TYPES.has(contentType)'));
        expect(src, contains('public_url:'));
      },
    );

    test('images shared module presigns only host (content-type unsigned)', () {
      final src = fn('_shared/images.ts');
      expect(src, contains('export async function presignR2PutUrl'));
      expect(src, contains('signQuery: true'));
    });

    test(
      'feed_validate only accepts client image_url under the room prefix',
      () {
        final src = fn('notify_friend/feed_validate/index.ts');
        expect(src, contains('if (uploadedKey == null)'));
        expect(src, contains('rooms/\${roomId}/'));
        expect(src, contains("error: \"invalid_image_url\""));
      },
    );
  });

  group('client wiring', () {
    final client = File(
      'lib/features/feed/feed_upload_client.dart',
    ).readAsStringSync();

    test('presigned upload is gated and falls back to base64', () {
      expect(client, contains("if (dart.library.io) 'feed_r2_put_io.dart'"));
      expect(client, contains('_tryBuildPresignedFeedBody'));
      expect(client, contains('_base64FeedBody('));
      expect(client, contains('putBytesToPresignedUrl'));
      expect(client, contains("static const String presignedUploadFlagKey ="));
    });

    test('flag failures default to disabled (base64)', () {
      // _presignedUploadEnabled swallows loader errors and caches false.
      expect(client, contains('enabled = false;'));
    });
  });
}
