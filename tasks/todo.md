# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260530_pre_compaction.md`.

## Plan (2026-06-04 2.1.0 Release Notes Sync)
- [x] Read active memory-bank files and the `release-notes-sync`,
      `asc-metadata-sync`, and `asc-cli-usage` skills.
- [x] Draft localized bundled What's New, ASC `whatsNew`, and
      `promotionalText` copy for review.
- [x] Bump local public version to `2.1.0+5`.
- [x] Update bundled What's New catalog and all maintained ARB locales.
- [x] Update ASC version-localization `.strings` assets while preserving EULA
      descriptions.
- [x] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.
- [x] Create/find ASC version `2.1.0`, upload localizations, and verify.

## Review (2026-06-04 2.1.0 Release Notes Sync)
- Local app version bumped to `2.1.0+5`; bundled What's New and generated l10n
  now include localized `whatsNew210*` entries for en, ja, ko, zh-Hant, and zh.
- Local ASC `.strings` files now contain reviewed 2.1.0 `promotionalText` and
  `whatsNew` copy while preserving existing EULA descriptions and URLs.
- Verification passed: ARB JSON parse, `flutter gen-l10n`,
  `flutter test test/app_store_metadata_terms_test.dart`, `flutter analyze`,
  `flutter test` (447 passed / 1 skipped), and `git diff --check`.
- ASC version `2.1.0`
  (`37897d26-cc47-492c-867f-c7bc3ee4d44b`) is now
  `PREPARE_FOR_SUBMISSION`. `asc versions create` and
  `asc localizations upload` returned Apple error `-50`, so the version and
  localization rows were created/updated through Apple’s REST API using the same
  App Store Connect key. Live verification confirmed all four locales have
  2.1.0 `promotionalText`, 2.1.0 `whatsNew`, and the EULA URL.

## Plan (2026-06-03 Room inventory UX)
B2 (bottom dock + collapse feed + expand room) was built then **reverted** per
user: changing the room canvas size between edit/real view broke position
prediction. Requirement: the pet activity area must be byte-identical in edit
and real view; inventory stays a TOP overlay at its original size; no
auto-collapse on move. Revert restored original behavior (room untouched).
- [x] Reverted all B2 changes (git checkout); back to original main behavior.
- [x] Option B: `HomeFurnitureInventoryOverlay` now caps the panel to
      `screenHeight*0.6` (bounded by available height) and wraps it in a
      `SingleChildScrollView`. Room layout + item sizes untouched; on normal
      phones it shows in full, on short windows it scrolls and never reaches the
      room floor. `flutter analyze` clean; `flutter test` 447 pass / 1 skip.
- [x] Scroll hint: overlay is now stateful with a `ScrollController` +
      `Scrollbar` whose thumb is always visible *only when scrollable*
      (detected via `ScrollMetricsNotification.maxScrollExtent > 0`), so short
      windows get a visible bar and normal screens stay clean.

## Plan (2026-06-02 God-file decomposition + consistency sweep)
Scope: god files + full-codebase consistency. Nature: STRICTLY
behavior-preserving (structural only). Mechanism: existing `part`/`part of`
extension idiom (same library => no privacy/import/API change). Verify
`flutter analyze` + `flutter test` after EVERY extraction.

Targets (by pain):
- [x] `home_view.dart` 5737 -> 3282; extracted `_HomeViewState` domains:
  - [x] room-decor (furniture + backgrounds) -> `home_view_room_decor.dart` (1268 lines)
  - [x] equipment domain -> `home_view_equipment.dart` (467 lines)
  - [x] pet-tick/hunger domain -> `home_view_pet_tick.dart` (158 lines)
  - [x] debug tools (interleaved, multi-range cut) -> `home_view_debug.dart` (577 lines)
- [~] `chat_room_view_v2.dart` 3657 -> 2538:
  - [x] scroll/viewport -> `chat_room_view_v2_scroll.dart` (327 lines)
  - [x] message-actions/moderation -> `chat_room_view_v2_actions.dart` (798 lines)
