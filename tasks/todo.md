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

## Plan (2026-05-21 iOS Export Symbol Upload Warning)
- [x] Add a repo-tracked App Store export options plist with Apple's immediate
  symbol upload disabled.
- [x] Add a repeatable archive export/upload script that uses the plist.
- [x] Document the release workflow and verification steps.
- [x] Run syntax/plist checks plus Flutter verification.

## Review (2026-05-21 iOS Export Symbol Upload Warning)
- Root cause: Xcode Organizer-generated App Store export options set
  `uploadSymbols=true`, so `IDEDistributionSymbolsStep` tries Apple's immediate
  symbol upload during export/upload. This can fail non-fatally even when the
  archive contains dSYMs and App Store Connect later processes the build.
- Added `ios/ExportOptions.app-store-nosymbols.plist` with the same App Store
  Connect export settings but `uploadSymbols=false`.
- Added `scripts/export_ios_appstore_no_apple_symbols.sh` to export/upload an
  existing `.xcarchive` with the tracked plist.
- Documented the release path in `docs/ios_app_store_export.md`, including ASC
  validation and manual Crashlytics dSYM upload if needed.
- Verification: `plutil -lint` passed, `sh -n` passed, `/opt/homebrew/bin/flutter
  analyze` passed, and `/opt/homebrew/bin/flutter test` passed with the
  feed-flow integration test skipped for missing Supabase env vars.

## Review (2026-05-22 Calendar Day-Sheet Invisible Photos)
- Symptom: calendar previews (grid cells, latest/recent cards) showed photos,
  but tapping a day opened the day sheet where all photos were invisible.
- Root cause: `_MemoryDaySheet` thumbnails pass `width: double.infinity,
  height: 200` to `CachedNetworkImageView`. With the default
  `relativeZoom` mode + both dims non-null, `_PortraitAwareImage` entered the
  circular-avatar framing path; `_safeViewport` clamped the infinite width to
  `1.0`, so `_baseImageSizeForContain` produced a ~1px image (effectively
  blank). Preview cards pass no width/height, so they skipped that branch.
- Fix: extracted the branch decision into `shouldUseAvatarFraming(...)` in
  `lib/shared/ui/cached_network_image_view.dart`, now requiring `width`/`height`
  to be FINITE. Non-finite dims fall through to the plain `BoxFit` path that
  honors the caller's `fit` (full-width letterbox). Zero impact on legitimate
  finite-size avatar callers (e.g. `home_latest_photo_card`, `user_avatar`).
- Tests: added `shouldUseAvatarFraming` unit tests (infinite w/h → no framing;
  finite → framing; legacyAbsolute/null → no framing). Verified they fail
  against the pre-fix predicate. `flutter analyze` clean, `flutter test` green
  (431 pass, feed-flow integration skipped for missing Supabase env vars).

## Review (2026-05-21 Recall Sent Photo)
Recall = soft-delete the sender's own `image_feed` photo. Tombstone in chat,
gone from home feed. NO coin claw-back, NO pet un-feed. Recallable anytime by
the sender. Surfaces: chat + home feed.

- Server: migration `20260521104158_delete_message_allow_image_feed` extends
  `delete_message` to `type in ('text','image_feed')`; image_feed recall also
  nulls `image_url` + `caption` (keeps `coins_awarded`). Owner + active-member
  guard, SECURITY DEFINER, `search_path=''` preserved; `edit_message` untouched.
  Applied via MCP after verifying the live def + project ref; file saved to
  `supabase/migrations/`.
- Backward-compat: recalled image_feed has null `image_url`; old home feed
  queries already filter `.not(image_url,is,null)`, old chat clients fall back
  to a grey placeholder card (no crash). Accepted by user.
- Adapter (`pet_chat_message_adapter`): deleted check now precedes the
  image_feed branch in `toUiMessage` + both preview helpers, so a recalled
  photo shows the tombstone.
- Chat: `_deleteMessage` accepts image_feed (optimistic clears
  image/caption/local-path + sets deletedAt/By); `ChatMessage.copyWith` gained
  `clearImageUrl/clearCaption/clearLocalImagePath`. Action sheet splits
  `canEdit` (text) vs `canDelete` (text|image_feed); confirm dialog uses
  photo-specific copy.
- Home: `PhotoViewerItem.senderId` added; `FullScreenPhotoViewer` gained
  `onDeletePhoto` + `currentUserId` and a recall button shown only on the
  user's own photo (with confirm). `PetPhotoGallery` threads `senderIds`,
  `onPhotoRecalled`, and a null-safe current-user read; recall reuses
  `delete_message`. Home drops the photo locally
  (`PetHomeGalleryFeedData.removeByMessageId`) and via a new `messages` UPDATE
  realtime handler so other members refresh.
- l10n: added `feedRecallPhotoAction/Title/Confirm/Failed` in
  en/ja/ko/zh/zh_TW; regenerated.
