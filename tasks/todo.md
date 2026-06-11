# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260606_pre_compaction.md`.

## Active Follow-ups
- [~] Monitor App Store review for iOS `2.2.0+6`.
      ASC version `ca6b8b89-a99e-4cc7-a23c-886853467b58`, build
      `ef250ff1-c94e-45db-9043-dd9f7942ca1b`, submission
      `8e1526cd-e1a7-4681-bbba-8490a33d4b53`; state is
      `WAITING_FOR_REVIEW`.
- [ ] Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
      8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
      deployment config; current `verify_jwt` behavior is documented but no
      `supabase/config.toml` exists.

## Plan (2026-06-11 v2.2.0 Release Notes Sync)
- [x] Draft localized bundled What's New and ASC release notes for `2.2.0`.
- [x] Update local app version, bundled What's New catalog, ARB localization
      keys, and ASC `.strings` assets.
- [x] Run `flutter gen-l10n`, `test/app_store_metadata_terms_test.dart`,
      `flutter analyze`, and `flutter test`.
- [x] Create or locate the App Store Connect `2.2.0` version and upload
      localized `.strings` metadata.
- [x] Verify ASC localizations and update `docs/release_status.md` /
      `memory-bank/progress.md`.

## Review (2026-06-11 v2.2.0 Release Notes Sync)
- Bumped the local candidate to `2.2.0+6` and added bundled What's New copy for
  en, ja, ko, zh-Hant, and zh-Hans.
- Created ASC version `2.2.0`
  (`ca6b8b89-a99e-4cc7-a23c-886853467b58`) by copying metadata from `2.1.0`.
- Uploaded v2.2.0 `promotionalText` / `whatsNew` for en-US, ja, ko, and
  zh-Hant; descriptions and direct Apple Standard EULA footers were preserved.
- Verification passed: `flutter gen-l10n`,
  `flutter test test/app_store_metadata_terms_test.dart`, `flutter analyze`,
  and `flutter test` (481 passed / 1 skipped).
- Next release step: build and upload `2.2.0+6`, wait for processing, attach
  the build to the ASC version, then run submission preflight.

## Plan (2026-06-11 v2.2.0 Build Upload And Submission)
- [x] Preflight iOS target settings and preserve iPhone-only release settings.
- [x] Build App Store IPA with explicit `--build-name=2.2.0 --build-number=6`.
- [x] Verify packaged IPA `Info.plist` version, build, device family,
      supported orientations, and full-screen setting.
- [x] Upload IPA to App Store Connect and wait for build processing.
- [x] Attach build to ASC version `2.2.0`.
- [x] Run ASC validation, review doctor/status, and dry-run submission.
- [x] Submit v2.2.0 for App Review and verify `WAITING_FOR_REVIEW`.
- [x] Update release-status and memory docs.

## Review (2026-06-11 v2.2.0 Build Upload And Submission)
- Built `build/ios/ipa/PetTomo.ipa` from Flutter with `2.2.0+6`; Flutter
  archive validation confirmed bundle `com.cc100053.pet`, display name
  `PetTomo`, deployment target `15.0`.
- Packaged IPA verification: `CFBundleShortVersionString=2.2.0`,
  `CFBundleVersion=6`, `UIDeviceFamily=[1]`,
  `UISupportedInterfaceOrientations=[UIInterfaceOrientationPortrait]`, and
  `UIRequiresFullScreen=true`.
- Uploaded and processed ASC build
  `ef250ff1-c94e-45db-9043-dd9f7942ca1b`; state `VALID`,
  `usesNonExemptEncryption=false`, uploaded `2026-06-10T08:15:08-07:00`.
- Attached the build to ASC version
  `ca6b8b89-a99e-4cc7-a23c-886853467b58`.
- ASC validation: 0 errors, 0 blocking issues; non-blocking warning remains
  for missing subscription promotional image, and App Privacy publish state is
  not publicly verifiable through the API.
- Submitted to App Review. Submission
  `8e1526cd-e1a7-4681-bbba-8490a33d4b53` is `WAITING_FOR_REVIEW`.

## Plan (2026-06-10 Edge Function Hardening — Phase 0/1)
Server-side interaction/data-flow refactor. Phase 0 = shared infra; Phase 1 =
R2 orphan cleanup + avatar replacement cleanup + timing-safe secret compare.
All changes are backward-compatible (no request/response contract change).
- [x] Add `supabase/functions/_shared/{http,images,auth}.ts` and route
      `feed_validate` + `avatar_upload` through the shared image/R2 helpers.
- [x] `feed_validate`: track the uploaded R2 key and `deleteFromR2` it when
      `process_feed_event` fails (rolled-back txn → no message references it).
- [x] `avatar_upload`: delete the previous avatar after a successful profile
      update, and delete the new object if the profile update fails.
- [x] Use constant-time `timingSafeEqual` for the `notify_friend` webhook secret
      and `hunger_tick_dispatch` scheduler secret.
