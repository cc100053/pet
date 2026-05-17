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

## Plan (2026-05-17 Multi-Pet System Review)
- [x] Read active memory-bank files, task notes, local shared-item rollout
  guidance, and the multi-pet design draft.
- [x] Inspect current pet, room, pet_state, equipment, room selection, and Home
  assumptions that are affected by allowing more than one pet per room.
- [x] Identify planning gaps, compatibility risks, and equipment ownership /
  equip-target decisions.
- [x] Produce a detailed phased execution plan for implementation review before
  any schema or app changes begin.

## Review (2026-05-17 Multi-Pet System Review)
- Current schema and UI are still one-pet-per-room in critical places:
  `pets.room_id` is unique, Home tracks one active pet, pet state is keyed by
  pet, room cards collapse pets to one summary, and equipment summaries ignore
  `pet_id`.
- Existing equipment ownership is room-scoped, while equip state is
  `(room_id, pet_id, slot)`. Multi-pet should preserve that split and make the
  selected equip target explicit in all UI/RPC paths.
- The main open product decision is whether hunger/affection become truly
  room-scoped shared state or remain stored on a representative pet for old
  client compatibility. The safer path is additive room-scoped state plus
  compatibility mirroring until old versions age out.

## Plan (2026-05-17 Multi-Pet v2.0.0 Implementation)
- [x] Bump app version and all rollout gates to `2.0.0`.
- [x] Add additive multi-pet schema:
  remove one-pet-per-room uniqueness, add `rooms.main_pet_id`, seed
  `room_pet_state`, and keep old `pet_state` available for old clients.
- [x] Add backend RPCs for v2.0.0:
  room pet list, add pet with capacity checks, set main pet, and room-scoped
  pet actions that mirror the main pet state for compatibility.
- [x] Update equipment backend:
  room inventory quantity can grow up to active pet count; equip is limited by
  owned copy count; one copy cannot be equipped on two pets at the same time.
- [x] Update Shop:
  equipment cards show owned count and allow Buy More until owned quantity
  reaches the room's pet count.
- [x] Add v2.0.0 pet-ticket purchase/consume flow:
  catalog item at 150 diamonds, atomic buy-and-add RPC, owned-ticket recovery
  consume, and Shop entry point for inviting another room pet.
- [ ] Update Home:
  load room pet list, render multiple pets, use main pet for room summaries and
  chat/avatar surfaces, and add per-pet equipment target selection.
- [ ] Add tests for capacity, equipment copy limits, main-pet summaries,
  room-scoped hunger, and version gates.
- [x] Run `flutter analyze` and `flutter test`.

## Review (2026-05-17 Multi-Pet v2.0.0 Foundation)
- Bumped app version to `2.0.0+1`.
- Added and applied live Supabase migrations:
  `multi_pet_v200_foundation` and `add_room_pet_action_rpc`.
- Live schema now has `rooms.main_pet_id`, non-unique `pets.room_id`,
  `room_pet_state`, and v2 RPCs:
  `get_room_pets`, `add_room_pet`, `set_room_main_pet`,
  `apply_room_pet_action`.
- Updated equipment RPC behavior:
  equipment quantity can grow up to room pet count, and `equip_pet_item`
  rejects wearing an item when all owned copies are already equipped.
- Updated Shop equipment cards to show owned count and allow `Buy more` until
  owned count reaches room pet count.
- Added widget tests for equipment buy-more and capacity lock behavior.
- Pet ticket flow is now wired:
  live `pet_ticket` catalog item costs 150 diamonds, is hidden from pre-2.0.0
  clients, and `purchase_and_use_pet_ticket` atomically checks room capacity,
  deducts diamonds, writes the ledger, and adds the selected pet. Same pet types
  are allowed.
- Shop now treats pet-ticket buy like Return Letter:
  rooms with 5 pets are blocked before purchase, otherwise Buy opens pet
  selection and submits the atomic buy-and-add RPC. Already-owned tickets still
  show `Use` and call `use_pet_ticket` as a recovery path.
- Remaining implementation: Home multi-pet rendering, per-pet equipment target
  picker, main-pet switcher UI, and room-scoped state reads in Home.
- Verification:
  live migration sanity checks passed,
  `flutter analyze` passed,
  `flutter test --concurrency=1` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.
  A default parallel `flutter test` run hit a transient
  `feed_upload_queue_test.dart` failure; that test file passed when rerun
  directly.

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