- Tests: adapter tombstone for recalled photo, viewer recall visibility +
  forwarding, `removeByMessageId`. `flutter analyze` clean; `flutter test`
  426 passed / 1 skipped; `dart format` applied.

## Review (2026-05-21 Multi-Pet Equipment & Hunger Fixes)
- Equipping onto an extra pet failed with RLS 42501: `pet_equipment`
  INSERT/UPDATE `WITH CHECK` only validated `pets`. Migration
  `pet_equipment_policies_allow_extra_pets` (live `20260521013422`) now allows
  `pets` OR `room_extra_pets`.
- Reading/removing an extra pet's gear raised `pet_not_found`: the two-arg
  `get_pet_equipment` and `unequip_pet_item` only checked `pets`. Migration
  `equipment_rpcs_allow_extra_pets` (live `20260521014910`) validates both
  tables. Fixed the blank dress-up preview and the locked/un-removable item
  when selecting the pet actually wearing it.
- `equipment_copy_unavailable` UX: home_view tracks per-item room quantity
  (`_ownedEquipmentQtyById`) + `_availableEquipmentCopies`; the panel dims and
  locks items whose copies are all worn by other pets (label
  `equipmentCopyInUse`), and the equip RPC error falls back to a friendly
  `equipmentCopyUnavailable` snackbar. Added a panel test + 5-language ARB keys.
- Room-selection preview gear is now scoped to each room's `main_pet_id`
  (`_fetchRoomEquippedSkus`), so it matches the actual main pet after a switch
  instead of a last-write-wins mix of all pets.
- Spurious low-hunger alert on main-pet switch (chat msg + toast + push):
  `set_room_main_pet` re-materialized the promoted pet's `pet_state` at default
  hunger 100 then synced down, which `handle_pet_hunger_alerts` read as a fresh
  downward crossing. Migration `suppress_hunger_alert_on_main_pet_swap` (live
  `20260521020952`) gates that trigger behind `app.skip_hunger_alerts` set
  around the swap sync.
- Feed-then-switch reverted hunger: the client feed (`apply_pet_action`) only
  wrote `pet_state`, so the swap synced a stale `room_pet_state`. Migration
  `apply_pet_action_mirrors_room_pet_state` (live `20260521022742`) mirrors the
  action result into `room_pet_state`, matching `tick_pet_state`.
- Verification: `flutter analyze` passed; equipment/home widget tests passed;
  live function/policy definitions verified via MCP.

## Plan (2026-05-21 Room Hunger Freeze)
- [x] Read active memory-bank files and Supabase SQL guidance.
- [x] Add an additive, room-scoped, expiring Supabase debug override for hunger
  decay.
- [x] Update tick/schedule RPC behavior so frozen rooms do not decay or build up
  catch-up decay when unfrozen.
- [x] Add debug-admin Flutter controls for freezing/unfreezing the active room
  and refreshing state.
- [x] Add focused regression coverage and run `flutter analyze` /
  `flutter test`.

## Review (2026-05-21 Room Hunger Freeze)
- Added local migration
  `20260521143000_add_room_hunger_freeze_debug_override.sql` with
  `room_debug_overrides`, `is_debug_admin()`, and
  `set_room_hunger_decay_paused(...)`.
- Updated `tick_pet_state` so active freezes keep hunger unchanged while
  advancing `last_decay_at`, and updated `compute_pet_hunger_next_check_at` so
  the server schedule sleeps until the freeze expiry.
- Added debug drawer actions to freeze the active room's hunger for one year or
  restore normal decay, then refresh the active pet state.
- Added `room_hunger_freeze_migration_test.dart` to lock the SQL invariants.
- Verification: focused migration test passed; `flutter analyze` passed;
  `flutter test` passed with `feed_flow_integration_test.dart` skipped for
  missing Supabase env vars.
- Live apply status: applied to Supabase project `ilxzpszgirhwxpeocygs`
  through MCP as migration `20260521021312 add_room_hunger_freeze_debug_override`.
  Sanity checks confirmed the debug table/RPCs exist, `tick_pet_state` checks
  the freeze override and advances `last_decay_at`, and
  `compute_pet_hunger_next_check_at` returns the freeze expiry for paused rooms.
- Follow-up fix: live RPC hit Postgres 42702 because
  `set_room_hunger_decay_paused(...) returns table (room_id ...)` made
  `on conflict (room_id)` ambiguous between the output variable and table
  column. Added/applied migration
  `20260521021817 fix_room_hunger_freeze_room_id_conflict`, rewriting the
  upsert to `on conflict on constraint room_debug_overrides_pkey do update`.

## Plan (2026-05-19 Home Multi-Pet Rendering)
- [x] Read active memory-bank files and UI guidance.
- [x] Confirm backend `get_room_pets` exists but Home rendering still only uses
  one `_petId/_petType`.
