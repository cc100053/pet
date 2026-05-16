# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Latest historical snapshot before compaction:
`tasks/archive/todo_20260516_pre_compaction.md`.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
  deployment config; current `verify_jwt` behavior is documented but no
  `supabase/config.toml` exists.

## Plan (2026-05-16 Persistent Firebase SPM Target Fix)
- [x] Re-read active memory-bank files, task notes, and lessons.
- [x] Confirm the ignored Flutter-generated SPM manifest can revert to
  `.iOS("13.0")` before Xcode resolves packages.
- [x] Add a tracked Xcode local package manifest that pins the generated plugin
  package platform to iOS 15.0 while pointing at Flutter's generated plugin
  symlinks.
- [x] Repoint the Runner Xcode project package reference from ignored
  `Flutter/ephemeral/...` to the tracked manifest.
- [x] Verify Xcode package resolution/build and rerun Flutter checks.

## Review (2026-05-16 Persistent Firebase SPM Target Fix)
- Added tracked `ios/Flutter/GeneratedPluginSwiftPackage/Package.swift` with
  `.iOS("15.0")` while keeping dependencies pointed at Flutter's generated
  plugin symlinks under `ios/Flutter/ephemeral/Packages/.packages/`.
- Added a placeholder Swift source so Xcode treats the tracked local package as
  a valid non-empty target.
- Repointed `Runner.xcodeproj` local package references from the ignored
  generated manifest to `Flutter/GeneratedPluginSwiftPackage`.
- The ignored ephemeral manifest may still regenerate with `.iOS("13.0")`, but
  Xcode no longer references that package wrapper.
- Documented the tracked-package iOS SPM flow in `memory-bank/tech-stack.md`.
- Verification:
  `xcodebuild -resolvePackageDependencies -workspace ios/Runner.xcworkspace ...`
  passed and resolved `FlutterGeneratedPluginSwiftPackage` from the tracked
  path,
  `xcodebuild -workspace ios/Runner.xcworkspace ... CODE_SIGNING_ALLOWED=NO build`
  passed,
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped for
  missing Supabase env vars.

## Plan (2026-05-16 Firebase iOS Deployment Target Fix)
- [x] Read active memory-bank files, task notes, and lessons.
- [x] Locate every iOS deployment target source that could drive Flutter's SPM
  package generation.
- [x] Make the Runner iOS target minimum explicit at 15.0 so Firebase SPM
  products and generated plugin package agree.
- [x] Regenerate/check iOS dependency files and verify the generated package no
  longer advertises iOS 13.0.
- [x] Run `flutter analyze` and `flutter test`, then record results.

## Review (2026-05-16 Firebase iOS Deployment Target Fix)
- Added explicit `IPHONEOS_DEPLOYMENT_TARGET = 15.0` to the Runner and
  RunnerTests target build configurations in
  `ios/Runner.xcodeproj/project.pbxproj`.
- Ran `flutter build ios --config-only --no-codesign`; Flutter regenerated
  `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift`
  with `.iOS("15.0")` instead of `.iOS("13.0")`.
- Verification:
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped for
  missing Supabase env vars.

## Plan (2026-05-16 V1.4.0 Equipment Price Change)
- [x] Read shared item rollout guidance, active memory-bank files, task notes,
  and lessons.
- [x] Confirm live catalog state for crown, ribbon, and sunglasses.
- [x] Add a local Supabase migration that updates only the requested prices.
- [x] Apply the migration to live Supabase and verify prices, slots, and
  version gating.
- [x] Record results.

## Review (2026-05-16 V1.4.0 Equipment Price Change)
- Added local migration `20260516230910_update_v140_equipment_prices.sql` and
  applied it live through Supabase MCP as `20260516140955_update_v140_equipment_prices`.
- Updated live catalog prices:
  crown `260`, ribbon `170`, sunglasses `240`.
- Verified slots and rollout gates stayed intact:
  crown `head`, ribbon `body`, sunglasses `face`; all remain
  `min_app_version = 1.4.0` and `is_active = false`.
- Verified `get_visible_shop_items('1.3.9')` still hides the three items, while
  `1.4.0` and `1.4.0+1` expose the new prices.
- Verification:
  `flutter analyze` passed,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.

## Review (2026-05-16 Face Equipment Slot Live Migration)
- Applied local migration `20260511233336_add_face_equipment_slot.sql` to live
  Supabase through MCP as `20260516140526_add_face_equipment_slot`.
- Verified `equip_sunglasses` now has `equipment_slot = face`; `equip_crown`
  remains `head`, `equip_ribbon` remains `body`, and all three stay
  `min_app_version = 1.4.0`, `price_coins = 160`, `is_active = false`.
- Verified `pet_equipment_slot_check` allows `head`, `face`, `body`, and
  `back`, and both `equip_pet_item` / `unequip_pet_item` include `face` slot
  validation.
- Verified `get_visible_shop_items('1.3.9')` hides all three V1.4.0 equipment
  items, while `1.4.0` and `1.4.0+1` expose crown/head, sunglasses/face, and
  ribbon/body.

## Plan (2026-05-16 AGENTS.md & Memory-Bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
  `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts before editing.
- [x] Inspect repo-local workflow sources: `.codex/skills/`, referenced
  `docs/`, `scripts/`, `supabase/functions/`, and relevant migrations.
- [x] Archive current memory/task snapshots before compaction.
- [x] Apply minimal `AGENTS.md`, memory-bank, and task-note updates.
- [x] Run verification and record results.

## Review (2026-05-16 AGENTS.md & Memory-Bank Optimization)
- Updated `AGENTS.md` with the existing `ui-ux-pro-max` local skill and
  documented Edge Function config/secrets that are grounded in source.
- Compacted active memory-bank summaries and archived pre-compaction snapshots:
  `memory-bank/archive/*_20260516_pre_compaction.md`.
- Archived the task log to `tasks/archive/todo_20260516_pre_compaction.md`.
- Active memory-bank line counts:
  before `73/76/60/34/35 = 278` total for
  `architecture/database-schema/progress/tech-stack/ui-ux-guidelines`;
  after `65/68/53/33/30 = 249` total.
- `tasks/todo.md` was compacted from 204 lines in the archived snapshot to 31
  lines before this review section.
- Verification:
  `wc -l memory-bank/*.md` captured before/after counts,
  `git diff --check` passed,
  `git diff --stat` stayed within `AGENTS.md`, `memory-bank/`, and `tasks/`,
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped:
  `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
