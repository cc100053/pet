import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const functionPath = 'supabase/functions/cleanup_abandoned_rooms/index.ts';
  const migrationPath =
      'supabase/migrations/20260607135307_guard_cleanup_purge_activity.sql';

  late String functionSource;
  late String migrationSource;

  setUpAll(() {
    functionSource = File(functionPath).readAsStringSync();
    migrationSource = File(migrationPath).readAsStringSync();
  });

  test('purge rechecks live room activity before deleting R2 objects', () {
    expect(functionSource, contains('function purgeIneligibilityReason'));
    expect(functionSource, contains('room_activity_after_scan'));
    expect(functionSource, contains('room_no_longer_stale'));
    expect(functionSource, contains('fetchRoomActivity'));
    expect(functionSource, contains('preDeleteReason'));
  });

  test('purge fails closed when R2 changed after the scan snapshot', () {
    expect(functionSource, contains('function r2SnapshotChangeReason'));
    expect(functionSource, contains('lastModifiedMs'));
    expect(functionSource, contains('r2_objects_changed_after_scan'));
    expect(functionSource, contains('r2_object_count_increased_after_scan'));
  });

  test('purge does not reuse stale approved candidates', () {
    expect(functionSource, contains('resetCleanupCandidateApproval'));
    expect(functionSource, contains('candidate_no_longer_approved'));
    expect(functionSource, contains('candidate_snapshot_changed'));
    expect(functionSource, contains('rooms_skipped'));
  });

  test('room activity trigger resets approved cleanup candidates', () {
    expect(
      migrationSource,
      contains('reset_cleanup_candidate_on_room_activity'),
    );
    expect(migrationSource, contains("review_status = 'pending'"));
    expect(migrationSource, contains('reviewed_at = null'));
    expect(
      migrationSource,
      contains('trg_rooms_cleanup_candidate_activity_reset'),
    );
    expect(
      migrationSource,
      contains('after update of last_activity_at on public.rooms'),
    );
  });
}
