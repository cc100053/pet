# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260523_pre_compaction.md`.

## Active Follow-ups
- [ ] App Store Connect version `2.0.1`
  (`ee8f35e8-fda1-4d15-b6cd-440a96409986`) is
  `PREPARE_FOR_SUBMISSION`; attach uploaded valid build `3` and submit when
  ready.
- [ ] Confirm Crashlytics receives dSYMs from the SPM path for build `3`.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
  deployment config; current `verify_jwt` behavior is documented but no
  `supabase/config.toml` exists.

## Plan (2026-05-27 v2.0.2 Bug Fix Release Notes)
- [x] Read release-note workflow, active memory-bank files, current version, and
  existing bundled/ASC release-note assets.
- [ ] Get approval for localized `2.0.2` bug-fix release-note drafts.
- [ ] Bump the app public version to `2.0.2` and choose the next build number.
- [ ] Add bundled What's New copy for `2.0.2`.
- [ ] Update App Store Connect localization files for `2.0.2` while preserving
  required EULA footer descriptions.
- [ ] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.
- [ ] Sync and verify App Store Connect metadata after local validation.

## Plan (2026-05-26 v2.0.1 iOS Archive)
- [x] Read active memory-bank files, task notes, ASC/Xcode build workflow, and
  iOS export workflow.
- [x] Inspect current iOS project settings before archiving; keep existing
  `TARGETED_DEVICE_FAMILY = 1` and avoid iPad setting changes.
- [x] Archive the existing Flutter/Xcode project for iOS App Store release.
- [x] Verify archive/export output and record the result.

## Plan (2026-05-24 v2.0.1 Release Notes)
- [x] Read release-note workflow, active memory-bank files, current version, and
  existing bundled/ASC release-note assets.
- [x] Bump the app public version to `2.0.1` and build number to `3`.
- [x] Add bundled What's New copy for `2.0.1` with short, clear bullets and no
  ad mention.
- [x] Update App Store Connect localization files for `2.0.1` while preserving
  the EULA footer in descriptions.
- [x] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.
- [x] Sync and verify App Store Connect metadata after local validation.

## Plan (2026-05-23 AGENTS.md + Memory-bank Optimization)
- [x] Read AGENTS.md, active memory-bank files, task notes, local skills,
  referenced docs, scripts, Edge Functions, and relevant migrations.
- [x] Archive current active memory/task snapshots before compaction.
- [x] Add only repo-grounded workflow updates to AGENTS.md.
- [x] Compact active memory-bank and task notes into current-state summaries.
- [x] Run line-count/diff checks plus `flutter analyze` and `flutter test`.

## Plan (2026-05-27 Duplicate What's New + chat history OOM)
- [x] Read AGENTS.md + active memory-bank, trace both bug paths.
- [x] Bug 1: guard `ForceUpdateGate` against duplicate What's New on lifecycle
  resume (re-entrancy guard on `_checkForUpdate` + per-session show guard).
- [x] Bug 2: cut chat list `cacheExtent` 2500 -> 600 and global image cache
  128MB/120 -> 64MB/80 to lower history-scroll memory footprint.
- [x] Add `ForceUpdateGate` What's New regression widget test; verify it fails
  without the guards.
- [x] `dart format`, `flutter analyze`, `flutter test`.

## Plan (2026-05-27 Rejoin latest on scroll-down)
- [x] Diagnose why scrolling down from history needed the jump-to-latest button
  (history window trims the live tail; no load-newer/rejoin on scroll).
- [x] Add `shouldRejoinLatestOnScroll` predicate + wire `_handleChatScroll` to
  rejoin the latest window when the user scrolls back to the newest end.
- [x] Add predicate unit tests; `dart format`, `flutter analyze`, `flutter test`.

## Plan (2026-05-27 OOM audit follow-up)
- [x] Audit app for other crash/OOM vectors (images, timers, subscriptions,
  realtime casts, global error handling).
