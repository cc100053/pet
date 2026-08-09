# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260804_pre_compaction.md`.

## Plan (2026-08-08 Remaining pg_timezone_names Probes)
- [x] Rewrite the six remaining probing functions behind a shared
      `public.normalize_timezone(text)` and deploy them.
- [x] Snapshot the old definitions first, then diff post-apply to prove only
      the probe changed, and verify grants/volatility/signatures survived.
- [x] Time each deployed function against real rows in aborted transactions.

## Plan (2026-08-08 Pet Refresh Timeout And Unclean Exit Triage)
- [x] Trace the `userFacingError` / `_refreshPetState` non-fatal to the RPC that
      actually timed out.
- [x] Stop a failed refresh from replacing pet state the user can already see.
- [x] Remove the `pg_timezone_names` probe from `tick_pet_state` and deploy it.
- [x] Assess the `UncleanExitService` non-fatal (working as designed; no code
      change).

## Plan (2026-08-08 Image Picker Non-Fatal Triage)
- [x] Trace the `ImagePickerApi.pickImage` non-fatal to the pigeon throw site
      and enumerate the native codes it can carry.
- [x] Classify media-permission codes into their own user-facing category with
      localized copy, and stop `multiple_request` from surfacing as an error.
- [x] Serialize picker requests and drop the unneeded full-metadata request so
      gallery picks no longer need photo-library permission.
- [x] Cover the new behavior with tests; run `dart format`, `flutter analyze`,
      and `flutter test`.
- [x] Register the Firebase MCP wrapper with Claude Code and confirm the actual
      Crashlytics code for issue `52a65b49f33a2938c9b1a123895d063e`.

## Plan (2026-08-04 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, repo-local workflows, and
      every outstanding worktree change without discarding shared-session work.
- [x] Archive full active-memory snapshots, compact current-state notes, and
      add only verified, non-duplicative agent workflow guidance.
- [x] Run diff, analyzer, and test verification; document results and line-count
      changes before committing logical groups.

## Plan (2026-08-10 OOM Non-Fatal Remediation)
- [x] Re-triage `5fd6c8464435fdf77b3ad723f3085fff`; confirm 2.3.4+17 does not
      address it (it carries the DB perf and image-picker fixes only).
- [x] Make image-cache trim thresholds track the configured caps instead of
      absolute bytes, which the 64 MB cap had made unreachable.
- [x] Weigh `liveImageCount` in the trim decision; live images are pinned
      outside the byte budget.
- [x] Release memory on an iOS memory warning instead of only logging; Flutter
      clears the cache but never the live set.
- [x] Record `last_resumed_at` and flush the sentinel on lifecycle change so
      foreground/background classification is auditable.
- [x] `dart format`, `flutter analyze` (clean), `flutter test` (612 pass).
- [ ] Decide the release vehicle: 2.3.4 build 17 is already uploaded and
      attached at ASC, so shipping this needs a new build.

## Active Follow-ups
- [ ] Monitor ASC/store outcome for iOS `2.3.4+17`; submit for App Review only
      after an explicit request. Working tree changes for this release are not
      yet committed to git.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [x] Confirm Crashlytics receives Firebase Apple SPM dSYMs and real
      `unclean_exit` events. Confirmed 2026-08-08: issue
      `5fd6c8464435fdf77b3ad723f3085fff` is a genuine foreground OOM on
      2.3.3+16 with `memoryWarnings=2`.
- [ ] Reduce simultaneously-live chat images: `liveImageCount` reached 96
      against the 80-entry `ImageCache` cap, and live images cannot be evicted.
      Partly mitigated 2026-08-10 (pressure now clears the live set and trim
      weighs live images), but the root cause stands: ~3.5 MB decoded per chat
      bubble at DPR 3, and the live set spans rooms across a room switch.
- [x] Remove the `pg_timezone_names` probe from the six remaining functions.
      Done 2026-08-08 via `20260808150000`; 0 functions in `public` still probe.
