# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Historical snapshot before this compaction:
`tasks/archive/todo_20260509_pre_compaction.md`.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.

## Plan (2026-05-11 Equipment Slot Taxonomy)
- [x] Read `shared-item-rollout`, active `memory-bank/*.md`,
  `tasks/lessons.md`, and the Godot socket/equipment workflow.
- [x] Inspect current equipment slots across Flutter, tests, and Supabase RPCs.
- [x] Add a `face` logical equipment slot so sunglasses can coexist with hats
  while still using the head socket anchor.
- [x] Keep hats mutually exclusive in the `head` slot and ribbon in `body`.
- [x] Update Supabase item metadata, slot constraints, and equip/unequip RPC
  validation for the new slot.
- [x] Update app labels, debug/preview surfaces, and tests.
- [ ] Apply and verify the live Supabase migration. Blocked by Supabase MCP
  usage-limit rejection on 2026-05-11.
- [x] Run verification and record results.

## Review (2026-05-11 Equipment Slot Taxonomy)
- Added `face` as a logical equipment slot so sunglasses can coexist with hats
  while resolving through the same head socket anchor.
- Kept hats mutually exclusive in the `head` slot and ribbon in `body`, so
  sunglasses, hats, and ribbon can all be equipped together.
- Updated Flutter catalog metadata, localized slot labels, debug/preview
  surfaces, and regression tests for separate `head`/`face` groups.
- Added local Supabase migration
  `20260511233336_add_face_equipment_slot.sql` to update item metadata,
  `pet_equipment` slot constraints, existing sunglasses equip rows, and
  equip/unequip RPC slot validation.
- Verification:
  `flutter gen-l10n` completed,
  focused equipment/shop tests passed,
  `flutter analyze` passed,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.
- Live Supabase migration was not applied: Supabase MCP SQL/migration actions
  were blocked by an automatic usage-limit rejection on 2026-05-11.

## Plan (2026-05-11 V1.4.0 Release Notes Sync)
- [x] Read `release-notes-sync`, `asc-metadata-sync`, and `asc-cli-usage`.
- [x] Update bundled in-app What's New for V1.4.0.
- [x] Update local ASC version localization `.strings` files for V1.4.0.
- [x] Run l10n generation, formatting, analyzer, and tests.
- [x] Sync the approved release notes to App Store Connect and verify.
- [x] Record final verification and any deployment limits.

## Review (2026-05-11 V1.4.0 Release Notes Sync)
- Added bundled in-app What's New entry for `1.4.0` and localized copy for
  `en`, `ja`, `ko`, `zh_TW`, and `zh`.
- Updated ASC version-localization files for `en-US`, `ja`, `ko`, and
  `zh-Hant` with approved V1.4.0 `promotionalText` and `whatsNew` drafts.
- Created App Store Connect version `1.4.0`
  (`5b2badc0-462d-4519-a78e-aafd070a313d`) by copying metadata from `1.3.0`.
- Uploaded and verified version localizations for `en-US`, `ja`, `ko`, and
  `zh-Hant`.
- Verification:
  `flutter gen-l10n` completed,
  `dart format lib/shared/whats_new/app_whats_new_catalog.dart` passed,
  `flutter analyze` passed,
  focused What's New/shop tests passed,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.

## Plan (2026-05-11 V1.4.0 Equipment Pricing & Release Draft)
- [x] Read `shared-item-rollout`, `release-notes-sync`, active
  `memory-bank/*.md`, `tasks/lessons.md`, and current task notes.
- [x] Confirm the three target items: crown, sunglasses, and ribbon.
- [x] Update local Supabase migration/catalog data so all three V1.4.0 equipment
  items cost a slightly higher price.
- [x] Apply and verify the catalog pricing on the live Supabase project.
- [x] Sync app/notification display names and targeted tests for the added shop
  rows.
- [x] Draft V1.4.0 release notes for supported ASC locales without uploading.
- [x] Run verification and record results.

