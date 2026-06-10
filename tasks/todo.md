# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260606_pre_compaction.md`.

## Active Follow-ups
- [~] Build/upload/attach the `2.1.0+5` iOS release build.
      Built `build/ios/ipa/PetTomo.ipa`, verified packaged Info.plist, uploaded
      build `67f39308-02eb-4a9a-9d32-64698ea4d99b`, and waited until `VALID`.
      Still attach it to ASC version `2.1.0`
      (`37897d26-cc47-492c-867f-c7bc3ee4d44b`) before submission.
      Keep `docs/release_status.md` updated as ASC state changes.
- [ ] Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
      8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
      deployment config; current `verify_jwt` behavior is documented but no
      `supabase/config.toml` exists.

## Plan (2026-06-07 Cleanup Purge Safety Hotfix)
- [x] Add fail-closed purge guards for live room activity and R2 object changes.
- [x] Add a DB trigger so new room activity invalidates stale approved cleanup
      candidates.
- [x] Add focused source-level regression tests for the cleanup contract.
- [x] Apply/deploy to Supabase project `ilxzpszgirhwxpeocygs` and verify live
      config/state.
- [x] Run `flutter analyze` and `flutter test`; update docs/release status.

## Review (2026-06-07 Cleanup Purge Safety Hotfix)
- Added `cleanup_abandoned_rooms` v2 fail-closed purge checks: live room
  status/activity is checked before listing R2 and immediately before delete;
  R2 object `LastModified` and object-count changes after `last_scanned_at`
  invalidate the approval; candidate snapshot changes also skip purge.
- Added/applied migration `20260607135307_guard_cleanup_purge_activity` so new
  `rooms.last_activity_at` activity resets approved cleanup candidates to
  `pending` before scheduled purge can reuse old review.
- Deployed Edge Function v2 to Supabase project `ilxzpszgirhwxpeocygs` with
  existing `verify_jwt=false` custom bearer-secret auth preserved.
- Live verification: trigger/function exist; anon/authenticated cannot execute
  the reset function; service_role can; cleanup scan/purge cron jobs are active;
  cleanup queue has `pending=88`, `purged=63`, `approved=0`.
- Verification passed: `flutter test test/cleanup_abandoned_rooms_safety_test.dart`,
  `flutter analyze`, and `flutter test` (457 passed / 1 skipped, env-gated feed
  integration test).

## Plan (2026-06-07 Post-Release Change Review)
- [x] Identify the release baseline and complete diff scope.
- [x] Review high-risk app/backend/security/compatibility changes since the
      last repo-known public release.
- [x] Run required release checks: `flutter analyze` and `flutter test`.
- [x] Record findings, residual risks, and release recommendation.

## Review (2026-06-07 Post-Release Change Review)
- Baseline: last repo-known public release is commit `ce4c85e`
  (`2.0.2+4`). Reviewed committed changes through `0fe82c4` plus the current
  uncommitted feed/docs/test changes.
- Release-blocking finding: `cleanup_abandoned_rooms` purge deletes every R2
  object under `rooms/<room_id>/` for `review_status='approved'` without
  rechecking live `rooms.last_activity_at` / status or a candidate snapshot.
  If a room becomes active after approval but before the daily purge, photos can
  still be deleted. Fix before approving more cleanup candidates or treating
  the backend as release-ready.
- Supabase read-only verification: project `ilxzpszgirhwxpeocygs` has
  `cleanup_abandoned_rooms` ACTIVE, scan/purge cron jobs active, canvas
  furniture columns present, and legacy 4-arg plus new 6-arg furniture RPCs
  present. Cleanup queue currently has `pending=88`, `purged=63`,
  `approved=0`.
- Feed hotfix review: `feed_validate` v18 keeps `webhook_skipped: false`, moves
  partner push to `EdgeRuntime.waitUntil`, and recent function logs show
  feed_validate 200s around 1-4s. Persisted failed feed jobs reload as pending
  for silent reconcile/retry.
- Production observation: recent Postgres logs include a few
  `invalid input syntax for type uuid: "temp_..."` errors near feed traffic.
  Review did not localize this to the new queue diff; monitor/follow up, but it
  is not currently a failing test or known user-visible release blocker.
- Verification passed: `flutter analyze`; `flutter test` (453 passed / 1
  skipped, env-gated feed integration test).
- Recommendation: do not approve/submit the release until the cleanup purge race
  is fixed or the purge cron is disabled. After that fix, rerun full checks and
  update `docs/release_status.md`.


## Plan (2026-06-07 Feed Upload Latency)
- [x] Check production edge-function, postgres, and API logs for the latest
      feeding-photo send.
- [x] Identify which feed pipeline step keeps `feedRewardPending` visible.
- [x] Move slow push notification dispatch off the feed response path.
- [x] Deploy `feed_validate` and verify production latency/behavior.
- [x] Run focused tests plus required `flutter analyze` / `flutter test`.
- [x] Document result.

## Review (2026-06-07 Feed Upload Latency)
- Root cause: the Flutter home status stayed on reward pending until
  `feed_validate` returned, and `feed_validate` synchronously awaited the
  nested `notify_friend` Edge Function after rewards/messages were already
  written.
