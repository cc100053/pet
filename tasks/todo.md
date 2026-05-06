# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.

## Plan (2026-05-07 GEOFlow Integration)
- [ ] Confirm GEOFlow's deployment/runtime shape and the safest app boundary.
- [ ] Add a configurable GEOFlow URL path for the Flutter app.
- [ ] Add a localized in-app entry point that opens the deployed GEOFlow site.
- [ ] Document install/deploy/use steps for PicPet.
- [ ] Run `dart format`, `flutter analyze`, and `flutter test`.

## Plan (2026-05-06 Crown Equipment)
- [x] Reuse the existing head socket/motion pipeline and add `equip_crown` as a
  new head equipment definition.
- [x] Add localized shop-name lookup and a version-gated catalog migration for
  the crown item without changing existing equipment behavior.
- [x] Add focused catalog/layout tests for the crown defaults.
- [x] Run formatting, localization generation, analyzer, and tests.
- [x] Record review notes and verification results.

## Review (2026-05-06 Crown Equipment)
- Added `equip_crown` as a head-slot equipment definition using the existing
  pet head socket/motion tracks. Initial fit is bottom-center anchored
  (`x=0.5`, `y=0.82`) with square source sizing at `0.34` pet width.
- Added localized shop-name lookup for Crown/王冠/皇冠/왕관 and generated
  Flutter localization files.
- Added and applied migration `20260506144656_add_crown_equipment.sql` with
  `visibility_mode = version_gated`, `min_app_version = 1.4.0`, and
  `is_active = false`, matching the existing compatibility rollout style.
- Verified the live Supabase target through Edge Function paths before applying:
  `mcp__supabase_pet__` points at repo project `ilxzpszgirhwxpeocygs`; the
  other available MCP project is unrelated.
- Verified live catalog behavior: `equip_crown` is hidden from
  `get_visible_shop_items('1.3.9')` and visible from
  `get_visible_shop_items('1.4.0')`.
- Verification:
  `dart format` passed for changed Dart/test files,
  `flutter gen-l10n` completed with existing ko/zh_TW untranslated-message
  warnings,
  focused equipment tests passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars,
  `flutter build bundle` passed and `AssetManifest.bin` contains
  `assets/equipment/hats/crown.png`,
  `git diff --check` passed.

## Plan (2026-05-05 Durable Feed Completion)
- [x] Trace the feed upload queue, `feed_validate`, and Home/Chat completion
  side effects for app-background and room-switch cases.
- [x] Keep unacknowledged completed/failed feed jobs replayable after lifecycle
  resume without double-applying UI side effects.
- [x] Refresh the original feed room's pet state after completion, even if the
  user has switched rooms or returned to room selection.
