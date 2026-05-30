# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260530_pre_compaction.md`.

## Active Follow-ups
- [ ] Monitor App Store review for `2.0.2`
  (`cb96407b-2767-4889-a3de-212be7b9289c`); latest submission
  `5653be07-b377-43f7-b675-06affede8ed0` is `WAITING_FOR_REVIEW`.
- [ ] Confirm Crashlytics receives dSYMs from the SPM path for build `3`.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
  deployment config; current `verify_jwt` behavior is documented but no
  `supabase/config.toml` exists.

## Plan (2026-05-30 AGENTS.md + Memory-bank Optimization)
- [x] Read AGENTS.md, active memory-bank files, task notes, local skills,
  referenced docs, scripts, Edge Functions, and relevant migrations.
- [x] Measure active memory-bank line counts before editing.
- [x] Archive current memory/task snapshots before compaction.
- [x] Add only repo-grounded workflow updates to AGENTS.md.
- [x] Compact active memory-bank and task notes into current-state summaries.
- [x] Run line-count/diff checks plus `flutter analyze` and `flutter test`.

## Plan (2026-05-30 Fixed Virtual Room Canvas)
- [x] DB migration is confirmed live on target Supabase project
  `ilxzpszgirhwxpeocygs`.
- [x] Legacy furniture RPC compatibility restored by live migration
  `20260530125134_fix_room_furniture_canvas_rpc_overloads`.
- [x] Verification checks completed for the furniture RPC hotfix.

## Plan (2026-05-30 Furniture RPC Backward Compatibility)
- [x] Verify target Supabase project and current furniture RPC signatures.
- [x] Add a migration that keeps legacy 4-arg furniture RPC calls unambiguous
  while preserving the new 6-arg canvas-coordinate calls.
- [x] Apply the migration to the target project through Supabase MCP.
- [x] Run focused verification SQL plus Flutter analyzer/tests.
- [x] Document the outcome and any remaining rollout risk.

## Plan (2026-05-30 FVM Flutter Run SPM Fix)
- [x] Compare Flutter-generated iOS SwiftPM package paths with the tracked
  package mirror used by Xcode.
- [x] Update the tracked mirror so package paths match FVM/Flutter 3.44.0
  generated `ios/Flutter/ephemeral/Packages/.packages/*-version` folders.
- [x] Verify Swift Package dependency resolution and run required Flutter
  checks where the sandbox allows it.

## Recent Review Highlights
- Furniture RPC compatibility hotfix (2026-05-30): live project
  `ilxzpszgirhwxpeocygs` had both 4-arg and 6-arg
  `place_room_furniture` / `update_room_furniture_transform` overloads, but the
  6-arg overloads had `DEFAULT NULL` canvas params. That made old 4-param
  PostgREST calls ambiguous and broke legacy furniture movement. Added/applied
  `20260530125134_fix_room_furniture_canvas_rpc_overloads`, recreating the
  6-arg overloads without defaults, keeping the legacy 4-arg functions, and
  aligning 6-arg placement with room-scoped inventory/version-gated furniture
  predicates. Live verification shows all four overloads now have
  `pronargdefaults = 0`; `notify pgrst, 'reload schema'` sent; `git diff
  --check`, `fvm flutter analyze`, and `fvm flutter test` passed (446 passed, 1
  skipped).
- FVM Flutter run SPM fix (2026-05-30): root cause was the tracked
  `ios/Flutter/GeneratedPluginSwiftPackage/Package.swift` mirror still pointing
  at unversioned Flutter ephemeral plugin package paths, while Flutter 3.44.0
  generates version-suffixed folders such as `url_launcher_ios-6.3.6`. Updated
  the mirror paths, added the generated `FlutterFramework` package dependency,
  fixed the Flutter 3.44.0 `cacheExtent` deprecation, verified Xcode package
  resolution, `flutter analyze`, `flutter test`, and `flutter run` on the
  `iPhone 17 Pro Max` simulator.
- v2.0.2 release/archive (2026-05-27): bumped local version to `2.0.2+4`,
  updated bundled What's New and ASC release metadata while preserving EULA
  descriptions, built/uploaded iOS build `4`, attached it to ASC version
  `2.0.2`, validated, and submitted for review.
- Chat/What's New/OOM follow-up (2026-05-27): guarded duplicate What's New
  sheets, reduced chat/global image cache pressure, bounded Home/feed preview
  image decodes, and made history scroll rejoin latest locally before refresh.
- Furniture canvas implementation (2026-05-30): added fixed-aspect room canvas
  math and dual-write client support for `canvas_position_x/y`; full tests
  passed with `fvm flutter test` before this docs compaction, but live DB
  migration remains the blocker.

## Review (2026-05-30 AGENTS.md + Memory-bank Optimization)
- Updated `AGENTS.md` with the repo `.fvmrc` Flutter pin and the current
  room-furniture canvas-coordinate migration guardrail.
- Archived active memory snapshots to:
  `memory-bank/archive/architecture_20260530_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260530_pre_compaction.md`,
  `memory-bank/archive/progress_20260530_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260530_pre_compaction.md`, and
  `memory-bank/archive/ui_ux_guidelines_20260530_pre_compaction.md`.
- Archived task notes to `tasks/archive/todo_20260530_pre_compaction.md`.
- Active memory-bank line counts before -> after:
  `architecture.md` 95 -> 99, `database-schema.md` 89 -> 93,
  `progress.md` 115 -> 73, `tech-stack.md` 38 -> 40,
  `ui-ux-guidelines.md` 31 -> 31, total 368 -> 336.
- `tasks/todo.md` was compacted from 322 -> 50 lines.
- Verification: `wc -l memory-bank/*.md` run, `git diff --check` passed, and
  `git diff --stat` inspected.
- `flutter analyze` and `flutter test` with the default Flutter failed before
  verification because system Dart is `3.10.7` while `pubspec.yaml` requires
  `^3.11.0-235.0.dev`.
- A writable Flutter `3.44.0` copy was used from `/private/tmp/flutter_3.44.0`.
  Analyze then failed on an existing SDK deprecation info:
  `lib/features/chat/widgets/deterministic_chat_list.dart:158:11`
  (`cacheExtent` -> `scrollCacheExtent`). This appears unrelated to the
  documentation-only changes.
- `flutter test` with the writable SDK could not run in this sandbox because
  Flutter test workers cannot bind `127.0.0.1:0` (`Operation not permitted`);
  no test bodies reached the env-gated feed integration skip.
