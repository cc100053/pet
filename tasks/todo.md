# TODO

## Plan (2026-09-13 Shared Room Frames)
- [x] Add additive member-only room-frame state and server level validation; preserve all existing contracts.
- [x] Save explicit frame confirmations to Supabase, reconcile/realtime-sync all active rooms, and retain Hive fallback without auto-uploading it.
- [x] Test failed saves, shared reconciliation, stale responses, and server authorization/level boundaries.
- [x] Update current-state/release docs, run final format/analyze/tests, commit and push.

Contract: legacy Hive `room_frame_styles` remains the fallback/cache (`roomId -> storageKey`); existing frame ids and unlock levels are unchanged. New `room_frame_state(room_id, style, updated_at)` is independent of existing room/background/shop RPCs. Only active members can read/equip; explicit confirmation is last-writer-wins. No automatic migration of conflicting local choices. Old binaries ignore the table; next app build consumes it. Rollback: revert client integration; old storage and RPCs remain usable.

## Review (2026-09-13 Shared Room Frames)
- Applied migration on verified `ilxzpszgirhwxpeocygs` (live `20260912151653`);
  pre/post-apply transactional SQL authorization/level/partner/upsert probes
  passed and rolled back. No pet/member writes; read-back shows 0 frame rows.
  Security/performance advisors have no findings for the new objects.
- Final `dart format --output=none --set-exit-if-changed lib test`: 331 files,
  0 changed; `flutter analyze`: clean; `flutter test`: 667 passed, 1 documented
  env-dependent integration skip. Focused frame tests: 35 passed.
- Real-device two-client realtime/background verification remains a release
  follow-up. This integration is not included in uploaded `3.1.0+23`; no app
  build/upload/submission was requested.

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260818_pre_compaction.md`.

## Plan (2026-08-18 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, repo-local workflows,
      recent commits, and the full worktree.
- [x] Archive exact pre-compaction snapshots and compact active memory/task
      notes to current decisions, contracts, and follow-ups.
- [x] Add only verified, non-duplicative workflow guidance to `AGENTS.md`.
- [x] Inspect the complete diff and run required format/analyzer/tests.
- [x] Commit all legitimate changes in logical groups, push `main`, verify the
      remote SHA, and leave a clean worktree.

## Active Follow-ups
- [ ] Decide whether any room-frame casing belongs in the shop. This needs an
      `items` row, a price from `docs/shop_pricing.md`, and migration /
      old-client compatibility approval.
- [ ] Real-device verify shared frames in two upgraded clients once the next
      app build is distributed; legacy-only choices are shared on Done.
- [ ] Monitor ASC/store outcome for iOS `3.1.0+23`; submit for App Review only
      after an explicit request.
- [ ] Confirm build 23's Runner UUID
      `1074123E-B8C3-3470-9A05-F5D2ACAF3F78` and App.framework UUID
      `0C7143A3-F470-6FF3-485E-50E695C70643` are absent from Crashlytics →
      Settings → Missing dSYMs `[USER ACTION REQUIRED]`.
- [x] Confirm build 22's recorded UUIDs (Runner
      `3D5833E2-B9BC-3107-9C9C-15DEFC0C5886`, App.framework
      `0C7143A3-330B-1F8B-485E-50E6EF09C56E`) are absent from Crashlytics →
      Settings → Missing dSYMs — confirmed 2026-08-26.
- [x] Confirm build 21's recorded UUIDs are absent from Crashlytics Missing
      dSYMs — confirmed 2026-08-20.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and
      `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm organic post-deploy timing for timezone-normalized pet RPCs.
- [ ] Add a leak regression test for `CachedNetworkImageView` if its cache
      manager harness can be stabilized without hanging `flutter test`.
- [ ] Convert source-text app tests to behavioral coverage where practical.
- [ ] Instrument remaining best-effort bare catches opportunistically with
      `reportSwallowedError(...)`.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Current References
- Release/build/backend truth: `docs/release_status.md`.
- Full pre-compaction task state:
  `tasks/archive/todo_20260818_pre_compaction.md`.

## Plan (2026-09-01 PetTomo 3.1.0 Release Notes Sync)
- [x] Update `3.1.0+23` versioning and localized bundled/ASC notes.
- [x] Create ASC version, sync four locales, and verify the EULA metadata.
- [x] Build, upload, process, and attach iOS build 23.
- [x] Upload all 12 dSYMs and preserve the archive.
- [x] Record release IDs and current baseline in the release ledger.
- [ ] Complete the Crashlytics Missing dSYMs check `[USER ACTION REQUIRED]`.

## Review (2026-09-01 PetTomo 3.1.0 Release Notes Sync)
- `dart format --output=none --set-exit-if-changed lib test`: 329 files, 0 changed.
- `flutter analyze`: passed with no issues.
- `flutter test`: 656 passed, 1 documented integration skip.
- ASC version `00203205-22bc-4b4d-94bc-8802b7839892` is
  `PREPARE_FOR_SUBMISSION`; build `00e52973-ae37-4ce9-9b70-47eb50762e3c` is
  `VALID` and attached.
- App Review submission was not requested or performed.

## Review (2026-08-18 Agent Docs And Memory Optimization)
- Added a narrow `AGENTS.md` TODO for the pet-socket skill's broken bare helper
  paths and clarified touched-file formatting versus the non-writing final
  whole-tree check. No runtime or generated files changed.
- Active memory fell from 382 to 299 lines: architecture 73→73, database schema
  78→74, progress 109→65, tech stack 38→38, and UI/UX 84→49.
  `tasks/todo.md` fell from 168 baseline lines to this compact active file.
- Preserved exact pre-compaction memory snapshots in
  `memory-bank/archive/*_20260818_pre_compaction.md`; preserved the post-plan
  178-line task snapshot in `tasks/archive/todo_20260818_pre_compaction.md`.
- `git diff --check` passed. The final format check reported 328 files and 0
  changes. `flutter analyze` passed with no issues. `flutter test` passed 642
  tests with 1 skip: `feed_flow_integration_test.dart` requires unset
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`.