- [x] Add focused tests for persisted terminal queue events.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`.
- [x] Record review notes and verification results.

## Review (2026-05-05 Durable Feed Completion)
- Home now replays loaded, unacknowledged completed/failed feed jobs on startup
  post-frame and app resume, with temp-id de-duping. Replayed completions are
  treated as reconciliation so server balance/state are reloaded without local
  duplicate coin animations.
- Feed completion refreshes the room that originated the upload instead of the
  currently selected room, so room switches and room-selection exits still
  update the correct pet health snapshot.
- Verified the live Supabase `feed_validate` project ref from Edge Function
  paths (`ilxzpszgirhwxpeocygs`) and confirmed `process_feed_event` remains the
  atomic server path for feed action, reward, and message insertion.
- Verification:
  `dart format` passed for changed Dart files,
  `flutter analyze` passed,
  `flutter test test/features/feed/feed_upload_queue_test.dart` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars.

## Plan (2026-05-05 Codebase Maintainability Refactor)
- [x] Read active `memory-bank/*.md`, `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Identify oversized Dart files and low-risk extraction boundaries.
- [x] Split `chat_room_view_v2.dart` private UI widgets into a focused part
  file without changing runtime behavior.
- [x] Split Home pet-scene rendering helpers out of `home_view.dart` without
  changing state ownership or RPC behavior.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`.
- [x] Record review notes with file-size impact and verification results.

## Review (2026-05-05 Codebase Maintainability Refactor)
- Split Chat route-only UI widgets into
  `lib/features/chat/chat_room_view_v2_widgets.dart`; kept message loading,
  realtime, cache, send/edit/delete, and scroll-window logic in
  `chat_room_view_v2.dart`.
- Split Home pet-scene rendering helpers into
  `lib/features/home/home_view_pet_scene_builders.dart`; kept state mutation
  and Supabase write actions inside `home_view.dart`.
- File-size impact:
  `chat_room_view_v2.dart` 5906 -> 3913 lines, with 1996 lines in the new UI
  part; `home_view.dart` 6202 -> 5318 lines, with 890 lines in the new pet
  scene part.
- Verification:
  `dart format` passed for changed Dart files,
  `flutter analyze` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars.

## Plan (2026-05-05 Deeper Route UI Refactor)
- [x] Inspect extracted Chat/Home UI parts for smaller ownership boundaries.
- [x] Split Chat UI widgets into focused part files for overlays/composer,
  message bubbles/feed cards, and top-bar/reply chrome.
- [x] Extract Home drawer/debug UI into a focused route UI part file.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`.
- [x] Record review notes with updated file-size impact and verification.

## Review (2026-05-05 Deeper Route UI Refactor)
- Replaced the single large Chat UI part with focused route-private parts:
  `chat_room_view_v2_overlays.dart`,
  `chat_room_view_v2_composer.dart`,
  `chat_room_view_v2_messages.dart`, and
  `chat_room_view_v2_chrome.dart`.
- Extracted Home drawer/debug UI to `home_view_drawer.dart`; kept the actual
  socket-debug state mutation in `_HomeViewState` via `_setShowSocketDebug`.
- Updated file sizes:
  `chat_room_view_v2.dart` is 3916 lines, Chat UI parts are
  143/445/1109/302 lines, `home_view.dart` is 5124 lines,
  `home_view_drawer.dart` is 202 lines, and
  `home_view_pet_scene_builders.dart` remains 890 lines.
- Verification:
  `dart format` passed for changed Dart files,
  `flutter analyze` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars.

## Plan (2026-05-05 Chat Behavior Helper Refactor)
- [x] Re-read active `memory-bank/*.md`, `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Identify Chat helpers that can move without direct `setState` usage.
- [x] Extract Chat data/profile/reaction/format helpers into a focused part
  file while keeping state transitions in `chat_room_view_v2.dart`.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`.
- [x] Record review notes with updated file-size impact and verification.

## Review (2026-05-05 Chat Behavior Helper Refactor)
- Added `lib/features/chat/chat_room_view_v2_data_helpers.dart` for route-private
  data helpers: message sorting/filtering/fetch page wrapping, reply preview
  resolution, cache persistence, reaction/profile display helpers, grouping
  checks, and UI message conversion.
- Kept direct UI state transitions, realtime handling, send/edit/delete actions,
  and viewport synchronization in `chat_room_view_v2.dart`.
- File-size impact:
  `chat_room_view_v2.dart` is now 3566 lines, down from 3916 after the previous
  split; the new data helper part is 354 lines.
- Verification:
  `dart format` passed for changed Dart files,
  `flutter analyze` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars.

## Plan (2026-05-05 Home Data Helper Refactor)
- [x] Re-read active `memory-bank/*.md`, `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Identify Home helpers that can move without direct `setState` usage.
- [x] Extract Home read-only/data/geometry helpers into a focused part file
  while keeping state transitions in `home_view.dart`.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`.
- [x] Record review notes with updated file-size impact and verification.

## Review (2026-05-05 Home Data Helper Refactor)
- Added `lib/features/home/home_view_data_helpers.dart` for route-private helper
  logic: reward parsing, poop position normalization, pet exp/health display
  math, departed-pet display resolution, shared decor compatibility checks,
  furniture sizing/geometry, and transform response parsing.
- Kept direct `setState` calls, Supabase writes/RPC orchestration, subscriptions,
  and UI builders in `home_view.dart`.
- File-size impact:
  `home_view.dart` is now 4785 lines, down from 5124 after the previous split;
  the new data helper part is 343 lines.
- Verification:
  `dart format` passed for changed Dart files,
  `flutter analyze` passed,
  `flutter test` passed with the existing feed integration test skipped due
  missing Supabase test env vars.

## Plan (2026-05-02 AGENTS.md & Memory-Bank Optimization)
- [x] Read `AGENTS.md`, active `memory-bank/*.md`, `tasks/todo.md`, and
  `tasks/lessons.md`.
- [x] Inspect repo-local workflow sources in `.codex/skills/`, `docs/`,
  `scripts/`, and `supabase/functions/` before documenting anything.
- [x] Archive pre-compaction snapshots for active memory-bank files that will be
  shortened.
- [x] Apply minimal repo-grounded updates to `AGENTS.md` and compact active
  `memory-bank/*.md` files.
- [x] Run `wc -l memory-bank/*.md`, `git diff --stat`, `flutter analyze`, and
  `flutter test`.
- [x] Record review notes with before/after counts, archive paths, and
  verification results.

## Plan (2026-05-02 Compress Task Log)
- [x] Identify whether `tasks/todo.md` still contains current actionable items.
- [x] Preserve only active follow-ups and compact current-session context.
- [x] Remove long historical plan/review logs from the active task file.
- [x] Run required verification.

## Review (2026-05-02 Repo Documentation Cleanup)
- Removed stale docs that were completed, superseded, or misleading compared
  with current code/memory-bank state.
- Kept current operational docs only: Crashlytics MCP, Godot PNG/socket
  workflow, hunger tick schedule report, label mapping, and testing helpers.
- Replaced duplicated `CLAUDE.md` guidance with a short pointer to canonical
  `AGENTS.md`.
- Updated `README.md` into a current doc index and added
  `.firebase-mcp.env.example` for Crashlytics MCP setup.
- Verification already run for that cleanup: `flutter analyze` passed and
  `flutter test` passed, with `test/feed_flow_integration_test.dart` skipped
  due missing Supabase test env vars.

## Review (2026-05-02 Compress Task Log)
- Compressed `tasks/todo.md` from a long historical task log into a compact
  current task file.
- Preserved only active release follow-ups and the latest repo documentation
  cleanup summary.
- Verification: `flutter analyze` passed; `flutter test` passed with
  `test/feed_flow_integration_test.dart` skipped due missing Supabase test env
  vars.

## Review (2026-05-02 AGENTS.md & Memory-Bank Optimization)
- Updated `AGENTS.md` only with repo-grounded Crashlytics workflow details:
  prefer ADC via `.firebase-mcp.env` and inspect
  `ios/scripts/upload_crashlytics_symbols.sh` when stacks are unsymbolicated.
- Compacted active memory-bank files into current-state summaries and archived
  full pre-compaction snapshots:
  `memory-bank/archive/architecture_20260502_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260502_pre_compaction.md`,
  `memory-bank/archive/progress_20260502_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260502_pre_compaction.md`,
  `memory-bank/archive/ui_ux_guidelines_20260502_pre_compaction.md`.
- Active memory-bank line counts:
  before `121/114/92/57/81 = 465` total for
  `architecture/database-schema/progress/tech-stack/ui-ux-guidelines`;
  after `71/78/55/34/35 = 273` total.
- `git diff --stat` inspection stayed within `AGENTS.md`, active
  `memory-bank/*.md`, and the already-dirty `tasks/todo.md`.
- Verification:
  `wc -l memory-bank/*.md` captured before/after counts,
  `flutter analyze` passed,
  `flutter test` passed, and
  `test/feed_flow_integration_test.dart` was skipped with:
  `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
