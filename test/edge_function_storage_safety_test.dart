import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level contract tests for the Phase 0/1 Edge Function hardening:
/// shared helpers, R2 orphan cleanup, avatar replacement cleanup, and
/// timing-safe secret comparison. Edge Functions cannot be reliably executed in
/// the Flutter test runtime, so we assert on the source seam (same approach as
/// `feed_validate_function_test.dart` / `cleanup_abandoned_rooms_safety_test.dart`).
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('shared edge function modules', () {
    test('shared http/images/auth modules exist with expected exports', () {
      final http = read('supabase/functions/_shared/http.ts');
      expect(http, contains('export const corsHeaders'));
      expect(http, contains('export function jsonResponse'));

      final images = read('supabase/functions/_shared/images.ts');
      expect(images, contains('export async function uploadToR2'));
      expect(images, contains('export async function deleteFromR2'));
      expect(images, contains('export function r2KeyFromPublicUrl'));
      expect(images, contains('export const ALLOWED_IMAGE_CONTENT_TYPES'));
      expect(images, contains('export const MAX_IMAGE_BYTES'));

      final auth = read('supabase/functions/_shared/auth.ts');
      expect(auth, contains('export function timingSafeEqual'));
    });

    test('feed_validate and avatar_upload consume the shared helpers', () {
      final feed = read(
        'supabase/functions/notify_friend/feed_validate/index.ts',
      );
      expect(feed, contains('../../_shared/http.ts'));
      expect(feed, contains('../../_shared/images.ts'));
      // The duplicated local copies must be gone.
      expect(feed, isNot(contains('function decodeBase64')));
      expect(feed, isNot(contains('async function uploadToR2')));

      final avatar = read('supabase/functions/avatar_upload/index.ts');
      expect(avatar, contains('../_shared/http.ts'));
      expect(avatar, contains('../_shared/images.ts'));
      expect(avatar, isNot(contains('function decodeBase64')));
      expect(avatar, isNot(contains('async function uploadToR2')));
    });
  });

  group('R2 orphan cleanup', () {
    test('feed_validate deletes the uploaded object when the RPC fails', () {
      final feed = read(
        'supabase/functions/notify_friend/feed_validate/index.ts',
      );
      // Tracks the object it owns and reclaims it on the rolled-back RPC path.
      expect(feed, contains('let uploadedKey: string | null = null'));
      expect(feed, contains('uploadedKey = key'));
      expect(
        feed,
        contains(
          RegExp(r'if \(processFeedError\)[\s\S]*?deleteFromR2\(uploadedKey\)'),
        ),
      );
    });

    test('avatar_upload removes the previous avatar after replacing it', () {
      final avatar = read('supabase/functions/avatar_upload/index.ts');
      expect(avatar, contains('previousAvatarUrl'));
      expect(avatar, contains('r2KeyFromPublicUrl(previousAvatarUrl)'));
      expect(avatar, contains('deleteFromR2(previousKey)'));
      // And it cleans up the new object if the profile update fails.
      expect(
        avatar,
        contains(RegExp(r'if \(updateError\)[\s\S]*?deleteFromR2\(key\)')),
      );
    });
  });

  group('timing-safe secret comparison', () {
    test('notify_friend uses timingSafeEqual for the webhook secret', () {
      final notify = read('supabase/functions/notify_friend/index.ts');
      expect(notify, contains('../_shared/auth.ts'));
      expect(notify, contains('timingSafeEqual(authHeader'));
      expect(
        notify,
        isNot(contains(r'authHeader === `Bearer ${NOTIFY_WEBHOOK_SECRET}`')),
      );
    });

    test(
      'hunger_tick_dispatch uses timingSafeEqual for the scheduler secret',
      () {
        final hunger = read('supabase/functions/hunger_tick_dispatch/index.ts');
        expect(hunger, contains('../_shared/auth.ts'));
        expect(hunger, contains('timingSafeEqual(authHeader'));
        expect(
          hunger,
          isNot(
            contains(r'authHeader !== `Bearer ${expectedSchedulerSecret}`'),
          ),
        );
      },
    );
  });
}