- [x] Add `test/edge_function_storage_safety_test.dart`; preserve existing
      `feed_validate_function_test.dart` introspection strings.
- [x] `flutter analyze` clean; `flutter test` green (463 passed, 1 skipped).
- [x] Deploy the four functions to `ilxzpszgirhwxpeocygs` (verified ref).
      feed_validate v19, avatar_upload v6, hunger_tick_dispatch v7 via MCP;
      notify_friend v30 via Supabase CLI `--no-verify-jwt`. `verify_jwt`
      preserved per function; edge logs all-200, no boot/import errors;
      `release_status.md` updated.
- [ ] Follow-up (Phase 1 remainder): per-user avatar upload rate limit needs a
      `profiles.avatar_updated_at` (or throttle table) migration — deferred;
      delete-on-replace already removes the storage-accumulation incentive.

## Plan (2026-06-10 Phase 3 — presigned direct-to-R2 feed upload)
Additive + opt-in (server-controlled flag, default OFF, base64 fallback).
Production behavior unchanged until the flag is flipped.
- [x] `_shared/images.ts`: add `presignR2PutUrl` (host-only SigV4 query sign).
- [x] New `feed_upload_url` edge function (v1, verify_jwt=true): membership-
      checked, room-scoped key, returns presigned PUT URL + public_url.
- [x] `feed_validate` v20: reject a client `image_url` not under the room's R2
      prefix (base64 path untouched → zero impact on current traffic).
- [x] Client: `AppConfigService.fetchBoolFlag`; `feed_upload_client` presigned
      path behind `feed_presigned_upload_enabled` with base64 fallback;
      cross-platform PUT via conditional import (`feed_r2_put_io/_stub`).
- [x] Seed `app_config.feed_presigned_upload_enabled = false`.
- [x] Add `test/features/feed/feed_presigned_upload_test.dart`; analyze clean;
      `flutter test` 481 passed/1 skipped.
- [x] Deploy `feed_upload_url` (CLI) + `feed_validate` v20 (MCP); smoke-verified
      boot/imports; both verify_jwt=true.
- [ ] ROLLOUT GATE: keep the flag false until a client build with the presigned
      path is released and tested end-to-end (get URL -> PUT R2 -> feed_validate
      with image_url). Then flip `feed_presigned_upload_enabled` to true and
      watch feed_validate/feed_upload_url logs.

## Plan (2026-06-10 Phase 2 — notify_friend decomposition)
Behavior-preserving refactor of the live push function. No contract change;
`verify_jwt=false` preserved.
- [x] Verified the "tiger avatar bug" is actually a deliberate fallback:
      `tiger_stay.gif` is a real R2 404, so `tiger -> ghost_stay.gif` stays
      (documented in `pets.ts`). NOT changed (would 404 for tiger pets).
- [x] Extract `notify_friend/l10n.ts` (push locale templates + store-item names)
      and `notify_friend/pets.ts` (avatar maps + type resolution); route
      CORS/JSON through `_shared/http.ts`. index.ts 1310 -> 1063 lines.
- [x] Deploy via CLI `--no-verify-jwt`; confirmed live v31, `verify_jwt=false`,
      byte-exact CJK, smoke 401/400 (boots/imports OK), `deno check` clean.
- [x] Add `test/notify_friend_module_split_test.dart`; `flutter analyze` clean;
      `flutter test` green (472 passed/1 skipped).
- [ ] Optional follow-up: FCM auth (`getAccessToken`/`importPrivateKey`) could
      move to `notify_friend/fcm.ts` too — left in index.ts to avoid touching the
      crypto/send path in this pass. l10n single-source-of-truth with `lib/l10n`
      (build-step generation) intentionally deferred — push strings are distinct.

## Plan (2026-06-10 Phase 4b — home query RPCs)
Additive, backward-compatible DB change. New clients only; old clients keep
their direct queries.
- [x] Add migration `20260610120000_add_room_home_summary_rpcs.sql` with
      `get_room_latest_feeds` (per-room top-N, fixes global-LIMIT starvation) and
      `get_room_member_counts` (aggregate), both `SECURITY INVOKER`, granted to
      `authenticated`. Applied via MCP and smoke-tested on live data.
- [x] Rewire `_fetchRoomLatestFeeds` / `_fetchRoomMemberCounts` internals to call
      the RPCs (method names + call sites unchanged, so the loading-performance
      introspection test still holds). `_fetchRoomPetSummaries` left as-is.
- [x] Client cleanups: chat `message_reactions` uses `.inFilter`; dropped the
      dead `canonical_tags: []` field from the feed_validate request body.
- [x] Add `test/room_home_summary_rpc_test.dart`; advisors show 0 new lints;
      `flutter analyze` clean; `flutter test` green (468 passed/1 skipped).
- [ ] Follow-up (Phase 4 remainder): consider folding member-count + latest-feed
      RPCs into the cold-start path metrics; optional further consolidation of
      pet summaries was intentionally skipped (no defect, reused elsewhere).

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