## Review (2026-05-11 V1.4.0 Equipment Pricing & Release Draft)
- Set `equip_crown`, `equip_sunglasses`, and `equip_ribbon` to 160 coins in a
  new Supabase migration and applied it to the live project.
- Added missing shop rows for sunglasses and ribbon with V1.4.0 version gating,
  `is_active = false`, equipment slots, asset paths, and `price_jpy = 160`.
- Synced app and notification display names for the added equipment SKUs.
- Drafted V1.4.0 release notes for `en-US`, `ja`, `ko`, and `zh-Hant`; no ASC
  files were updated and nothing was uploaded.
- Verification:
  live `items` rows show all three equipment items at 160 coins,
  `get_visible_shop_items` hides them from `1.3.9` and exposes them to
  `1.4.0`/`1.4.0+1`,
  `flutter gen-l10n` completed,
  focused equipment/shop tests passed,
  `flutter analyze` passed,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.
- Note: `notify_friend` is updated locally; deploy the edge function before
  expecting notification name changes in production.

## Plan (2026-05-11 V1.4.0 Equipment Rollout Audit)
- [x] Read `shared-item-rollout`, active `memory-bank/*.md`,
  `tasks/lessons.md`, and the Godot socket/equipment workflow.
- [x] Identify the new V1.4.0 equipment catalog, app, asset, and backend
  changes.
- [x] Audit version gating, old-client rendering fallback, purchase/RLS
  enforcement, localization, and tests.
- [x] Record findings and verification limits.

## Review (2026-05-11 V1.4.0 Equipment Rollout Audit)
- Verified live `equip_crown` rollout data is version-gated from `1.4.0`:
  hidden for `1.3.9`, visible for `1.4.0` and `1.4.0+1`.
- Confirmed app version is `1.4.0+1`, `assets/equipment/hats/crown.png` is
  bundled, and localized shop names exist in app ARB/generated localization.
- Updated stale equipment/socket tests to match the current Godot exports and
  catalog metadata, and added a V1.4.0 crown compatibility regression test.
- Added `equip_straw_hat` and `equip_crown` localized names to
  `notify_friend` so notification copy does not fall back to raw item ids.
- Verification:
  focused equipment/socket tests passed,
  `flutter analyze` passed,
  `flutter build bundle` passed and the asset manifest includes crown/straw hat,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.
- Note: `notify_friend` is updated locally; deploy the edge function before
  expecting notification name changes in production.

## Plan (2026-05-09 AGENTS.md & Memory-Bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
  `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts and archive current snapshots.
- [x] Inspect repo-local workflow sources before documenting changes:
  `.codex/skills/`, referenced `docs/`, `scripts/`, and `supabase/functions/`.
- [x] Apply minimal AGENTS/docs updates and compact active notes.
- [x] Run verification and record the review here.

## Review (2026-05-09 AGENTS.md & Memory-Bank Optimization)
- Updated `AGENTS.md` with the supported Apple raw JWT command and the current
  Firebase Hosting/GEO marketing boundary.
- Fixed stale Crashlytics workflow docs that referenced removed local
  `firebase.json` / `.firebaserc` files.
- Compacted active memory-bank summaries and archived pre-compaction snapshots:
  `memory-bank/archive/architecture_20260509_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260509_pre_compaction.md`, and
  `memory-bank/archive/progress_20260509_pre_compaction.md`.
- Archived the long task log to
  `tasks/archive/todo_20260509_pre_compaction.md` and kept this file focused on
  active follow-ups plus the current run.
- Active memory-bank line counts:
  before `75/78/67/34/35 = 289` total for
  `architecture/database-schema/progress/tech-stack/ui-ux-guidelines`;
  after `65/71/59/34/35 = 264` total.
- Verification:
  `wc -l memory-bank/*.md` captured before/after counts,
  `git diff --check` passed,
  scoped `git diff --stat` stayed within AGENTS/docs/memory/tasks,
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped:
  `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
- Note: the working tree still includes pre-existing deletions of `.firebase/`,
  `.firebaserc`, `firebase.json`, and `html/` files from the GEO workspace
  split; this run did not revert or recreate them.