- [x] Load room pet lists in Home and refresh them after returning from Shop.
- [x] Render non-main room pets in the room scene without changing the main-pet
  interaction model.
- [x] Add focused regression coverage and rerun `flutter analyze` /
  `flutter test`.

## Review (2026-05-19 Home Multi-Pet Rendering)
- Root cause: Home still had a single `_petId` / `_petType` rendering path.
  Even though the backend can now return multiple pets through `get_room_pets`,
  the room scene only drew the representative main pet.
- Added Home room-pet loading through `get_room_pets`, cached by room id, and
  refreshed it during pet-state refreshes, room switches, and after returning
  from Shop.
- Rendered non-main room pets as visual-only companions in the Home room scene,
  while keeping feed/status/equipment interactions tied to the current main pet.
- Added focused source regression coverage for the Home multi-pet query and
  rendering path.
- Remaining scope: main-pet switcher UI and per-pet equipment target selection
  are still pending.
- Verification: `flutter analyze` passed; `flutter test` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.

## Plan (2026-05-19 Post-Pet-Purchase 406)
- [x] Read active memory-bank files and locate multi-pet `.single()` /
  `.maybeSingle()` assumptions.
- [x] Identify Home `_loadPetId(roomId)` as the post-purchase 406 source.
- [x] Resolve room pet id through `rooms.main_pet_id` with a deterministic
  fallback instead of querying `pets` by `room_id` as one row.
- [x] Add focused regression coverage and rerun `flutter analyze` /
  `flutter test`.

## Review (2026-05-19 Post-Pet-Purchase 406)
- Root cause: Home still resolved the current pet with
  `pets.eq('room_id', roomId).maybeSingle()`. After a successful pet-ticket
  purchase, the room legitimately has 2+ pet rows, so PostgREST returned 406
  for the object-shaped request.
- Fixed `_loadPetId(roomId)` to read `rooms.main_pet_id` first and fall back to
  the first room pet ordered by `created_at, id` only when the room has no main
  pet id.
- Added a focused Home multi-pet query regression test.
- Verification: `flutter analyze` passed; `flutter test` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.

## Plan (2026-05-19 Pet Ticket Purchase Failure)
- [x] Read active memory-bank files, lessons, and Supabase SQL guidance.
- [x] Confirm the failing path is the v2.0.0 pet-ticket purchase RPC.
- [x] Add a forward Supabase migration that removes the `pet_id` PL/pgSQL
  ambiguity without changing RPC signatures.
- [x] Apply the migration to the intended PetTomo Supabase project.
- [x] Add focused regression coverage and run `flutter analyze` /
  `flutter test`.

## Review (2026-05-19 Pet Ticket Purchase Failure)
- Root cause: `use_pet_ticket` and `purchase_and_use_pet_ticket` return a
  column named `pet_id`, which becomes a PL/pgSQL output variable. Their
  `insert into public.pet_state ... on conflict (pet_id)` clauses therefore
  conflicted with `pet_state.pet_id` at runtime.
- Added and applied live migration
  `fix_pet_ticket_pet_id_conflict` (live version `20260519002602`), rewriting
  both RPCs to use `on conflict on constraint pet_state_pkey do nothing` while
  keeping the same parameters and return tables.
- Verified live function definitions no longer contain
  `on conflict (pet_id)` and both contain the fixed constraint conflict target.
- Added a focused migration regression test.
- Verification: `flutter analyze` passed; `flutter test` passed with
  `test/feed_flow_integration_test.dart` skipped for missing Supabase env vars.

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
## Plan (2026-05-21 V2.0.0 Release Notes)
- [x] Read release-notes workflow, active memory-bank files, current app version,
  existing What's New catalog, ASC localization files, and recent git history.
- [x] Draft localized ASC and bundled What's New copy for approval.
- [x] Add approved V2.0.0 bundled What's New entries and localization keys.
- [x] Update local ASC version localization `.strings` files.
- [x] Run localization generation, analyzer, and tests.
- [x] Record results and ASC sync.

## Review (2026-05-21 V2.0.0 Release Notes)
- Added bundled What's New entry `2.0.0` with localized copy in
  `app_whats_new_catalog.dart` and `lib/l10n/app_*.arb`, then regenerated
  Flutter localization files.
- Updated local ASC version localization files for `en-US`, `ja`, `ko`, and
  `zh-Hant` with V2.0.0 `promotionalText` and `whatsNew`.
- Created App Store Connect version `2.0.0` for app `6757725650` by copying
  metadata from `1.4.0`; new version ID:
  `1fc934d6-90c8-4b94-802c-e35d0c5e0230`.
- Uploaded and verified ASC localizations:
  `en-US`, `ja`, `ko`, `zh-Hant`.
- Verification:
  `flutter gen-l10n` passed via `/opt/homebrew/bin/flutter` with pre-existing
  untranslated-message notices for `ko` and `zh_TW`,
  `git diff --check` passed,
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped
  for missing Supabase env vars.

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
