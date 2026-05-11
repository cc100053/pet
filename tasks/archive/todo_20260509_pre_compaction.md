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

## Plan (2026-05-08 GEO Marketing Workspace Split)
- [x] Verify GEOFlow Docker checkout, Firebase Hosting config, static `html/`,
  export scripts, manifests, and docs are present in
  `/Users/fatboy/geo-marketing`.
- [x] Update the daily Codex automation to run from the shared GEO marketing
  workspace.
- [x] Remove migrated GEOFlow/Firebase Hosting files from this Flutter app repo.
- [x] Update app repo memory-bank notes to point marketing work to the external
  workspace.

## Review (2026-05-08 GEO Marketing Workspace Split)
- Confirmed `/Users/fatboy/geo-marketing/shared/GEOFlow` contains the Docker
  GEOFlow checkout and `/Users/fatboy/geo-marketing/projects/pettomo` contains
  Firebase Hosting config, static `html/`, export script, manifest, and docs.
- Verified the PetTomo export script runs successfully from the new workspace.
- Removed migrated hosting/GEO files from this repo:
  `deployments/`, `html/`, `.firebase/`, `.firebaserc`, `firebase.json`,
  GEOFlow docs, and GEOFlow export/manifest scripts.
- Updated `memory-bank/architecture.md` and `memory-bank/progress.md` so future
  app work does not assume Firebase Hosting/GEOFlow assets live in this repo.
- Verification:
  confirmed the old hosting/GEO paths no longer exist in this repo,
  `node --check scripts/generate_apple_client_secret.mjs` passed,
  `git diff --check` passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing Supabase env-gated feed integration
  test skipped.

## Plan (2026-05-07 GEOFlow Content Workflow)
- [x] Document the repeatable one-topic, five-language GEOFlow publishing
  process.
- [x] Include GEO optimization, editorial review, manifest, export, deploy, and
  Search Console responsibilities.
- [x] Link the workflow from GEOFlow deployment notes and memory-bank.

## Review (2026-05-07 GEOFlow Content Workflow)
- Added `docs/geoflow_content_workflow.md` as the canonical workflow for future
  GEOFlow content sections.
- Documented the default publishing rule:
  `1 topic = 5 language pages = 1 hreflang group`.
- Cross-linked the workflow from `docs/geoflow_deployment.md` and
  `memory-bank/progress.md`.

## Plan (2026-05-07 GEOFlow Multilingual Guides)
- [x] Add manifest-based guide export with language folders and hreflang.
- [x] Create approved GEOFlow article records for five core guides in
  Traditional Chinese, Simplified Chinese, Japanese, and Korean.
- [x] Preserve existing English guide URLs while adding `/guides/en/` canonical
  language pages.
- [x] Regenerate guide pages and sitemap for all configured languages.
- [x] Run verification, deploy Firebase Hosting, and verify live URLs.

## Review (2026-05-07 GEOFlow Multilingual Guides)
- Inserted 20 localized GEOFlow article records for core guide groups:
  PetTomo difference, couples, friends, shared rooms, and photo feeding.
- Added `scripts/geoflow_guides_manifest.json` as the publishing manifest for
  article id, language, translation group, slug, and legacy aliases.
- Updated `scripts/export_geoflow_guides.mjs` to render language folders,
  language index pages, canonical URLs, sitemap entries, and page-level
  `hreflang` alternates.
- Current static guide output includes 30 GEOFlow article pages:
  10 English pages plus 5 core pages each for `zh-hant`, `zh-hans`, `ja`, and
  `ko`.
- Verification:
  checked generated language folders and `hreflang` links,
  fixed mixed-language template text before publishing,
  `node --check scripts/export_geoflow_guides.mjs` passed,
  `git diff --check` passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing Supabase env-gated feed integration
  test skipped,
  Firebase Hosting deploy passed,
  live HTTP checks for Japanese, Traditional Chinese, Korean guide pages and
  `/sitemap.xml` returned 200.

## Plan (2026-05-07 GEOFlow Long-Distance Couples Batch)
- [x] Create a GEOFlow CMS batch for five long-distance couples SEO articles.
- [x] Attach the batch to title/keyword/task records inside GEOFlow.
- [x] Review the articles for PetTomo factual fit, structure, and duplicate
  intent.