- [x] Drop the rollback snapshot. Done 2026-08-08 on request.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Recent Context
- Release/build/backend truth: `docs/release_status.md`.
- iOS `2.3.4+17` release-notes sync completed: ASC version
  `9f8120ca-91be-4875-aa4e-eb8e3106cae9` is `PREPARE_FOR_SUBMISSION`;
  build `42b5c164-d1e4-45f3-b485-a26116d70d76` is `VALID`, attached, and
  intentionally not submitted for App Review. Release note covers the
  `tick_pet_state`/sibling-function database performance fix (`07c831c`,
  `0aef9b2`) and the photo-permission-refusal error-handling fix (`de0454e`).
  Localized ASC metadata was verified for en-US, ja, ko, and zh-Hant with EULA
  footers preserved. `flutter gen-l10n`, analyzer, and full test checks
  (608 passed/1 skipped) all passed. Working tree changes are not yet
  committed to git.
- Full prior task state: `tasks/archive/todo_20260804_pre_compaction.md`.

## Review (2026-08-08 Remaining pg_timezone_names Probes)
- All six rewritten and applied as `20260808150000`. `public` now has **0**
  functions with an executable `pg_timezone_names` reference.
- `get_effective_room_pet_statuses` was the worst of the group and the reason
  the room picker was slow: being `LANGUAGE sql`, its probe sat in a lateral
  join and ran once per requested room. It also cannot carry an inline
  exception handler, which is why the fallback became a shared
  `public.normalize_timezone(text)` rather than six inlined blocks.
- Measured on the deployed functions, all inside aborted transactions:
  `get_effective_room_pet_statuses` ~7 ms over 5 rooms (was 1,652 ms mean),
  `apply_pet_action` ~4–5 ms (was 588 ms), `apply_room_pet_action` ~14 ms,
  `create_room` ~96 ms (was 967 ms), `compute_pet_hunger_next_check_at`
  ~0.6 ms. `create_room` persisted the caller's real `Asia/Taipei` profile zone,
  which is the check that matters for the two functions that *store* the
  normalized value rather than just reading it.
- Snapshot-then-diff showed zero unrelated changes across all six, and
  signature/`prosecdef`/volatility/grants byte-identical. `create or replace`
  (never drop/create) is what preserves the tightened `apply_pet_action` ACL.
- Rollback snapshot `tz_probe_rollback.snapshot_20260808` was dropped on
  request once verification was complete. The revert source is now git alone:
  the pre-change definitions live in the migrations this one supersedes.
- `flutter analyze` clean; `flutter test` 608 passed/1 skipped.

## Review (2026-08-08 Pet Refresh Timeout And Unclean Exit Triage)
- Issue `0183b64515477452f62329d7d3a83a4f` (`PostgrestException 57014` at
  `home_view.dart:2154`) had two independent defects. Server: `tick_pet_state`
  probed `pg_timezone_names` once per call at ~792 ms, blowing the
  `authenticated` role's 8 s `statement_timeout` — 71,502 calls, 757 ms mean,
  54,165 s cumulative, the largest single consumer of DB time on the project.
  App: the `catch` replaced a perfectly good on-screen pet with an error banner
  on any transient refresh failure.
- Both are fixed. Migration `20260808130000` is applied to production (live
  `20260808131528`); see `docs/release_status.md` for the contract inventory,
  the before/after measurements, and the live-traffic verification still owed.
- Six sibling functions carry the identical `pg_timezone_names` probe and are
  the next-largest slow queries. Deliberately out of scope for this pass since
  they are not in the reported traces; each needs its own timezone-usage check.
- Issue `5fd6c8464435fdf77b3ad723f3085fff` (`UncleanExitException`) is **not a
  bug**. It is `UncleanExitService` doing exactly its job: `previous_exit:
  foregroundUnclean`, `memoryWarnings=2`, route `MaterialPageRoute<dynamic>`,
  `diag_snapshot_route: chat_room_view_v2`, `diag_image_cache_live: 96` against
  an 80-entry cap, `diag_image_cache_bytes: 53 MB` against a 64 MB cap. It is
  the confirmation the memory-bank open item asked for. Left OPEN and
  unmodified: silencing it would delete the only OOM signal the app has.