- [x] Bound decode size in `photo_food.dart` (Home food photo) and the
  `feed_capture_view.dart` preview (`Image.memory`) via cacheWidth/cacheHeight.
- [x] `dart format`, `flutter analyze`, `flutter test`.
- Noted (not changed): full-screen photo viewer (`photo_view` gallery) decodes
  full-res across multiple live pages; deferred — touches zoom UX.

## Recent Review Highlights
- v2.0.1 iOS archive (2026-05-26): built
  `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/PetTomo.ipa` using
  the existing Runner scheme/settings with explicit Flutter build name
  `2.0.1` and build number `3`; verified packaged `UIDeviceFamily = [1]`;
  uploaded build `3` to App Store Connect and waited until it became `VALID`.
- v2.0.1 release notes (2026-05-24): bumped `pubspec.yaml` to `2.0.1+3`,
  added concise bundled What's New copy for English, Japanese, Korean,
  Traditional Chinese, and Simplified Chinese, updated ASC release metadata for
  `en-US`, `ja`, `ko`, and `zh-Hant`, created ASC version
  `ee8f35e8-fda1-4d15-b6cd-440a96409986`, uploaded and verified localizations,
  and left the version in `PREPARE_FOR_SUBMISSION` for build attachment.
- App Store EULA metadata rejection (2026-05-22): added direct Apple Standard
  EULA footer to every `.asc/version-localizations/*.strings` description,
  added `test/app_store_metadata_terms_test.dart`, updated release-note
  workflow guardrails, uploaded and verified ASC metadata, and left the
  unresolved App Review issue for App Store Connect resubmission.
- iOS export symbol warning (2026-05-21): added
  `ios/ExportOptions.app-store-nosymbols.plist`,
  `scripts/export_ios_appstore_no_apple_symbols.sh`, and
  `docs/ios_app_store_export.md` so existing archives can be exported/uploaded
  with Apple's immediate symbol upload disabled while retaining dSYMs.
- Calendar day-sheet invisible photos (2026-05-22): fixed
  `CachedNetworkImageView` avatar-framing selection for infinite dimensions and
  added focused predicate tests.
- Recall sent photo (2026-05-21): `delete_message` now soft-deletes sender-owned
  `image_feed` rows, chat shows tombstones, Home removes recalled photos, and
  feed rewards are not reversed.
- Multi-pet/equipment/hunger fixes (2026-05-21): extra-pet equipment RLS/RPCs
  validate `pets` and `room_extra_pets`; main-pet switch suppresses false
  hunger alerts; `apply_pet_action` mirrors room hunger; room gear previews use
  `main_pet_id`; equipment inventory is copy-aware.
- Room hunger freeze (2026-05-21): added admin-only expiring room freeze via
  `room_debug_overrides` and `set_room_hunger_decay_paused(...)`; applied live
  and fixed the output-column upsert ambiguity.

## Review (2026-05-27 Duplicate What's New + chat history OOM)
- Bug 1 (release notes shown twice): `_checkForUpdate` runs on `initState` and
  every `AppLifecycleState.resumed`. `prepareForLaunch` only persists when
  `shouldShow == false`; on a real "show" nothing persists until `markShown`
  (after the user dismisses the toast). A resume during that open window
  (ATT/push prompt or App Store return) re-evaluated `shouldShow == true` and
  stacked a second sheet. Fixed in
  `lib/shared/force_update/force_update_gate.dart` with `_checkInProgress`
  (re-entrancy guard, reset in `finally`) and `_whatsNewShownThisSession`
  (per-session show guard in `_maybeShowWhatsNewDialog`). Debug-forced What's New
  is unaffected.