- Production logs matched the user-visible delay: one v16 `feed_validate`
  request took 28.7s and its nested `notify_friend` request took 16.8s; two
  earlier v16 retries also hit `process_feed_event` statement timeouts before
  the final successful attempt.
- Deployed `feed_validate` v17 with `notify_friend` queued through
  `EdgeRuntime.waitUntil`, so reward/hunger responses no longer wait for push
  notification delivery. Added response and notification timing logs.
- Verification passed: `flutter test test/feed_validate_function_test.dart`,
  `flutter analyze`, and `flutter test` (452 passed / 1 skipped, env-gated feed
  integration test). MCP confirmed v17 is ACTIVE with `verify_jwt=true`.
- Follow-up existing-user handling: deployed `feed_validate` v18 to preserve the
  legacy `webhook_skipped: false` response type, and updated the feed upload
  queue so persisted failed jobs from older timeouts reload as pending for
  silent reconcile/retry instead of immediately replaying a stale error.
- Follow-up verification passed:
  `flutter test test/feed_validate_function_test.dart test/features/feed/feed_upload_queue_test.dart`,
  `flutter test` (453 passed / 1 skipped), and `flutter analyze`.

## Review (2026-06-07 Release Status Docs)
- Added `docs/release_status.md` as the release/build/backend deployment ledger.
- Documented that git commit messages are evidence only; live iOS state must be
  verified through App Store Connect/storefront, and shipped releases should get
  explicit git tags.
- Linked the ledger from `README.md`, `AGENTS.md`,
  `docs/ai_collaboration_workflow.md`, and `memory-bank/progress.md`.

## Plan (2026-06-07 Feed Reward Hunger Regression)
- [x] Build a focused repro/feedback loop for feed image completion and hunger.
- [x] Trace Flutter feed upload completion, room refresh, pet-state refresh, and
      backend RPC/tick behavior.
- [x] Add or update a regression test at the narrowest reliable seam.
- [x] Apply the smallest fix, then run focused verification.
- [x] Run `flutter analyze` and `flutter test`.
- [x] Document result and any current behavior changes.

## Review (2026-06-07 Feed Reward Hunger Regression)
- Root cause: successful feed actions added hunger after a pre-action tick, but
  left `last_decay_at` anchored before the feed when the tick had little/no
  whole-point decay. A subsequent client/server tick could then subtract from
  that pre-feed anchor, making the reward appear to disappear.
- Added migration `20260607005751_anchor_decay_after_pet_action.sql` to anchor
  `last_decay_at` at the feed time only when the feed actually increases hunger,
  mirrored to both `pet_state` and `room_pet_state`.
- Added migration `20260607005904_restrict_apply_pet_action_execute.sql` to
  keep `apply_pet_action` Data API execution authenticated-only.
- Applied both migrations to Supabase project `ilxzpszgirhwxpeocygs` and
  verified live function source/grants by MCP SQL.
- Focused verification passed:
  `flutter test test/feed_hunger_action_migration_test.dart`.
- Required verification passed: `flutter analyze`; `flutter test`
  (450 passed / 1 skipped, env-gated feed integration test).

## Plan (2026-06-06 AGENTS.md + Memory-bank Optimization)
- [x] Read AGENTS.md, active memory-bank files, task notes, local skills,
      referenced docs, scripts, Edge Functions, and relevant migrations.
- [x] Measure active memory-bank line counts before editing.
- [x] Archive current memory/task snapshots before compaction.
- [x] Add only repo-grounded workflow updates to AGENTS.md.
- [x] Compact active memory-bank and task notes into current-state summaries.
- [x] Run line-count/diff checks plus `flutter analyze` and `flutter test`.

## Review (2026-06-06 AGENTS.md + Memory-bank Optimization)
- Updated `AGENTS.md` with ASC IPA upload / build-processing commands from the
  repo release workflow, and replaced the stale room-furniture canvas TODO with
  the verified 4-arg/6-arg RPC compatibility rule.
- Archived active memory snapshots to:
  `memory-bank/archive/architecture_20260606_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260606_pre_compaction.md`,
  `memory-bank/archive/progress_20260606_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260606_pre_compaction.md`, and
  `memory-bank/archive/ui_ux_guidelines_20260606_pre_compaction.md`.
- Archived task notes to `tasks/archive/todo_20260606_pre_compaction.md`.
- Active memory-bank line counts before -> after:
  `architecture.md` 130 -> 110, `database-schema.md` 104 -> 98,
  `progress.md` 97 -> 89, `tech-stack.md` 43 -> 41,
  `ui-ux-guidelines.md` 31 -> 31, total 405 -> 369.
- `tasks/todo.md` was compacted from 240 -> 53 lines.
- Verification passed: `wc -l memory-bank/*.md`, `git diff --check`,
  `git diff --stat` inspection, `flutter analyze`, and `flutter test`
  (447 passed / 1 skipped). The feed integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` were
  unset.
- Pre-existing untracked `.claude/` remains untouched.