- [x] Export the reviewed articles with the existing public guide set.
- [x] Deploy Firebase Hosting and verify live guide URLs.

## Review (2026-05-07 GEOFlow Long-Distance Couples Batch)
- Created GEOFlow task `PetTomo Long-Distance Couples - Draft Batch 1` with
  article ids 9-13.
- Added matching title and keyword libraries for long-distance couple search
  intent.
- Marked the five article records as `review_status = approved` while keeping
  them in GEOFlow's draft pool.
- Updated the static export default article set to include reviewed ids 4-13.
- Exported 10 total public guide pages and deployed them to Firebase Hosting.
- Verification:
  article quality checks passed for ids 9-13,
  `node --check scripts/export_geoflow_guides.mjs` passed,
  `git diff --check` passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing Supabase env-gated feed integration
  test skipped,
  live HTTP checks for `/guides/` and two new article URLs returned 200,
  live sitemap includes all 10 guide URLs.

## Plan (2026-05-07 GEOFlow Static Firebase Guides)
- [x] Export only the current PetTomo Core Guides batch from GEOFlow article ids
  4-8; skip old ids 1-3 because they came from the earlier wrong prompt/context.
- [x] Add a repeatable static export script for reviewed GEOFlow articles.
- [x] Generate Firebase Hosting pages under `html/guides/`, plus sitemap and
  robots files.
- [x] Document the free Firebase Hosting workflow.
- [x] Run final verification checks.

## Review (2026-05-07 GEOFlow Static Firebase Guides)
- Added `scripts/export_geoflow_guides.mjs`, which reads selected local GEOFlow
  articles through Docker Compose and renders static guide pages for Firebase
  Hosting.
- Generated five SEO guide pages under `html/guides/`, with a guides index,
  canonical URLs, Open Graph tags, Article JSON-LD, `html/sitemap.xml`, and
  `html/robots.txt`.
- Kept GEOFlow as the local CMS/drafting system; Firebase Hosting receives only
  static reviewed output, so the workflow can stay on the free Spark plan.
- Documented the workflow and Google Search Console follow-up in
  `docs/geoflow_deployment.md`.
- Verification:
  `node --check scripts/export_geoflow_guides.mjs` passed,
  `node scripts/export_geoflow_guides.mjs --ids=4,5,6,7,8` exported 5 pages,
  `git diff --check` passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing Supabase env-gated feed integration
  test skipped,
  Firebase Hosting deploy to `pet-app-702be` passed,
  live HTTP checks for `/guides/`, `/sitemap.xml`, and one guide page returned
  200.

## Plan (2026-05-07 GEOFlow Deployment)
- [x] Confirm GEOFlow should run as an external Laravel content/GEO service,
  not as a Flutter app dependency.
- [x] Clone GEOFlow into a gitignored local deployment directory.
- [x] Configure local PetTomo GEOFlow env values and start Docker services.
- [x] Replace the default local admin password.
- [x] Document local usage and production deployment requirements.
- [x] Run verification checks.

## Review (2026-05-07 GEOFlow Deployment)
- Cloned `https://github.com/yaojingang/GEOFlow` into
  `deployments/GEOFlow`, with `deployments/` ignored by PicPet git.
- Created local GEOFlow `.env` values for `PetTomo Guides` /
  `PetTomo GEO Content Center`; kept the deployment outside the Flutter runtime.
- Built the shared `geoflow-app:latest` image with `docker compose build app`
  because GEOFlow's compose file can collide when several services build the
  same image tag in parallel under Docker Compose v5.
- Started local PostgreSQL, Redis, app, queue, scheduler, and Reverb services
  with `docker compose up -d --no-build`.
- Verified local front page and admin login return HTTP 200 at
  `http://127.0.0.1:18080` and `/geo_admin/login`; admin user is active.
- Changed the seeded local `admin` account away from the public default
  password.
- Added `docs/geoflow_deployment.md` with local commands, usage guidance, and
  production `[USER ACTION REQUIRED]` steps.
- Verification:
  local GEOFlow front/admin HTTP checks passed,
  `flutter analyze` passed,
  `flutter test` passed with the existing Supabase env-gated feed integration
  test skipped,
  `git diff --check` passed.

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