- Live images cannot be evicted by `ImageCache`, so `liveImageCount` 96 > the
  80-entry `maximumSize` is the real memory driver. Reducing simultaneously
  mounted chat images is the follow-up, not a reporter change.
- `flutter analyze` clean; `flutter test` 601 passed/1 skipped.

## Review (2026-08-08 Image Picker Non-Fatal Triage)
- The Crashlytics frame `messages.g.dart:268` is the pigeon
  `throw PlatformException(...)` branch, so the non-fatal was always a native
  `image_picker` refusal, never a Dart bug at
  `feed_capture_view.dart:115`. The exact code is only in the report's
  reason/log lines, so the fix covers every code that site can raise.
- `userFacingError(...)` gained a `mediaPermissionDenied` category keyed off
  the `PlatformException.code` (locale-independent, unlike the message), with
  `errorMediaPermissionDenied` copy in en/ja/ko/zh/zh_TW. These stop landing in
  the `unexpected` bucket, which is what the open triage item asked for.
- `_errorSummary` now renders `PlatformException` as `code | message | details`
  instead of `toString()`, whose trailing native stack differs per occurrence
  and defeated both dedup and Crashlytics grouping.
- `FeedCaptureView` serializes picks behind `_picking` (the plugin fails the
  *first* request with `multiple_request` when a second arrives), treats
  `multiple_request` as a silent no-op, and passes `requestFullMetadata: false`
  so iOS stays on the permission-free PHPicker path.
- The same unguarded `pickImage` call existed in `profile_view._pickAvatar` and
  `home_onboarding_flow._uploadOnboardingProfileAvatar`, where a refusal became
  an unhandled async error; both now handle it the same way.
- `dart format`, `flutter analyze` (no issues), and `flutter test` (593 passed,
  1 skipped Supabase integration test) all pass. `flutter gen-l10n` still
  reports only the three pre-existing untranslated messages in ko and zh_TW.
- Crashlytics confirmed the code afterwards: issue
  `52a65b49f33a2938c9b1a123895d063e` is
  `PlatformException(multiple_request, Cancelled by a second request)`, thrown
  from `ui_error:feed_pick_image`. One event, one user, 2.3.3+16, iPhone 15 Pro
  on iOS 26.5.2, 2026-08-08T07:21:31Z; the event log shows `route_push
  MaterialPageRoute` five seconds earlier, i.e. a second tap on the capture
  sheet. It is the only `image_picker` issue in the last 90 days, and no
  camera/photo access-denied events exist, so the `_picking` guard addresses
  the observed cause and the permission classification is pre-emptive.
- Diagnosis recorded as a Crashlytics note on that issue. The fix ships after
  2.3.3+16, so the issue should be left OPEN until a build carrying `de0454e`
  has soaked.
- Firebase MCP now works from Claude Code too: registered the existing
  `scripts/start_firebase_mcp_crashlytics.sh` wrapper via `claude mcp add`
  (local scope, `~/.claude.json`) and documented it as step 4 in
  `docs/firebase_crashlytics_mcp_workflow.md`. ADC and the service-account key
  were already in place; nothing new was stored in the repo.

## Review (2026-08-04 Agent Docs And Memory Optimization)
- Added repo-grounded handled-error and OOM/process-kill guidance to
  `AGENTS.md`; no runtime code or generated file was changed by this pass.
- Active memory fell from 318 to 242 lines: architecture 111→70, database
  schema 87→66, progress 53→39, tech stack 38→38, UI/UX 29→29.
- Preserved full snapshots in
  `memory-bank/archive/{architecture,database_schema,progress}_20260804_pre_compaction.md`
  and the prior task log in
  `tasks/archive/todo_20260804_pre_compaction.md`.
- Reviewed all outstanding files. The pre-existing 2.3.2 release/localization
  set is coherent and will be committed separately from this documentation set.
- `git diff --check`, `flutter gen-l10n`, and `flutter analyze` passed.
  `flutter gen-l10n` reported three pre-existing untranslated messages in each
  of ko and zh_TW; generated sources stayed consistent.
- `flutter test` passed 579 tests; the feed integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` are unset.
