import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract tests for the Phase 4b additive home-summary RPCs and the client
/// wiring that consumes them. The migration is the source of truth; old app
/// versions keep using their direct queries, so this only asserts the new path
/// exists and is backward-compatible (additive, SECURITY INVOKER).
void main() {
  String read(String path) => File(path).readAsStringSync();

  final migration = read(
    'supabase/migrations/20260610120000_add_room_home_summary_rpcs.sql',
  );
  final roomManager = read(
    'lib/features/home/controllers/home_room_manager.dart',
  );

  group('migration', () {
    test('defines both additive RPCs as SECURITY INVOKER', () {
      expect(
        migration,
        contains('create or replace function public.get_room_latest_feeds('),
      );
      expect(
        migration,
        contains('create or replace function public.get_room_member_counts('),
      );
      // RLS must keep doing the access control — INVOKER, not DEFINER.
      expect('security invoker'.allMatches(migration).length, 2);
      expect(migration, isNot(contains('security definer')));
    });

    test('grants execute to authenticated only (not anon)', () {
      expect(
        migration,
        contains('grant execute on function public.get_room_latest_feeds'),
      );
      expect(
        migration,
        contains('grant execute on function public.get_room_member_counts'),
      );
      expect(migration, contains('revoke all on function'));
      expect(migration, isNot(contains('to anon')));
    });

    test('latest feeds is limited per room, not globally', () {
      // The defect being fixed: a single global LIMIT across all rooms.
      expect(migration, contains('cross join lateral'));
      expect(migration, contains('distinct on (m.image_url)'));
      expect(migration, contains('limit least(greatest(p_per_room_limit, 0), 50)'));
    });
  });

  group('client wiring', () {
    test('member counts come from the aggregate RPC', () {
      expect(roomManager, contains("'get_room_member_counts'"));
      // The old "select every member row and count in Dart" path is gone.
      expect(roomManager, isNot(contains(".select('room_id')\n")));
    });

    test('latest feeds come from the per-room RPC', () {
      expect(roomManager, contains("'get_room_latest_feeds'"));
      expect(roomManager, contains("'p_per_room_limit': kPetHomeGalleryMaxPhotos"));
      // The old global-limit heuristic is gone.
      expect(
        roomManager,
        isNot(contains('roomIds.length * kPetHomeGalleryMaxPhotos * 3')),
      );
    });
  });
}