- Bug 2 (chat history scroll crash): reversed chat list used `cacheExtent: 2500`,
  keeping ~14 full-size image bubbles decoded/live and tripping the iOS memory
  limit. Reduced to `600` in
  `lib/features/chat/widgets/deterministic_chat_list.dart`; lowered global
  `_maxImageCacheBytes`/`_maxImageCacheEntries` 128MB/120 -> 64MB/80 in
  `lib/main.dart`. Message window stays capped at 80.
- Added `test/shared/force_update/force_update_gate_whats_new_test.dart`
  (one-sheet-per-session); confirmed it fails with both guards disabled.
- Verification: `dart format` (no diffs), `flutter analyze` clean,
  `flutter test` 434 passed / 1 skipped (env-gated feed integration test).

## Review (2026-05-23 AGENTS.md + Memory-bank Optimization)
- Updated `AGENTS.md` with two grounded workflow notes: the iOS archive
  export/upload helper from `docs/ios_app_store_export.md`, and the ASC EULA
  footer/test requirement from the release-note workflow.
- Archived active memory snapshots to:
  `memory-bank/archive/architecture_20260523_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260523_pre_compaction.md`,
  `memory-bank/archive/progress_20260523_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260523_pre_compaction.md`, and
  `memory-bank/archive/ui_ux_guidelines_20260523_pre_compaction.md`.
- Archived the long task log to
  `tasks/archive/todo_20260523_pre_compaction.md`, then compacted
  `tasks/todo.md` from 510 lines to 58 lines.
- Active memory-bank line counts before -> after:
  `architecture.md` 95 -> 95, `database-schema.md` 122 -> 89,
  `progress.md` 185 -> 86, `tech-stack.md` 37 -> 38,
  `ui-ux-guidelines.md` 30 -> 31, total 469 -> 339.
- Verification: `wc -l memory-bank/*.md` run, `git diff --check` passed,
  `git diff --stat` inspected, `flutter analyze` passed, and `flutter test`
  passed (432 passed, 1 skipped).
- Skipped test reason: `test/feed_flow_integration_test.dart` requires
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN`.

## Review (2026-05-24 v2.0.1 Release Notes)
- Updated local version from `2.0.0+2` to `2.0.1+3`.
- Added `2.0.1` bundled What's New catalog entry and localized ARB/generated
  l10n strings.
- Updated `.asc/version-localizations/*.strings` `promotionalText` and
  `whatsNew` fields only; EULA-bearing descriptions were preserved.
- Created ASC iOS version `2.0.1`
  (`ee8f35e8-fda1-4d15-b6cd-440a96409986`) from `2.0.0`, uploaded all four ASC
  locales, and verified newline-formatted live `whatsNew` JSON values.
- Verification: `flutter gen-l10n` passed with pre-existing untranslated-key
  warnings for `ko` and `zh_TW`; `flutter analyze` passed; focused App Store
  metadata terms test passed; full `flutter test` passed (433 passed, 1
  skipped).

## Review (2026-05-26 v2.0.1 iOS Archive)
- Preflight confirmed the Runner target keeps `TARGETED_DEVICE_FAMILY = 1`,
  `SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, `SUPPORTS_MACCATALYST = NO`,
  deployment target `15.0`, and team `QRLFBRL2J2`.
- Ran `flutter build ipa --release --build-name=2.0.1 --build-number=3`, which
  archived with existing Xcode project signing/settings.
- Outputs:
  `build/ios/archive/Runner.xcarchive` (323.4 MB) and
  `build/ios/ipa/PetTomo.ipa` (78 MB).
- IPA verification: `CFBundleShortVersionString = 2.0.1`,
  `CFBundleVersion = 3`, `UIDeviceFamily = [1]`,
  `UISupportedInterfaceOrientations = ["UIInterfaceOrientationPortrait"]`, and
  `UIRequiresFullScreen = true`.
- Uploaded `build/ios/ipa/PetTomo.ipa` to App Store Connect; upload/build ID
  `592b786d-b38c-4f2f-ae96-436923a6bbc5` reached `VALID`, expired `false`,
  encryption `exempt`.
