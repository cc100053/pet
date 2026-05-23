# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260523_pre_compaction.md`.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
  deployment config; current `verify_jwt` behavior is documented but no
  `supabase/config.toml` exists.
- [ ] App Store Connect version `2.0.0`
  (`1fc934d6-90c8-4b94-802c-e35d0c5e0230`) remains `REJECTED` with
  `UNRESOLVED_ISSUES` after the EULA metadata fix; resolve/resubmit the App
  Review issue in App Store Connect.

## Plan (2026-05-23 AGENTS.md + Memory-bank Optimization)
- [x] Read AGENTS.md, active memory-bank files, task notes, local skills,
  referenced docs, scripts, Edge Functions, and relevant migrations.
- [x] Archive current active memory/task snapshots before compaction.
- [x] Add only repo-grounded workflow updates to AGENTS.md.
- [x] Compact active memory-bank and task notes into current-state summaries.
- [x] Run line-count/diff checks plus `flutter analyze` and `flutter test`.

## Recent Review Highlights
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