- [x] `shop_view.dart` 2340 -> 1316: inline widgets/painters
      -> `widgets/shop_view_decorations.dart` (1024 lines)
- [~] Consistency sweep (behavior-preserving):
  - [x] dedup byte-identical helpers -> shared utils (locals delegate):
        `removeRealtimeChannelSafely` (home+chat; shop intentionally LEFT — it
        lacks the unsubscribe fallback => different behavior);
        `parseOptionalDate` (home+chat_message+blocked_users);
        `parseDate` (chat_message+memory_feed);
        `globalRectForKey` (chat scroll + keyboard shell x2).
        SKIPPED `_ensureCurrentAppVersion` (identical but state-entangled —
        _currentAppVersion/mounted/setState; clean extraction = over-engineering).
  - NOTE: most same-named helpers are NOT true dupes (e.g. `_withNetworkTimeout`
    diverges: home = bare timeout, profile = tagged-exception wrapper). Do not
    force-merge divergent helpers under behavior-preservation.
- [x] Break up giant `build()` methods (extract verbatim sub-trees to helpers):
  - [x] chat `build()` 442 -> 167 (`chat_room_view_v2_build.dart`: appBar +
        fc.Builders)
  - [x] home `build()` 249 -> 161 (`home_view_build.dart`: room-selection
        scaffold + status bar)
  - [x] shop `ShopFloatingNoticeCard.build()` 239 -> 182 (`_buildNoticeIcon`/
        `_buildNoticeBadge`). NOTE: `_ShopViewState.build()` was already 62 lines.

## Review (2026-06-02 God-file decomposition — session 1)
- 6 behavior-preserving `part`-file extractions across the 3 god files; every
  step verified green with `flutter analyze` (No issues) + `flutter test`
  (447 pass / 1 skip). Net: home_view -1885, chat -1119, shop -1024 lines moved
  out of the core files into cohesive part files. No public API / runtime change.
- Added State `setState` wrappers for extension parts: `_setStateForRoomDecor`,
  `_setStateForEquipment` (home), `_setStateChat` (chat).
- Updated source-introspection test `home_multi_pet_query_test.dart` to read the
  new equipment part (asserting symbol LOCATION, not behavior).
- Pitfalls captured in `tasks/lessons.md` (extension setState, static
  qualification, subdir `part of '../x.dart'`, source-scan tests).
- Remaining: home_view debug domain (interleaved — needs per-method moves, not a
  block cut), then the codebase-wide consistency sweep.

## Active Follow-ups
- [~] Build/upload/attach the `2.1.0+5` iOS release build.
      Built `build/ios/ipa/PetTomo.ipa`, verified packaged Info.plist, uploaded
      build `67f39308-02eb-4a9a-9d32-64698ea4d99b`, and waited until `VALID`.
      Attach was not run because escalation was blocked by the environment
      usage limit.
- [ ] Confirm Crashlytics receives dSYMs from the SPM path for build `3`.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
  deployment config; current `verify_jwt` behavior is documented but no
  `supabase/config.toml` exists.

## Plan (2026-06-01 Flutter 3.44 Global Docs Sync)
- [x] Scan Pet and Kurabe current-state docs for Flutter/Dart/FVM guidance.
- [x] Update Pet current docs so bare global `flutter` is the expected 3.44.0
  command path, with FVM only as an optional same-version fallback.
- [x] Update Kurabe current docs for the same global Flutter 3.44.0 workflow.
- [x] Re-scan docs for stale current-state guidance.

- Review: Updated Pet `AGENTS.md`, `README.md`, `memory-bank/tech-stack.md`,
  and `memory-bank/progress.md` so current guidance expects bare global
  Flutter `3.44.0` / Dart `3.12.0`, with FVM only as an optional same-version
  fallback.
- Review: Updated Kurabe `README.md`, `tasks/lessons.md`, and task notes to
  reflect the same global Flutter baseline, the bare-Fastlane workflow, and the
  `phosphoricons_flutter` icon migration.

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
  --check`, `flutter analyze`, and `flutter test` passed (446 passed, 1
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
  passed with `flutter test` before this docs compaction, but live DB
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
