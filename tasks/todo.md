# TODO

# Plan (2026-04-24 App-wide PNG Sequence Rendering)
- [x] Add bundled PNG sequences for every current pet animation state without removing existing GIF assets.
- [x] Route app pet rendering through the sequence renderer so GIFs become fallback-only during the migration.
- [x] Update focused tests, memory notes, and run Flutter verification.

# Review (2026-04-24 App-wide PNG Sequence Rendering)
- [x] Implemented.
- Scope:
  - Added 128 bundled PNG sequence frames for ghost, cat, fish, and tiger stay/sleep/walk states under `assets/pet_sequences/`.
  - Added a source-GIF-to-frame-sequence catalog with per-frame duration sampling, plus reusable `PetAnimationFrameBuilder` / `PetAnimatedImage` widgets.
  - Migrated Home pet rendering, room selection avatars, chat menu avatars, room inventory previews, and pet selection cards to the sequence renderer while keeping GIF assets and legacy debug tooling in place for the migration window.
- Verification:
  - `dart format lib/features/pet/pet_animation_frames.dart lib/features/pet/pet_animated_image.dart lib/features/home/home_view.dart lib/features/home/widgets/home_room_inventory_panel.dart lib/features/home/room_selection_view.dart lib/features/chat/chat_room_view_v2.dart lib/features/pet/pet_selection_page.dart test/features/pet/pet_animation_frames_test.dart`
  - `flutter analyze`: passed.
  - `flutter test test/features/pet/pet_animation_frames_test.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/widgets/pet_equipment_layout_test.dart test/features/home/widgets/home_room_inventory_panel_test.dart test/features/home/room_selection_view_test.dart`: passed.
  - `flutter build bundle`: passed; the bundle includes the new PNG sequence assets.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-24 Variable Frame Duration Socket Workflow)
- [x] Extend the Godot socket authoring add-on so each frame can capture/export/load duration metadata and preview playback uses that timing.
- [x] Make Flutter pet PNG sequences and socket motion tracks duration-aware while preserving the current ghost behavior.
- [x] Add focused tests, update current-state docs, and run Flutter verification.

# Review (2026-04-24 Variable Frame Duration Socket Workflow)
- [x] Implemented.
- Scope:
  - Added a `Duration ms` control to the Godot Socket Authoring dock; capture/load/export now preserves per-frame durations.
  - Godot exports both a compatibility `frameDurationsMs` array and a richer `frames[]` schema with `image`, `durationMs`, and per-frame sockets; preview playback uses each frame's duration.
  - Flutter `PetFrameSequence` and `PetMotionTrack` now support cumulative duration sampling, while ghost idle keeps the same 2600 ms loop and visual behavior.
  - Bumped the Godot add-on to `0.4.0`.
- Verification:
  - `dart format lib/features/pet/pet_animation_frames.dart lib/features/pet/pet_sockets.dart lib/features/home/home_view.dart lib/features/home/debug/dress_up_fit_tool_page.dart test/features/pet/pet_animation_frames_test.dart test/features/pet/pet_socket_config_test.dart`
  - `flutter test test/features/pet/pet_animation_frames_test.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/widgets/pet_equipment_layout_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter test`: passed.
  - Godot CLI is not installed on this machine, so the add-on changes were statically inspected and still need runtime reload in the Godot editor.

# Plan (2026-04-24 Godot Equipment Anchor Parity)
- [x] Compare the Godot equipment preview transform with Flutter overlay placement.
- [x] Apply the Godot-authored straw hat anchor/size using aspect-preserving Flutter sizing.
- [x] Add focused coverage, update memory notes, and run Flutter verification.

# Review (2026-04-24 Godot Equipment Anchor Parity)
- [x] Implemented.
- Diagnosis:
  - Godot preview scaled equipment by width while preserving the PNG source aspect ratio.
  - Flutter used the catalog's independent `w` / `h` layout box and then `BoxFit.contain`; when that box did not match the PNG aspect ratio, the anchor was computed against invisible padding.
  - The app catalog still had older straw hat values instead of the Godot export's `anchor: 0.5,0.55` and width ratio `0.8`.
- Scope:
  - Added aspect-preserving equipment sizing via `EquipmentSize.fromWidthAspect(...)`.
  - Updated `equip_straw_hat` to match the latest Godot preview metadata and the straw hat PNG aspect ratio.
  - Added focused tests covering the aspect sizing math and catalog values.
- Verification:
  - `dart format lib/features/pet/equipment_catalog.dart test/features/home/widgets/pet_equipment_layout_test.dart`
  - `flutter test test/features/home/widgets/pet_equipment_layout_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/pet/pet_animation_frames_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter test`: passed.

# Plan (2026-04-24 Ghost Equipped PNG Sequence Rendering)
- [x] Add a small pet frame-sequence catalog/helper for the ghost idle PNG frames.
- [x] Switch Home pet rendering to the PNG sequence only for ghost idle with equipped items, keeping GIF rendering for all other states.
- [x] Add focused tests, update current-state docs, and run required Flutter verification.

# Review (2026-04-24 Ghost Equipped PNG Sequence Rendering)
- [x] Implemented.
- Scope:
  - Added a ghost idle frame-sequence helper that maps animation progress onto the 13 PNG source frames with the existing hold-2 cadence.
  - Switched Home to use the PNG sequence only when ghost idle has equipped items, keeping GIF playback for unequipped ghost and all other pets/states.
  - Explicitly listed ghost assets in `pubspec.yaml` so the bundle includes the runtime GIF/PNG files without pulling in authoring-only files from nested folders.
- Verification:
  - `dart format lib/features/pet/pet_animation_frames.dart lib/features/home/home_view.dart test/features/pet/pet_animation_frames_test.dart`
  - `flutter test test/features/pet/pet_animation_frames_test.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter build bundle`: passed; manifest contains the 13 ghost idle PNG frames and no ghost authoring files.
  - `flutter test`: passed.

# Plan (2026-04-24 Godot Preview Live Controls)
- [x] Wire equipment slot, anchor, size, canvas, and path controls to update the preview immediately.
- [x] Include equipment preview metadata in exported JSON and restore it on JSON load.
- [x] Bump the add-on version and statically verify the script.

# Review (2026-04-24 Godot Preview Live Controls)
- [x] Implemented.
- Scope:
  - Connected equipment slot, anchor X/Y, size, canvas width/height, and PNG path controls to refresh `EquipmentPreview` immediately.
  - Added `equipmentPreview` metadata to socket JSON export with asset path, slot, anchor, and size ratio.
  - Added JSON load support for restoring the saved preview metadata and bumped the add-on to `0.3.0`.
- Verification:
  - Static inspection of `/Users/fatboy/pet-tomo/addons/socket_authoring/socket_authoring_dock.gd` passed.
  - Godot CLI is not available from the shell, so reload the plugin in Godot to validate the editor UI.

# Plan (2026-04-24 Godot Equipment Preview)
- [x] Extend the Socket Authoring dock with an equipment preview sprite that can load a PNG asset.
- [x] Add playback using captured/exported socket frames so the equipment follows the selected marker during review.
- [x] Verify the plugin statically and record how to use the preview.

# Review (2026-04-24 Godot Equipment Preview)
- [x] Implemented.
- Scope:
  - Added `Load JSON` so the dock can restore captured socket frames from `ghost_stay_sockets.json` after restarting Godot.
  - Added equipment preview controls for PNG path, slot, anchor, and size.
  - Added `Load`, `Play`, and `Stop`; playback advances `AnimatedSprite2D.frame`, reapplies captured marker positions, and positions a transient `EquipmentPreview` sprite on the selected socket.
- Verification:
  - Static inspection of `/Users/fatboy/pet-tomo/addons/socket_authoring/socket_authoring_dock.gd` passed.
  - Godot CLI is not available from the shell, so final validation should be done in the open Godot editor.

# Plan (2026-04-24 Apply Godot Ghost Socket Export)
- [x] Convert `/Users/fatboy/pet-tomo/pet/ghost/ghost_stay_sockets.json` into Flutter `PetSocketCatalog` values.
- [x] Update focused socket tests and current-state memory notes for the Godot-authored ghost idle anchors.
- [x] Run formatting plus focused tests, then record verification.

# Review (2026-04-24 Apply Godot Ghost Socket Export)
- [x] Implemented.
- Scope:
  - Applied the Godot export's frame-0 normalized positions to ghost `head`, `body`, and `back` base sockets in `PetSocketCatalog`.
  - Converted the exported ghost head frames into a stepped, hold-2 motion delta track relative to frame 0.
  - Updated socket, overlay, and Dress-up Fit Tool tests plus active memory-bank notes.
- Verification:
  - `dart format lib/features/pet/pet_sockets.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/debug/dress_up_fit_tool_page_test.dart`
  - `flutter test test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/debug/dress_up_fit_tool_page_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-24 Godot Socket Authoring Plugin)
- [x] Add an editor dock plugin for capturing current frame socket marker positions without manually copying coordinates.
- [x] Support previous/next frame navigation and JSON export with pixel plus normalized socket coordinates.
- [x] Verify plugin files statically and document how to enable/use it without overwriting the currently dirty scene.

# Review (2026-04-24 Godot Socket Authoring Plugin)
- [x] Implemented.
- Scope:
  - Added `/Users/fatboy/pet-tomo/addons/socket_authoring/` with an enabled Godot editor plugin.
  - The dock reads the currently edited scene's `AnimatedSprite2D`, `HeadSocket`, `BodySocket`, and `BackSocket`; supports `Prev`, `Next`, `Capture`, `Refresh`, and `Export JSON`.
  - JSON export writes beside the scene as `ghost_stay_sockets.json`, including pixel `x/y` and normalized `nx/ny` values for every frame.
- Verification:
  - Static inspection of plugin files and `project.godot` passed.
  - Godot CLI is not available from the shell, and the scene is currently dirty in the open editor, so runtime plugin validation should happen after saving/reloading the project in Godot.

# Plan (2026-04-24 Godot Ghost Socket Authoring Fix)
- [x] Normalize the Godot ghost socket preview around PNG top-left coordinates so authored points match the Flutter catalog contract.
- [x] Add the missing `BackSocket` node and script handling so all current equipment slots have visible markers.
- [x] Verify the Godot scene/script text state and record the outcome here.

# Review (2026-04-24 Godot Ghost Socket Authoring Fix)
- [x] Implemented.
- Scope:
  - Updated `/Users/fatboy/pet-tomo/pet/ghost/ghost_stay.tscn` so `AnimatedSprite2D.centered = false`, the idle preview speed is `5.0`, and `BackSocket` exists in the scene.
  - Updated `/Users/fatboy/pet-tomo/pet/ghost/ghost_stay.gd` so head/body/back markers are driven from frame-indexed socket arrays using PNG top-left coordinates, and the script prints normalized `Offset(...)` values for Flutter handoff.
- Verification:
  - Static scene/script inspection passed.
  - Godot CLI was not available from the shell, so runtime validation still needs the open Godot editor to reload the externally changed files.

# Plan (2026-04-23 Ghost Head Timing Sync)
- [x] Align ghost head motion timing with the exported GIF cadence by holding each authored point for two logical frames.
- [x] Switch ghost head motion sampling to stepped playback and update idle loop durations in both production and the fit tool preview.
- [x] Refresh focused tests plus required `flutter analyze` / `flutter test`, then record the result here.

# Review (2026-04-23 Ghost Head Timing Sync)
- [x] Implemented.
- Scope:
  - Added a repeat helper plus explicit stepped sampling mode to `PetMotionTrack`, then switched the ghost `head` motion track to hold each authored point for two logical frames instead of smoothing between marks.
  - Updated the ghost idle motion loop in both `HomeView` and the Dress-up Fit Tool preview from `1820 ms` to `2600 ms` so overlay playback matches the exported GIF cadence more closely.
  - Adjusted focused ghost motion tests to assert the new held-frame behavior and overlay placement at the repeated-frame boundary.
- Verification:
  - `dart format lib/features/pet/pet_sockets.dart lib/features/home/home_view.dart lib/features/home/debug/dress_up_fit_tool_page.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart`
  - `flutter analyze`: passed.
  - `flutter test test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/debug/dress_up_fit_tool_page_test.dart`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-23 Ghost Head Anchor Trial Apply)
- [x] Apply the manually authored ghost `head` socket data as a production trial without changing unfinished `body` / `back` behavior.
- [x] Make idle motion sampling slot-aware so only the calibrated head uses the new manual track for now.
- [x] Update focused tests plus required `flutter analyze` / `flutter test`, then record the result here.

# Review (2026-04-23 Ghost Head Anchor Trial Apply)
- [x] Implemented.
- Scope:
  - Replaced the ghost `head` socket base position with the manually authored Krita trial data from `docs/templates/ghost_anchor_trial.template.json`, while leaving `body` and `back` on their previous production values.
  - Extended `PetSocketConfig.resolveMotion(...)` to support slot-aware idle motion lookup, then attached the authored motion track only to the ghost `head` slot so uncalibrated slots do not inherit the same drift.
  - Wired both production overlays and the Dress-up Fit Tool preview through the slot-aware lookup, keeping the trial behavior consistent anywhere ghost equipment placement is rendered.
- Verification:
  - `dart format lib/features/pet/pet_sockets.dart lib/features/home/widgets/pet_equipment_overlay.dart lib/features/home/debug/dress_up_fit_tool_page.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/home/debug/dress_up_fit_tool_page_test.dart`
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-23 Krita Anchor Authoring Trial)
- [x] Verify whether Krita is available locally and install it if needed.
- [x] Define a minimal manual anchor-calibration workflow for the existing ghost stay PNG sequence.
- [x] Add a short repo doc so the workflow can be repeated before investing in a bigger asset pipeline.
- [x] Run doc-change verification and record the outcome here.

# Review (2026-04-23 Krita Anchor Authoring Trial)
- [x] Implemented.
- Scope:
  - Confirmed Krita was not present locally, installed it via Homebrew cask, and launched it so the free-tool trial can start immediately on this machine.
  - Added `docs/krita-anchor-authoring-trial.md` with a minimal manual workflow scoped to `assets/pet/ghost/ghost_stay/` rather than a full pipeline redesign.
  - Added `docs/templates/ghost_anchor_trial.template.json` so frame-by-frame socket coordinates can be recorded in one stable handoff format for later conversion into Flutter data.
- Verification:
  - `python3 -m json.tool docs/templates/ghost_anchor_trial.template.json >/dev/null`
  - `git diff --check`

# Plan (2026-04-23 Ghost Equipment Anchor Drift)
- [x] Trace the ghost pet visual/equipment rendering path and identify why equipment anchors stay fixed while the idle GIF drifts internally.
- [x] Add a scoped overlay motion mechanism so equipment placement can follow ghost idle drift without changing existing static socket math for other pets/states.
- [x] Add regression coverage for ghost idle equipment motion and update compact memory/task notes if the current behavior contract changes.
- [x] Run formatting, `flutter analyze`, and `flutter test`, then record the review summary here.

# Review (2026-04-23 Ghost Equipment Anchor Drift)
- [x] Implemented.
- Scope:
  - Measured the provided ghost idle PNG sequence under `assets/pet/ghost/ghost_stay/` and derived a 13-frame normalized motion track from the sprite's real in-canvas drift instead of approximating from static socket tweaks alone.
  - Extended `PetSocketConfig` with optional idle motion tracks and sampled that motion only for non-walking/non-sleeping states, so existing static socket math remains unchanged for other pets and states.
  - Added a looping ghost idle overlay animation in `HomeView` and passed the sampled motion into `PetEquipmentOverlay`, so equipment anchors now follow the ghost's subtle idle drift in both the main pet view and status avatar rendering.
  - Updated focused tests to cover the current ghost socket overrides plus the new PNG-derived idle overlay motion.
- Verification:
  - `dart format lib/features/pet/pet_sockets.dart lib/features/home/widgets/pet_equipment_overlay.dart lib/features/home/home_view.dart test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart`
  - `flutter test test/features/pet/pet_socket_config_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-23 Photo Viewer Swipe Safety)
- [x] Trace the full-screen photo viewer gesture path and confirm why horizontal swipes can trigger vertical dismiss motion.
- [x] Tighten the dismiss gesture arbitration so the viewer only starts vertical drag/dismiss after clear vertical intent, leaving left/right paging with more tolerance.
- [x] Add regression coverage for horizontal, diagonal, and vertical swipe behavior in the full-screen photo viewer.
- [x] Run formatting, `flutter analyze`, and `flutter test`, then record the review summary here.

# Review (2026-04-23 Photo Viewer Swipe Safety)
- [x] Implemented.
- Scope:
  - Reworked `FullScreenPhotoViewer` swipe-to-dismiss tracking so raw pointer movement stays idle until the gesture shows clear vertical intent instead of reacting immediately to any small `dy`.
  - Biased the arbitration toward horizontal paging by rejecting dismiss earlier for horizontal-dominant drags and requiring a larger vertical lead before the viewer starts moving/fading.
  - Added regression tests that verify a slightly diagonal left/right swipe does not start dismiss motion and that a clearly vertical swipe still dismisses the viewer.
- Verification:
  - `dart format lib/shared/ui/full_screen_photo_viewer.dart test/full_screen_photo_viewer_test.dart`
  - `flutter test test/full_screen_photo_viewer_test.dart`: passed.
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-23 Dress-Up Fit Tool Implementation)
- [x] Add shared pet equipment placement math and wire production overlays through it.
- [x] Add local per-pet equipment fit override support without changing current catalog behavior.
- [x] Build the admin-only Dress-up Fit Tool page with preview, controls, resets, and copyable snippets.
- [x] Add a debug-admin drawer entry and minimal localized labels.
- [x] Add focused layout, overlay, catalog, and fit-tool widget tests.
- [x] Run formatting, l10n generation, analyzer, and tests; record the review summary here.

# Review (2026-04-23 Dress-Up Fit Tool Implementation)
- [x] Implemented.
- Scope:
  - Added shared equipment placement math and updated `PetEquipmentOverlay` to use it for both normal rendering and per-pet fit overrides.
  - Added the debug-admin-only Dress-up Fit Tool page with pet/equipment/state/facing/layer controls, live markers/bounds, slider/stepper tuning, reset actions, and copyable Dart snippets.
  - Added the Home drawer entry plus EN/JA/ZH localization and regenerated Flutter l10n outputs; existing `ko` and `zh_TW` untranslated warnings remain.
  - Kept the tool local-only: no Supabase schema, RPC, remote config, upload, or production data writes.
- Verification:
  - `flutter gen-l10n`: passed; existing `ko` and `zh_TW` untranslated-message warnings remain.
  - `dart format ...`: passed on touched files.
  - Focused tests passed: `flutter test test/features/home/widgets/pet_equipment_layout_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/pet/equipment_catalog_test.dart test/features/pet/pet_socket_config_test.dart test/features/home/debug/dress_up_fit_tool_page_test.dart test/features/home/widgets/home_room_inventory_panel_test.dart`
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-23 Dress-Up Fit Tool Handoff Plan)
- [x] Read current memory-bank state and dress-up/debug-admin context.
- [x] Add a detailed handoff plan under `docs/` for the admin-only visual equipment fitting tool.
- [x] Record scope, phases, tests, non-goals, and next-agent checklist.
- [x] Run documentation-change verification and record results here.

# Review (2026-04-23 Dress-Up Fit Tool Handoff Plan)
- [x] Implemented.
- Scope:
  - Added `docs/dressup-fit-tool-implementation-plan.md` as the next-session handoff spec for an admin-only visual equipment fitting tool.
  - Covered manager workflow, UI spec, layout math extraction, local draft state, generated Dart snippets, implementation phases, tests, non-goals, and future remote-dashboard considerations.
  - Kept this as documentation/planning only; no app behavior changed.
- Verification:
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-22 Pet Dress-Up MVP v1.3.0)
- [x] Verify the current dress-up touchpoints in Home, inventory, shop, assets, and release metadata.
- [x] Add Supabase support for pet equipment: table, RLS, realtime publication, RPCs, and seeded live hat item with `min_app_version = 1.3.0`.
- [x] Update store purchase compatibility so version-gated shop-visible cosmetic items remain purchasable with coins.
- [x] Implement Flutter equipment catalogs, pet socket rendering, Home realtime/state flows, and the Equipment inventory tab.
- [x] Extend shop models/UI/localization/assets for the live hat rollout and keep the app release target at `1.3.0+1`.
- [x] Add focused tests, update active memory-bank docs, run `flutter analyze`, `flutter test`, and `flutter build bundle`, then record the review summary here.

# Review (2026-04-23 Pet Dress-Up MVP v1.3.0)
- [x] Implemented.
- Scope:
  - Verified the current dress-up branch had already completed most Flutter work: equipment/socket catalogs, pet overlay rendering in Home + status avatar, Equipment inventory tab in the shared room panel, Shop section/category wiring, localizations, and the `1.3.0+1` app version bump.
  - Confirmed through Supabase MCP that the repo-target project `ilxzpszgirhwxpeocygs` already had live migration `20260422150216_add_pet_equipment` applied, including `pet_equipment`, its RLS/realtime publication, `equip_pet_item` / `unequip_pet_item` / `get_pet_equipment`, seeded `equip_straw_hat`, and the version-gated `purchase_item_with_coins` fix.
  - Added the missing local migration file `supabase/migrations/20260422150216_add_pet_equipment.sql` so the repo matches the live backend state instead of drifting from it.
  - Added focused regression coverage for `PetEquipmentOverlay`, `PetSocketCatalog`, and `EquipmentCatalog`, regenerated Flutter `l10n` so the new equipment strings compile, and made Shop purchase-success notices render equipment assets.
  - Updated active memory-bank docs to record the dress-up architecture, schema contracts, and rollout state.
- Verification:
  - `dart format lib/features/home/home_view.dart lib/features/home/controllers/home_room_manager.dart lib/features/home/home_view_models.dart lib/features/home/widgets/home_room_inventory_panel.dart lib/features/home/widgets/pet_equipment_overlay.dart lib/features/pet/equipment_catalog.dart lib/features/pet/pet_sockets.dart lib/features/shop/models/shop_item.dart lib/features/shop/shop_item_localization.dart lib/features/shop/shop_view.dart lib/features/shop/widgets/shop_item_cards.dart lib/features/shop/widgets/shop_item_visual.dart test/features/home/widgets/home_room_inventory_panel_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/pet/equipment_catalog_test.dart test/features/pet/pet_socket_config_test.dart`
  - `flutter gen-l10n`: passed; existing `ko` and `zh_TW` untranslated-message warnings remain.
  - Focused tests passed: `flutter test test/features/home/widgets/home_room_inventory_panel_test.dart test/features/home/widgets/pet_equipment_overlay_test.dart test/features/pet/equipment_catalog_test.dart test/features/pet/pet_socket_config_test.dart`
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`.
  - `flutter build bundle`: passed.

# Plan (2026-04-22 Multi-Room Memory Pressure Hardening)
- [x] Trace the current room-switch, image-cache, and diagnostics hooks relevant to low-memory multi-room usage.
- [x] Add an iOS native memory-warning bridge into Flutter and record Crashlytics + memory snapshot context when it fires.
- [x] Tighten image cache policy and add room-switch-time cache trimming plus room-count/index diagnostics.
- [x] Add focused regression coverage and update memory-bank notes.
- [x] Run `flutter analyze` and `flutter test`, then record the review summary and verification results here.

# Review (2026-04-22 Multi-Room Memory Pressure Hardening)
- [x] Implemented.
- Scope:
  - Added an iOS native memory-warning bridge in `ios/Runner/AppDelegate.swift` and a Flutter-side `SystemMemoryPressureService` so native low-memory warnings are captured by the existing Crashlytics + memory diagnostics pipeline before a possible jetsam kill.
  - Exposed the current Crashlytics route/feature/room context so the memory-warning handler can stamp room-aware custom keys and snapshots instead of logging a generic app-level event.
  - Reduced the global Flutter image-cache budget from `150 / 192 MB` to `120 / 128 MB` and added high-water-mark room-switch trimming (`soft_trim` / `hard_trim`) through `MemoryDiagnosticsService`.
  - Added room-switch custom keys (`room_count`, `selected_room_index`, `room_switch_from`, `room_switch_to`, `room_switch_entry_loading`) plus richer room-switch memory snapshot notes to improve future triage for the hard-to-reproduce fourth-room crash.
  - Updated active memory-bank docs with the new multi-room memory-pressure hardening behavior.
- Verification:
  - `dart format lib/main.dart lib/services/crash/crash_reporting_service.dart lib/services/performance/memory_diagnostics_service.dart lib/services/performance/system_memory_pressure_service.dart lib/features/home/controllers/home_room_manager.dart test/services/performance/memory_diagnostics_service_test.dart test/services/performance/system_memory_pressure_service_test.dart`
  - `flutter analyze`: passed.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-22 Chat Long-Press Overlay Collision Avoidance)
- [x] Trace why the long-press options card can overlap the selected message preview on taller preview content.
- [x] Replace height estimation in the action-sheet layout with measured child sizing so the rail, preview, and options card stack without collision.
- [x] Add focused regression coverage for tall preview content and rerun required verification.
- [x] Record the review summary and verification results here.

# Review (2026-04-22 Chat Long-Press Overlay Collision Avoidance)
- [x] Implemented.
- Scope:
  - Traced the overlap to the action sheet positioning the options card from `anchor.messageRect.height` instead of the preview widget's real laid-out height.
  - Switched the overlay stack to measured rail/preview/card sizing in `CustomMultiChildLayout`, so the whole vertical stack shifts together using actual child heights.
  - Updated the top clamp logic to reserve space for the options card as well, which keeps Edit/Delete reachable when the pressed message sits low in the viewport.
  - Added a focused tall-preview regression test proving the options card stays below the selected message preview without overlap.
- Verification:
  - `dart format lib/features/chat/widgets/chat_message_action_sheet.dart test/features/chat/chat_message_action_sheet_test.dart`
  - `flutter test test/features/chat/chat_message_action_sheet_test.dart`: passed.
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "editing own text message updates body and edited marker"`: passed.
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "deleting own text message renders deleted placeholder"`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-22 Chat Long-Press Overlay Refinement)
- [x] Inspect the current `ChatMessageActionSheet` overlay/animation path and restore a Telegram-like focused long-press presentation.
- [x] Add animated background blur + softer scrim and tune motion timing/translation so the selected message, reaction rail, and actions enter smoothly.
- [x] Update focused chat overlay tests and any bounded-window integration coverage that asserts the long-press UI.
- [x] Run `dart format` on touched files, then `flutter analyze` and `flutter test`.
- [x] Record the review summary and verification results here.

# Review (2026-04-22 Chat Long-Press Overlay Refinement)
- [x] Implemented.
- Scope:
  - Restored the long-press message overlay toward a Telegram-like focused presentation instead of the flatter transparent-scrim state.
  - Added animated full-screen background blur plus a softer vignette scrim so the selected message stays visually isolated during long press.
  - Tuned the reaction rail, message preview, and action card entry/exit motion to use smaller travel distances and calmer scale ramps for smoother movement.
  - Slightly lengthened the dialog transition duration so the overlay settles more softly without changing message actions or reaction behavior.
  - Added regression coverage for the new blur layer in both the standalone action-sheet test and the bounded-window chat-room long-press test.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart lib/features/chat/widgets/chat_message_action_sheet.dart test/features/chat/chat_message_action_sheet_test.dart test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter test test/features/chat/chat_message_action_sheet_test.dart test/features/chat/chat_room_view_v2_bounded_window_test.dart`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-20 Invite Link Auth-Code Collision Fix)
- [x] Reproduce/trace why invite links trigger Supabase Auth PKCE handling.
- [x] Change generated invite links and fallback redirects to use an invite-specific query parameter instead of auth `code`.
- [x] Keep parsing compatibility for old `?code=` links without generating new ones.
- [x] Update tests, memory/task notes, and redeploy Firebase Hosting.
- [x] Run focused tests plus `flutter analyze` and `flutter test`.

# Review (2026-04-20 Invite Link Auth-Code Collision Fix)
- [x] Implemented.
- Root cause:
  - Supabase Flutter treats any mobile deep link with query parameter `code` as a PKCE auth callback, regardless of host/path.
  - Room invite links used `?code=XXXXXX`, so Supabase tried to exchange the room code as an auth code and threw `Code verifier could not be found in local storage`.
- Scope:
  - Generated invite links now use `?invite_code=XXXXXX`.
  - Hosted fallback accepts both `invite_code` and legacy `code`, but redirects to the app with `invite_code`.
  - App invite parser accepts both `invite_code` and legacy `code`.
  - Supabase mobile auto deep-link detection is disabled; `AppInviteLinkService` manually sends only `com.cc100053.pet://login-callback` links to Supabase Auth.
  - Added regression coverage for generated links not containing `?code=` and auth callbacks not becoming pending invites.
- Verification:
  - `dart format lib/main.dart lib/services/invite/invite_link_service.dart test/services/invite/invite_link_service_test.dart`
  - `flutter test test/services/invite/invite_link_service_test.dart`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.
  - `firebase deploy --only hosting --project pet-app-702be --non-interactive`: passed.
  - Live `/invite` verified accepting both `invite_code` and legacy `code` while redirecting custom scheme with `invite_code`.

# Plan (2026-04-20 Invite Link Share Flow)
- [x] Verify current invite UI, link/deep-link, and live RPC behavior.
- [x] Add reusable invite-code RPC migration and apply it through Supabase MCP.
- [x] Add invite-link parsing, pending invite persistence, and deep-link handling.
- [x] Update invite UI to keep copy code and add system share-sheet sharing.
- [x] Add Firebase Hosting invite fallback and app/universal-link association files.
- [x] Add localization keys, regenerate l10n, and update memory-bank current state.
- [x] Run formatting, `flutter analyze`, and `flutter test`; record results.

# Review (2026-04-20 Invite Link Share Flow)
- [x] Implemented.
- Scope:
  - Added and live-applied Supabase migration `20260420113000_add_reusable_room_invite_code_rpc.sql`.
  - Added `get_or_create_room_invite_code(...)` so normal share/copy reuses an existing active code and keeps `rooms.invite_code` synced for old clients.
  - Kept refresh semantics separate through the existing explicit invite-code RPCs.
  - Added `AppInviteLinkService` for hosted/custom invite URL parsing, share-text construction, pending invite persistence, initial-link handling, and runtime link stream handling.
  - Fixed client joins to use live `join_room_by_code`, with pending invite auto-join after Home bootstrap.
  - Updated the invite dialog to keep tap/copy code and add a system Share button for WhatsApp/LINE/Telegram/etc. through the platform share sheet.
  - Added Firebase Hosting `/invite` fallback page, AASA, Android assetlinks, Android intent filters, and iOS associated-domain entitlement.
  - Added EN/JA/KO/zh/zh-TW localized invite share/copy/pending/error copy and regenerated l10n.
  - Corrected invite share/fallback brand spelling to `PetTomo`.
- User action required:
  - Done 2026-04-20: Firebase Hosting `/invite` and `.well-known/*` deployed to `https://pet-app-702be.web.app`.
  - Done 2026-04-20: iOS Associated Domains enabled on Apple Developer bundle ID `ZX7BF33P9V` for `com.cc100053.pet`; local entitlements include `applinks:pet-app-702be.web.app` and iOS signing is automatic under team `QRLFBRL2J2`.
  - Replace/add the Android production Play/App Signing SHA-256 in `html/.well-known/assetlinks.json`; the current value is the local debug keystore fingerprint.
- Verification:
  - Supabase MCP read confirmed `get_or_create_room_invite_code`, `join_room_by_code`, `create_room_invite_code`, and `regenerate_invite_code` are present.
  - `flutter gen-l10n`: passed; existing zh untranslated-message notice remains.
  - `dart format ...`: passed.
  - `flutter test test/services/invite/invite_link_service_test.dart`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-20 Flutter Test Fix)
- [x] Run `flutter test` and confirm the active failure surface.
- [x] Trace the failing test(s) to the smallest root-cause code or test mismatch.
- [x] Apply a scoped fix without reverting existing chat edit/delete worktree changes.
- [x] Run `dart format` if files change, then `flutter analyze` and `flutter test`.
- [x] Record the review and verification result here.

# Review (2026-04-20 Flutter Test Fix)
- [x] Implemented.
- Scope:
  - Fixed `ForceUpdateGate` so soft-update and What's New `showJuiceToast` dialogs are awaited instead of continuing while still visible.
  - Restored explicit soft-update `Later` handling while keeping the `Update` action available.
  - Deferred What's New launch persistence until after the user dismisses the toast.
  - Restored version and "What's new" section labels inside the compact What's New toast body.
- Verification:
  - `dart format lib/shared/ui/app_dialog.dart lib/shared/force_update/force_update_gate.dart`
  - `dart format lib/shared/whats_new/whats_new_toast_body.dart`
  - `flutter test test/shared/force_update/force_update_gate_test.dart -r expanded`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-19 Chat Message Edit/Delete)
- [x] Verify Supabase MCP target/current state before mutating DB.
- [x] Add a migration for `messages.edited_at`, `messages.deleted_at`, `messages.deleted_by`, plus narrow sender-owned text edit/delete RPCs.
- [x] Apply the migration through Supabase MCP and confirm live columns/RPCs.
- [x] Extend chat message/reply models, repository selects, action service methods, and Hive cache serialization for edited/deleted state.
- [x] Add own-text edit/delete actions, Juice edit dialog/delete confirmation, optimistic update/revert behavior, deleted placeholder rendering, and edited marker rendering.
- [x] Add localized strings in all ARB files and regenerate Flutter l10n.
- [x] Add/adjust service, model/cache, action-sheet, and chat-room widget tests.
- [x] Run `dart format`, `flutter gen-l10n`, `flutter analyze`, and `flutter test`; record results.

# Review (2026-04-19 Chat Message Edit/Delete)
- [x] Implemented with one pre-existing unrelated full-suite failure still present.
- Scope:
  - Added and live-applied Supabase migration `20260419123000_add_chat_message_edit_delete.sql`.
  - Added `messages.edited_at`, `messages.deleted_at`, `messages.deleted_by`, plus sender-owned text-only `edit_message(...)` and `delete_message(...)` RPCs.
  - Kept direct table updates closed to clients; RPCs enforce authenticated active room membership, sender ownership, text type, non-deleted state, and body validation.
  - Extended chat models, reply previews, repository selects, Hive cache serialization, action service RPC calls, realtime updates, and localized deleted/edited rendering.
  - Added own-message Edit/Delete actions with optimistic updates and failure rollback; deleted messages hide reply/copy/reaction/edit/delete affordances and clear local reactions.
- Verification:
  - `flutter gen-l10n`: passed; existing zh untranslated-message notice remains.
  - `dart format lib/features/chat lib/services/chat test/features/chat test/services/chat test/pet_chat_message_adapter_test.dart lib/l10n/app_localizations*.dart`: passed.
  - Focused chat/service tests passed: `flutter test test/services/chat/chat_message_action_service_test.dart test/services/chat/chat_message_repository_test.dart test/pet_chat_message_adapter_test.dart test/features/chat/chat_message_action_sheet_test.dart test/features/chat/chat_room_view_v2_bounded_window_test.dart`.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` failures; `test/feed_flow_integration_test.dart` skipped due missing Supabase test env vars.

# Plan (2026-04-19 Avatar Crop Context Preview)
- [x] Replace the avatar editor's pure-black crop surroundings with a dimmed preview of the same image.
- [x] Keep the clear circular crop preview and existing non-destructive `avatar_view_v2` save behavior unchanged.
- [x] Run focused avatar editor tests and analyzer; record results.

# Review (2026-04-19 Avatar Crop Context Preview)
- [x] Implemented.
- Scope:
  - The editor stage now renders the currently framed image behind the crop circle with a dark overlay, so users can still see the photo outside the crop boundary while adjusting.
  - The circular crop preview remains clear and still uses the same shared avatar framing transform as final avatar rendering.
  - The gesture area covers the full editor stage, so dragging outside the circle still adjusts the photo.
- Verification:
  - `dart format lib/shared/ui/avatar_position_editor_page.dart`
  - `flutter test test/shared/ui/avatar_position_editor_page_test.dart`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` What's New/force-update failures; feed integration test skipped due missing Supabase test env vars.

# Plan (2026-04-18 Avatar Photo Adjustment UX)
- [x] Extract shared avatar framing transform math so editor preview and final avatar rendering stay identical.
- [x] Rebuild the full-screen avatar editor around a fixed circular frame with bounded drag, pinch zoom, slider zoom, and reset/center.
- [x] Keep Profile and onboarding save flows non-destructive with the existing `avatar_view_v2` URL fragment contract.
- [x] Add localized editor hint/control copy and regenerate l10n.
- [x] Add focused framing math and editor widget tests.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; record results and any unrelated failures.

# Review (2026-04-18 Avatar Photo Adjustment UX)
- [x] Implemented with the existing unrelated full-suite failure still present.
- Scope:
  - Added shared `AvatarFramingTransform` math for relative avatar zoom, minimum fill scale, pan bounds, and normalized alignment.
  - Updated final avatar rendering to consume the shared transform helper.
  - Rebuilt the shared full-screen avatar editor as a fixed circular crop-frame UI with bounded drag, pinch zoom, zoom slider, center reset, localized hint text, and Juice-style tappable controls.
  - Kept Profile and onboarding on the existing non-destructive `avatar_view_v2` URL-fragment save contract; no DB/schema or upload-contract changes.
  - Added focused math and editor widget coverage, including drag, pinch, slider, reset, save, and cancel behavior.
- Verification:
  - `flutter gen-l10n`: passed; existing zh untranslated-message notice remains.
  - `dart format lib/shared/utils/avatar_display_position.dart lib/shared/ui/cached_network_image_view.dart lib/shared/ui/avatar_position_editor_page.dart lib/features/profile/profile_view.dart lib/features/home/flows/home_onboarding_flow.dart test/avatar_display_position_test.dart test/shared/ui/avatar_position_editor_page_test.dart lib/l10n/app_localizations*.dart`
  - `flutter test test/avatar_display_position_test.dart test/shared/ui/avatar_position_editor_page_test.dart`: passed.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` What's New/force-update failures; feed integration test skipped due missing Supabase test env vars.

# Plan (2026-04-18 Debug Profile Setup Onboarding Tool)
- [x] Add a debug drawer action that opens the profile-setup onboarding step directly for testing the new-user upload-photo entry point.
- [x] Keep the action scoped to debug-admin tools and avoid mutating the real persisted onboarding state beyond the existing debug-onboarding flag.
- [x] Add localized debug labels and regenerate l10n.
- [x] Run formatting, analyzer, and tests; record results and unrelated failures.

# Review (2026-04-18 Debug Profile Setup Onboarding Tool)
- [x] Implemented with the existing unrelated full-suite failure still present.
- Scope:
  - Added a debug-admin drawer action under User & Plan: `Test Profile Setup`.
  - The action closes the drawer, returns to room selection, and shows the profile-setup onboarding overlay immediately with the default-name draft and empty draft avatar.
  - The action is a local preview trigger and does not write the normal onboarding completed/dismissed settings; normal Save photo / Continue actions still exercise the real new-user profile update/upload path.
  - Added localized debug labels for en, ja, ko, zh, and zh_TW, then regenerated Flutter l10n.
- Verification:
  - `flutter gen-l10n`: passed; existing zh untranslated-message notice remains.
  - `dart format lib/features/home/home_view.dart lib/l10n/app_localizations*.dart`
  - `flutter analyze`: passed, no issues found.
  - `flutter test test/avatar_display_position_test.dart test/user_avatar_test.dart test/services/profile/profile_bootstrap_service_test.dart`: passed.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` What's New/force-update failures; feed integration test skipped due missing Supabase test env vars.

# Plan (2026-04-18 Shared Avatar Framing Upload Flow)
- [x] Extract the avatar position editor into shared UI so Profile and onboarding use the same framing surface.
- [x] Change Profile photo upload to pick -> adjust -> save/upload, with cancel leaving the remote avatar unchanged.
- [x] Change new-user onboarding photo upload to use the same adjust-before-upload flow and persist the framing metadata.
- [x] Run formatting, analyzer, and tests; record results and any unrelated failures.

# Review (2026-04-18 Shared Avatar Framing Upload Flow)
- [x] Implemented with the existing unrelated full-suite failure still present.
- Scope:
  - Extracted the full-screen avatar framing editor into shared UI.
  - Profile photo upload now opens the editor immediately after image selection, uploads only after Save, and appends `avatar_view_v2` framing metadata to the uploaded R2 URL.
  - New-user onboarding uses the same editor before `avatar_upload`, then persists the same framing metadata and primes the profile/home cache with the framed URL.
  - Canceling the editor returns without uploading, so the current avatar remains unchanged and no orphaned upload is created by that path.
- Verification:
  - `dart format lib/shared/ui/avatar_position_editor_page.dart lib/features/profile/profile_view.dart lib/features/home/home_view.dart lib/features/home/flows/home_onboarding_flow.dart`
  - `flutter analyze`: passed, no issues found.
  - `flutter test test/avatar_display_position_test.dart test/user_avatar_test.dart test/services/profile/profile_bootstrap_service_test.dart`: passed.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` What's New/force-update failures; feed integration test skipped due missing Supabase test env vars.
  - `flutter test test/shared/force_update/force_update_gate_test.dart -r expanded`: reproduced the same three failures (`soft update resolves before What's New is shown`, `same-version build upgrade shows What's New when not shown before`, `legacy install without recorded version still shows first tracked What's New`).

# Plan (2026-04-18 Restore Profile Avatar Adjustment)
- [x] Restore the Profile remote-avatar adjustment action so it opens the framing editor instead of closing as a no-op.
- [x] Persist non-destructive avatar framing by updating the `profiles.avatar_url` fragment only, preserving the `avatar_upload` Edge Function upload path.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; record results and any unrelated failures.

# Review (2026-04-18 Restore Profile Avatar Adjustment)
- [x] Implemented with one pre-existing unrelated full-suite failure still present.
- Scope:
  - Restored `_adjustCurrentAvatar(...)`, `_saveAvatarFraming(...)`, and the full-screen avatar position editor removed by the Profile UI refactor.
  - Wired the `profileAvatarAdjustCurrent` bottom-sheet item to open the editor instead of closing as a no-op.
  - Framing saves by updating only the remote avatar URL fragment through `buildAvatarUrlWithFraming(...)`; the `1.1.4` `avatar_upload` Edge Function upload path remains unchanged.
- Verification:
  - `dart format lib/features/profile/profile_view.dart`
  - `flutter analyze`: passed, no issues found.
  - `rg "Adjust framing not implemented|profileAvatarAdjustCurrent|_adjustCurrentAvatar|_AvatarPositionEditorPage|buildAvatarUrlWithFraming" lib/features/profile/profile_view.dart`: placeholder removed; adjust path/editor present.
  - `flutter test test/avatar_display_position_test.dart test/user_avatar_test.dart test/services/profile/profile_bootstrap_service_test.dart`: passed.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` What's New/force-update failures already recorded below; feed integration test skipped due missing Supabase test env vars.

# Plan (2026-04-18 Profile Avatar Upload Crash v1.1.4)
- [x] Replace Profile photo avatar upload direct Supabase Storage call with the deployed `avatar_upload` Edge Function/R2 path.
- [x] Handle Profile avatar upload failures locally so missing bucket/config/network errors do not escape to Crashlytics as fatal zoned errors.
- [x] Bump app version from `1.1.3+1` to `1.1.4+1`.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; record results and current-state notes.

# Review (2026-04-18 Profile Avatar Upload Crash v1.1.4)
- [x] Implemented with one pre-existing unrelated full-suite failure still present.
- Scope:
  - Replaced Profile custom avatar direct Supabase Storage upload to missing `app_assets` with the deployed `avatar_upload` Edge Function path.
  - Reused the existing upload MIME/size limits and Supabase access-token refresh retry for 401 Edge Function responses.
  - Caught Profile avatar upload errors locally and displays localized `userFacingError(...)` in a danger toast instead of letting the exception escape to `runZonedGuarded`.
  - Bumped `pubspec.yaml` to `1.1.4+1`.
- Verification:
  - `dart format lib/features/profile/profile_view.dart`
  - `flutter analyze`: passed, no issues found.
  - `rg "storage\\.from\\('app_assets'\\)|from\\(\\\"app_assets\\\"\\)|uploadBinary\\(" lib test`: no matches.
  - `flutter test test/services/profile/profile_bootstrap_service_test.dart test/services/crash/crash_reporting_service_test.dart`: passed.
  - `flutter test`: failed only in the pre-existing `test/shared/force_update/force_update_gate_test.dart` failures already recorded above; the env-gated feed integration test skipped due missing Supabase test env vars.

# Plan (2026-04-18 AGENTS + Memory-Bank Optimization)
- [x] Read required repo guidance, active memory-bank files, task notes, workflow docs/skills/scripts/functions, and check git status.
- [x] Measure active memory-bank line counts, archive any file before compacting it, and keep active files current-state focused.
- [x] Patch `AGENTS.md` only for grounded workflow/command corrections or additions discovered from local sources.
- [x] Review diffs for overreach, then run required verification: `wc -l memory-bank/*.md`, `git diff --stat`, `flutter analyze`, and `flutter test`.
- [x] Record before/after line counts, archive paths, verification results, and remaining notes in this file.

# Review (2026-04-18 AGENTS + Memory-Bank Optimization)
- [x] Implemented with one unrelated verification failure recorded.
- Scope:
  - Updated `AGENTS.md` Supabase setup guidance so migrations point to the MCP-first workflow instead of the SQL editor.
  - Added a grounded Edge Function workflow pointer to `docs/hunger_tick_schedule_report.md` for server-side hunger tick cron/manual verification.
  - Compacted active `architecture.md`, `database-schema.md`, and `progress.md` into current-state summaries with pointers to source-of-truth files and archive snapshots.
  - Did not edit app/runtime code.
- Active memory-bank line counts:
  - Before: `architecture.md` 103, `database-schema.md` 116, `progress.md` 129, `tech-stack.md` 53, `ui-ux-guidelines.md` 81; total 482.
  - After: `architecture.md` 72, `database-schema.md` 92, `progress.md` 71, `tech-stack.md` 53, `ui-ux-guidelines.md` 81; total 369.
- Archived snapshots:
  - `memory-bank/archive/architecture_20260418_pre_compaction.md` (103 lines)
  - `memory-bank/archive/database_schema_20260418_pre_compaction.md` (116 lines)
  - `memory-bank/archive/progress_20260418_pre_compaction.md` (129 lines)
- Diff review:
  - Scoped tracked diff: `AGENTS.md`, three active memory-bank files, and `tasks/todo.md` only (`217 insertions`, `295 deletions`).
  - `git status` still shows pre-existing unrelated app/localization/release-note changes outside this task; left untouched.
- Verification:
  - `wc -l memory-bank/*.md`: total 369 active lines.
  - `git diff --stat`: reviewed; global stat includes unrelated pre-existing app/release changes.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: failed in `test/shared/force_update/force_update_gate_test.dart`; appears unrelated to this documentation-only change because the affected force-update/What's New files were already modified outside this task. The env-gated feed integration test skipped with: `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
  - Focused failure details from `flutter test test/shared/force_update/force_update_gate_test.dart -r expanded`:
    - `soft update resolves before What's New is shown`: expected no `Stability & Security Update`, but one widget was found.
    - `same-version build upgrade shows What's New when not shown before`: expected `1.0.5+1`, actual `1.0.5+2`.
    - `legacy install without recorded version still shows first tracked What's New`: expected `null`, actual `1.0.5`.

# Plan (2026-04-17 Reliable Feed Upload Queue)
- [x] Extract feed upload result/optimistic models out of the route-owned camera view.
- [x] Add a persistent Riverpod/Hive-backed feed upload queue that owns upload,
      retry, and resume reconciliation.
- [x] Refactor `FeedCaptureView` to enqueue jobs and close without owning the
      background upload future.
- [x] Wire Home and Chat to observe queue events so pending/completed/failed
      feed jobs reconcile after navigation or app resume.
- [x] Add focused queue/reconciliation tests and run `flutter analyze` plus
      `flutter test`.

# Review (2026-04-17 Reliable Feed Upload Queue)
- [x] Implemented and verified.
- Scope:
  - Added feed upload models, a Hive repository, Supabase upload/reconciliation
    client, and a non-auto-disposed Riverpod queue.
  - `FeedCaptureView` now persists/enqueues a feed job and closes; compression,
    token refresh, `feed_validate`, and reconciliation are queue-owned.
  - Home observes the queue for global pending/completed/failed handling,
    refreshes pet state/gallery/coins after completion, and resumes pending jobs
    on app resume.
  - Chat observes the queue only for room-local optimistic row reconciliation,
    avoiding duplicate Home reward/refresh side effects.
- Verification:
  - `flutter test test/features/feed/feed_upload_queue_test.dart test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Furniture Flip And Multi-Quantity Inventory)
- [x] Add live Supabase support for per-instance furniture flip and room-level
      furniture inventory revision notifications without changing old RPC
      parameters.
- [x] Update Home placed-furniture loading/rendering/edit controls to persist
      horizontal flip per placed furniture instance.
- [x] Update Shop furniture cards so owned furniture remains purchasable and
      shows room-owned quantity, while one-off cosmetics stay owned/locked.
- [x] Update room inventory UI to show shared total and available-to-place
      counts, and refresh automatically when another room member buys furniture.
- [x] Add localized strings, focused tests, run `flutter gen-l10n`,
      `flutter analyze`, and `flutter test`, then update memory-bank notes.
- [x] Rollout target: app version `1.1.2`.

# Review (2026-04-15 Furniture Flip And Multi-Quantity Inventory)
- [x] Implemented and verified.
- Scope:
  - Added and live-applied Supabase migration
    `20260415132020_add_furniture_flip_and_inventory_revisions.sql`.
  - Added `room_furniture.flip_x`, additive
    `update_room_furniture_flip(...)`, and room-level
    `room_item_inventory_revisions` realtime notifications triggered by
    `room_item_inventories` changes.
  - Home now loads, renders, toggles, and persists per-instance horizontal
    furniture flip while keeping selection/delete chrome unmirrored.
  - Shop furniture cards now show room-owned quantity and use `Buy more` while
    remaining purchasable; backgrounds and other one-off cosmetics remain
    owned/locked.
  - Room Inventory now shows owned and available counts when copies are already
    placed, and Home/room-scoped Shop refresh counts from revision events.
  - Added localized copy for `Buy more`, owned count, available count, and flip
    tooltip across supported locales.
- Verification:
  - Supabase MCP live migration applied and verified (`flip_x`, flip RPC,
    revision table, realtime publication).
  - `flutter gen-l10n`
  - `dart format ...`
  - `flutter test test/features/shop/shop_grid_item_card_test.dart test/features/home/widgets/home_room_inventory_panel_test.dart test/features/home/widgets/home_furniture_scale_controls_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Crash Recovery Prompt UX)
- [x] Replace the crash fallback screen copy so it no longer claims an update is available.
- [x] Redesign the crash fallback as a PicPet-style recovery screen with a pet GIF and clear restart guidance.
- [x] Keep the normal hard/soft force-update flow unchanged.
- [x] Add localized crash-recovery strings and focused widget coverage.
- [x] Run `dart format`, `flutter gen-l10n`, `flutter analyze`, and `flutter test`; record results.

# Review (2026-04-15 Crash Recovery Prompt UX)
- [x] Implemented and verified.
- Scope:
  - Replaced the crash fallback's force-update copy/action with dedicated crash recovery localization.
  - Removed App Store launch behavior from `CrashUpdateGuard`; true hard/soft force-update paths remain in `ForceUpdateGate`.
  - Added a PicPet-style full-screen recovery surface using the default ghost pet GIF, warm game styling, restart guidance, and a "Got it" acknowledgement that clears the overlay.
  - Added localized recovery copy for en, ja, ko, zh, and zh_TW.
  - Added widget coverage confirming zh_TW crash copy appears and update copy does not.
- Verification:
  - `flutter gen-l10n`
  - `dart format lib/shared/force_update/crash_update_guard.dart test/shared/force_update/crash_update_guard_test.dart`
  - `flutter test test/shared/force_update/crash_update_guard_test.dart`
  - `flutter test test/shared/force_update/force_update_gate_test.dart test/shared/force_update/crash_update_guard_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 iOS Platform View Recreate Crash)
- [x] Identify every Flutter surface that creates an iOS platform view and map it to the reported `UiKitView` stack.
- [x] Reproduce or reason from lifecycle/key ownership to find why Flutter attempts to create an already-created view id.
- [x] Implement the smallest lifecycle-safe fix and add regression coverage where practical.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; update task/memory notes with root cause and verification.

# Review (2026-04-15 iOS Platform View Recreate Crash)
- [x] Implemented and verified.
- Root cause:
  - The reported stack is from Flutter iOS platform-view creation (`PlatformViewsService.initUiKitView` / `_DarwinViewState._createNewUiKitView`).
  - The app's normal persistent `UiKitView` owner is the AdMob banner `AdWidget` in `AdMobBannerSlot`.
  - Live Firebase Crashlytics for iOS did not show a matching production issue in the last 7 or 90 days; this matches a local debug/hot-restart platform-view id collision pattern, where Dart's platform-view id counter restarts while native iOS still has an old embedded view.
- Scope:
  - Added `AdMobIds.isBannerViewSupported` so embedded banner platform views are disabled in debug by default and remain enabled in profile/release.
  - Added env override `ADMOB_ENABLE_DEBUG_BANNER_VIEWS=true` for intentional local banner testing.
  - Switched Home room-selection and Shop banner slots to the banner-specific gate; rewarded ads remain on the existing iOS support gate.
  - Added unit coverage for banner platform-view gating.
- Verification:
  - `dart format lib/services/env.dart lib/services/ads/admob_ids.dart lib/features/ads/admob_banner_slot.dart lib/features/home/home_view.dart lib/features/shop/shop_view.dart test/services/ads/admob_ids_test.dart`
  - `flutter test test/services/ads/admob_ids_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Shop Candy Feedback Follow-up)
- [x] Update the shared item rollout skill with the lessons from the bathroom furniture / candy pack rollout.
- [x] Move Shop candy-pack SFX triggering onto the purchase success path so it fires even when the balance-chip animation is rebuilt.
- [x] Fix the Shop currency-chip `TweenSequence` assertion by removing overshooting curve output from the sequence input.
- [x] Add focused animation regression coverage that advances the reward animation far enough to catch the scheduler assertion.
- [x] Run `dart format`, focused tests, `flutter analyze`, and `flutter test`; update task/memory notes.

# Review (2026-04-15 Shop Candy Feedback Follow-up)
- [x] Implemented and verified.
- Scope:
  - Updated `.codex/skills/shared-item-rollout/SKILL.md` with rollout lessons for owned inventory hydration, live app-version gates, purchase feedback, and `TweenSequence` animation safety.
  - Moved Shop candy-pack SFX to the successful diamond-purchase branch when `new_coin_balance` increases, while keeping the balance chip responsible for the visual `+N` animation only.
  - Removed the overshooting `Curves.easeOutBack` input from the Shop currency-chip `TweenSequence`; the scale overshoot is now expressed by tween values with controller input staying in `0..1`.
  - Extended `shop_currency_chip_test` to advance the reward animation and verify the reward label clears after completion.
- Verification:
  - `dart format lib/features/shop/shop_view.dart lib/features/shop/services/shop_purchase_handler.dart test/features/shop/shop_currency_chip_test.dart`
  - `flutter test test/features/shop/shop_currency_chip_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Room Furniture Inventory And Candy Feedback)
- [x] Hydrate room furniture catalog from owned inventory item IDs so bought bathroom furniture stays visible/usable even if the shop visibility response is stale.
- [x] Resolve current app version from the platform before applying version gates in Home/Shop so old cached launch versions do not hide newly supported items.
- [x] Add the existing candy-gain sound and reward animation feedback when buying the 500-candy diamond pack in Shop.
- [x] Add focused regression tests for owned furniture catalog hydration and Shop candy reward feedback.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; document results and any current-state notes.

# Review (2026-04-15 Room Furniture Inventory And Candy Feedback)
- [x] Implemented and verified.
- Scope:
  - Home room inventory now merges visible shop furniture with owned room-inventory item rows, so already-purchased bathroom furniture can appear in the room backpack even if the shop visibility response omits it.
  - Home and Shop now resolve the platform app version before applying version gates, using the cached launch version only as a fallback if the platform lookup fails.
  - Shop candy balance chips now support the same candy-gain sound plus a floating `+N` reward animation; the 500 Candy Pack triggers it when the purchase RPC returns a higher coin balance.
  - Added focused regression coverage for owned version-gated furniture catalog hydration and Shop candy reward feedback.
- Verification:
  - `dart format ...`
  - `flutter test test/features/home/home_furniture_inventory_utils_test.dart test/features/shop/shop_currency_chip_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Chat Mentions And Smooth Send)
- [x] Add display-only chat @mention autocomplete for active room members, excluding the current user and blocked users.
- [x] Highlight known @mention display names inside chat text bubbles while storing messages as plain text.
- [x] Replace optimistic sent messages with confirmed server rows in one timeline update to remove the post-send shrink/expand jitter.
- [x] Add focused mention parsing/widget tests plus send-regression tests for optimistic replacement and viewport stability.
- [x] Run `dart format`, `flutter analyze`, and `flutter test`; document results and compact current-state notes as needed.

# Review (2026-04-15 Chat Mentions And Smooth Send)
- [x] Implemented and verified.
- Scope:
  - Added display-only chat mentions with active-token parsing, active room-member suggestions, blocked/current-user filtering, fixed-height overlay placement, focus-preserving insertion, and known-name text highlighting.
  - Kept message storage as plain text and avoided Supabase schema, Edge Function, notification, unread-rule, or old-client behavior changes.
  - Added send-row APIs to `ChatMessageActionService` while preserving existing return-id methods.
  - Replaced optimistic temp messages with confirmed server/realtime rows in a single timeline update so the reversed latest view does not collapse then expand after send.
  - Made analytics calls no-op safely when Firebase is unavailable, preventing send-success bookkeeping from crashing tests or early startup.
- Verification:
  - `dart format ...`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "successful send replaces optimistic" -r expanded`
  - `flutter test test/features/chat/chat_mentions_test.dart test/services/chat/chat_message_action_service_test.dart test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-15 Shop Furniture And Candy Pack)
- [x] Inspect current Shop/furniture catalog, image rendering, purchase RPCs, and live Supabase target before mutating data.
- [x] Add image-backed furniture support for shop cards, room inventory, and placed room furniture while preserving emoji fallback.
- [x] Add localized labels/descriptions for Toilet, Tub, and 500 Candy Pack.
- [x] Add a version-gated Supabase catalog migration for toilet, tub, and the 500-candy diamond exchange pack, keeping purchase predicates aligned.
- [x] Apply the migration through Supabase MCP after confirming the target project, then verify catalog visibility boundaries.
- [x] Run asset bundle, localization, analyzer, and tests; update memory/task notes with results and pricing rationale.

# Review (2026-04-15 Shop Furniture And Candy Pack)
- [x] Implemented and verified.
- Scope:
  - Added reusable image-backed furniture rendering with emoji fallback for Shop cards, purchase notices, Home inventory, and placed room furniture.
  - Registered `assets/furniture/` and localized Toilet, Tub, and 500 Candy Pack names/descriptions across supported ARB files.
  - Added and live-applied Supabase migration `20260415104915_add_bathroom_furniture_and_candy_pack.sql`: Toilet is `150` candy, Tub is `300` candy, and 500 Candy Pack costs `50` diamonds.
  - Kept all three new SKUs `is_active = false` with `visibility_mode = version_gated` and `min_app_version = 1.1.2`; verified `get_visible_shop_items('1.1.1')` returns none and `get_visible_shop_items('1.1.2')` returns all three.
  - Updated furniture purchase/place RPC predicates and diamond exchange purchase predicates so visible version-gated rows can be bought/placed while hidden rollout rows remain excluded.
- Pricing note:
  - Toilet at `150` candy fits as an accessible mid-low decor item.
  - Tub at `300` candy is reasonable as a larger premium decor item, but should stay below rare/background anchor prices unless it becomes a premium highlight.
  - 500 candy for `50` diamonds creates a clear `10 candy = 1 diamond` exchange rate; that is simple, but it becomes an economy anchor, so future candy rewards and furniture prices should be checked against this rate.
- Verification:
  - Supabase MCP target/migration history checked against the repo project; live migration applied successfully.
  - Live catalog visibility: `1.1.1` hidden, `1.1.2` visible.
  - `flutter gen-l10n`
  - `dart format ...`
  - `flutter test test/features/shop/shop_item_compatibility_test.dart`
  - `flutter test test/features/home/widgets/home_room_inventory_panel_test.dart`
  - `flutter build bundle`
  - `strings build/flutter_assets/AssetManifest.bin | rg 'assets/furniture/(toilet|bathtub)\\.png'`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-14 Chat Crash Hardening)
- [x] Harden chat send path so optimistic UI, latest-window refresh, DB insert,
  and post-send refresh all recover without uncaught exceptions.
- [x] Clean up chat/Home realtime channels through `removeChannel(...)` and
  ignore stale callbacks after chat route disposal.
- [x] Harden shared cached image sizing and avatar fragment parsing against
  NaN/Infinity while capping cache decode dimensions.
- [x] Reduce chat render stress around image cards, highlights, and action
  sheets without changing visible behavior or interaction flow.
- [x] Add focused regression tests, update memory notes, and run
  `flutter analyze` plus `flutter test`.

# Review (2026-04-14 Chat Crash Hardening)
- [x] Implemented and verified.
- Scope:
  - Wrapped chat text send in one recoverable path covering latest-window prep,
    optimistic insertion, DB send, notification trigger, refresh, composer
    restore, and `_sending` cleanup.
  - Added chat Crashlytics context/breadcrumbs around route lifecycle, send
    phases, fullscreen/action/reaction surfaces, plus memory snapshots.
  - Replaced chat/Home realtime `unsubscribe()` cleanup with best-effort
    `removeChannel(...)`, cleared local channel references first, and ignored
    stale callbacks after route disposal or room switches.
  - Hardened `CachedNetworkImageView` cache-size resolution and avatar framing
    fragments against NaN/Infinity, with cache dimensions capped at 2048px per
    side.
  - Reduced chat Impeller pressure by removing BackdropFilter blur from action
    sheets/glass pills, reducing highlight shadows, and isolating feed-card
    image repaint work.
  - Made CrashReportingService no-op safely when Firebase is unavailable, so
    diagnostics cannot crash widget tests or early startup.
- Verification:
  - `dart format ...`
  - `flutter test test/shared/ui/cached_network_image_view_test.dart`
  - `flutter test test/avatar_display_position_test.dart`
  - `flutter test test/features/chat/chat_message_action_sheet_test.dart`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter test test/services/chat/chat_message_action_service_test.dart`
  - `flutter test test/services/crash/crash_reporting_service_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-13 Feed Double Reward Clarity)
- [x] Verify current Supabase target and inspect live reward/message function shape before applying an additive RPC migration.
- [x] Add `claim_feed_double_reward(p_room_id, p_message_id)` locally and live via Supabase MCP without changing existing `claim_action_reward(...)`.
- [x] Update Home feed double-reward flow so ad claims are tied to the feed message, show x2 total reward feedback, and refresh affected state.
- [x] Update Home currency reward UI, Chat feed badge copy, and Chat V2 realtime handling for message reward updates.
- [x] Add focused tests for reward metadata, badge text, status-bar double reward feedback, and chat message reward updates.
- [x] Run localization/code formatting plus required verification (`flutter gen-l10n`, `flutter analyze`, `flutter test`) and document results.

# Review (2026-04-13 Feed Double Reward Clarity)
- [x] Implemented and verified.
- Scope:
  - Added and live-applied additive Supabase RPC `claim_feed_double_reward(p_room_id, p_message_id)` with row locking, ledger metadata dedupe, and message reward sync.
  - Switched Home feed double-reward claims to the new RPC so ad rewards are tied to a feed photo; the HUD now shows an x2 total-reward label while only adding the extra candy locally.
  - Updated Chat feed-photo reward labels to include localized candy text and added `messages` update realtime handling so reward badges update in place and cache correctly.
  - Added localized double-reward claimed copy across en/zh/ja/ko and adjusted zh feed reward badge order to `糖果 +{count}`.
- Verification:
  - Supabase MCP target confirmed as `ilxzpszgirhwxpeocygs`; live migration applied and verified.
  - Rollback smoke check confirmed a `20` reward doubles to `40`, profile coins increase by `20`, a second claim adds nothing, and no smoke rows remain.
  - `flutter gen-l10n`
  - `dart format ...`
  - `flutter test test/pet_chat_message_adapter_test.dart`
  - `flutter test test/features/chat/chat_window_state_test.dart`
  - `flutter test test/features/home/widgets/home_game_status_bar_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-11 Compact Memory Bank)
- [x] Read all active memory-bank files and measure which files dominate token usage.
- [x] Archive current long-form memory-bank snapshots before shortening active files.
- [x] Rewrite active architecture/schema/progress notes as concise current-state summaries with pointers to archive and source-of-truth files.
- [x] Update agent guidance so future memory-bank updates stay compact, then run verification.

# Review (2026-04-11 Compact Memory Bank)
- [x] Implemented and verified.
- Scope:
  - Reduced active memory-bank files from 720 lines to 299 lines while keeping the long-form snapshots in `memory-bank/archive/`.
  - Rewrote `architecture.md`, `database-schema.md`, and `progress.md` as compact current-state summaries with source-of-truth pointers.
  - Added an `AGENTS.md` rule to keep active memory-bank files compact and archive long historical detail.
- Verification:
  - `wc -l memory-bank/*.md memory-bank/archive/*_20260411_pre_compaction.md`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-11 Update AGENTS Workflows)
- [x] Read the current AGENTS.md, memory-bank files, and task notes required by repo workflow.
- [x] Verify referenced repo-local workflow docs/skills/scripts before changing AGENTS.md.
- [x] Patch AGENTS.md with only grounded workflow and command additions, then review the diff.

# Review (2026-04-11 Update AGENTS Workflows)
- [x] Implemented and verified.
- Scope:
  - Added repo-local workflow pointers for Crashlytics triage, release-note/App Store metadata sync, and shared-item rollouts.
  - Added grounded commands for Flutter asset-bundle verification, Firebase Crashlytics MCP tool listing, and ASC localization upload/list verification.
  - Added a TODO for the missing `.firebase-mcp.env.example` file referenced by the Crashlytics MCP setup doc.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-09 Refactor Review Sweep)
- [x] Read the active memory-bank files plus current task notes, then inspect the highest-complexity Flutter surfaces for refactor candidates.
- [x] Trace concrete code paths in the main hotspots (`home_view`, `chat_room_view_v2`, `shop_view`, `profile_view`, related sheets) and collect line-level evidence.
- [x] Summarize the highest-value refactor opportunities with clear priority, rationale, and affected files.

# Review (2026-04-09 Refactor Review Sweep)
- [x] Investigated and documented.
- Scope:
  - Reviewed the largest active Flutter surfaces and compared them against existing extraction patterns (providers, controllers, services) to find places where responsibilities are still mixed or duplicated.
  - Focused on refactors with practical payoff: consistency, lower regression risk, reduced network latency, or simpler state ownership.
  - Collected concrete line references for repeated app-version/profile bootstrap logic, chat window hydration duplication, shop load serialization, duplicated profile-sheet fetch flows, and Home furniture persistence/state-sync hotspots.
- Verification:
  - `rg --files memory-bank`
  - `find lib test -name '*.dart' -print0 | xargs -0 wc -l | sort -nr | head -n 40`
  - Targeted `nl -ba` / `rg -n` inspection across the reviewed files

# Plan (2026-04-10 Refactor Home Furniture Persistence + Shared Profile Bootstrap)
- [x] Inspect the latest furniture RPC definitions and current Home/Profile bootstrap flows before changing either path.
- [x] Extract a shared profile bootstrap service, switch Home/Profile to the shared path, and add focused service coverage.
- [x] Add a backward-compatible atomic room-furniture transform migration, update Home to use it with a legacy fallback, and record the change in the memory bank.
- [x] Run full verification (`flutter analyze`, `flutter test`) and summarize how to test the changed user flows end to end.

# Review (2026-04-10 Refactor Home Furniture Persistence + Shared Profile Bootstrap)
- [x] Implemented and verified.
- Scope:
  - Added `ProfileBootstrapService` so Home and Profile now share one path for ensuring the signed-in user has a `profiles` row and the latest device timezone.
  - Switched `HomeView._ensureProfile()` and `ProfileView._loadProfile()` to the shared service, and added focused unit coverage for missing-profile creation and timezone-sync behavior.
  - Added and applied a backward-compatible Supabase migration for `update_room_furniture_transform(...)`, then updated Home furniture persistence to use the atomic RPC with a legacy fallback to the old per-field RPCs when the new function is unavailable.
  - Updated the memory bank to document the new shared bootstrap path and the additive furniture-transform RPC contract.
- Verification:
  - `flutter test test/services/profile/profile_bootstrap_service_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-04 Debug Xcode Archive Signing Failure)
- [x] Read the repo memory bank plus any iOS/archive notes, then inspect the current Xcode project signing settings for Runner and the notification extension.
- [x] Compare the current local signing environment against recent successful archives on this machine to separate repo config issues from Apple account / keychain issues.
- [x] Document the root cause and required recovery actions; avoid repo-side code changes unless the project configuration itself is proven wrong.

# Review (2026-04-04 Debug Xcode Archive Signing Failure)
- [x] Investigated and verified.
- Scope:
  - Confirmed `ios/Runner.xcodeproj/project.pbxproj` is still targeting team `QRLFBRL2J2` with automatic signing semantics for the shipped iOS targets (`com.cc100053.pet` and `com.cc100053.pet.NotificationService`).
  - Confirmed the failure is not caused by a newly broken project configuration: this same Mac still has successful Runner archives and App Store uploads from `2026-03-19`, including an uploaded `1.0.5 (2)` archive for the same bundle id and team.
  - Verified the current local signing environment is missing the required key material: `security find-identity -v -p codesigning` returns `0 valid identities found`, and no local provisioning-profile directory is currently present under `~/Library/MobileDevice/Provisioning Profiles`.
  - Concluded the current archive failure is blocked by 2 external prerequisites shown in Xcode itself: the Apple Developer Program License Agreement for the account/team must be accepted, and a valid signing certificate/private-key pair must be restored or re-created locally for team `QRLFBRL2J2`.
- Verification:
  - `security find-identity -v -p codesigning`
  - `plutil -p ~/Library/Developer/Xcode/Archives/2026-03-19/'Runner 19-3-2026, 10.45.xcarchive'/Info.plist`
  - `flutter build ios --release` (started and reached the Xcode signing step; no repo-side configuration regression identified before the external signing gate)

# Plan (2026-04-04 Replace Furniture Pinch With Bottom Scale Controls)
- [x] Rework Home furniture edit interactions so placed furniture uses tap-to-select plus single-finger drag, and remove the pinch-resize gesture path.
- [x] Add a bottom floating furniture scale control bar with step buttons and a slider, wire it to the selected placed furniture, and update the related helper math/localized copy.
- [x] Add focused regression coverage, update memory/task notes, and run the required verification (`flutter gen-l10n`, `flutter analyze`, `flutter test`).

# Review (2026-04-04 Replace Furniture Pinch With Bottom Scale Controls)
- [x] Implemented and verified.
- Scope:
  - Reworked `HomeView` furniture edit interactions so placed furniture now uses tap-to-select plus single-finger drag, and removed the pinch gesture path entirely.
  - Added `HomeFurnitureScaleControls`, a bottom floating control bar with large `- / slider / +` controls, stepped `0.1` resizing, and disabled states at the configured min/max bounds.
  - Kept the existing `room_furniture.scale` persistence contract and room-edge reclamp behavior, while also preserving immediate drag/resize edits performed before a new placement receives its server id.
  - Updated localized furniture hints / What's New copy to describe the new selection-plus-bottom-controls flow, and documented the interaction change in the memory bank and lessons log.
  - Added focused regression coverage for stepped scale math and the new control widget.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-04 Update Shared Item Rollout Skill)
- [x] Review the existing shared-item rollout skill and map the newly discovered background rollout failures to its workflow/guardrails.
- [x] Update the skill so future shared decor rollouts cover nested Flutter asset folders, purchase RPC alignment, and RLS alignment.
- [x] Run the required repo verification and document the skill update.

# Review (2026-04-04 Update Shared Item Rollout Skill)
- [x] Implemented and verified.
- Scope:
  - Updated `.codex/skills/shared-item-rollout/SKILL.md` to include the new rollout metadata `shop_visibility`, the distinction between visible/purchasable/seed-only decor, and the current background rollout migrations that enforce those rules.
  - Added explicit guardrails for nested Flutter asset folders and for the 3 enforcement layers that must stay aligned on decor rollouts: catalog visibility, purchase RPC predicates, and table RLS policies.
  - Expanded the verification section so future decor rollouts check `flutter build bundle` output/`AssetManifest.bin` and inspect live Supabase RPC/policy definitions when the rollout changes purchase predicates.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-04 Fix Background Shop Visibility + Asset Paths)
- [x] Re-check the interrupted background rollout changes, including memory-bank context, current diffs, and the live/background shop data contract.
- [x] Fix the shop/background implementation so free backgrounds stay out of the shop catalog, paid background previews render with the corrected asset paths, and the requested candy prices are enforced.
- [x] Update task/memory notes as needed and run the required verification (`flutter analyze`, `flutter test`).

# Review (2026-04-04 Fix Background Shop Visibility + Asset Paths)
- [x] Implemented and verified.
- Scope:
  - Confirmed the interrupted background rollout changes were already in the worktree, then verified the live Supabase catalog state directly: free rollout backgrounds are hidden, Bubble Sky is `250` candies, and Starlit Dream is `220` candies.
  - Kept the corrected asset filenames wired through `lib/features/home/room_backgrounds.dart`, which is the shared background registry used by Shop card previews, theme preview dialog, success notice visuals, and Home background rendering.
  - Preserved the Shop-side free-background filter through `ShopItem.shopVisibility` + `ShopView._storeItems`, and added focused regression coverage for corrected background asset paths plus hidden/coin-only background metadata parsing.
  - Traced the remaining runtime crash to Flutter asset bundling instead of the preview widget: `pubspec.yaml` only declared `assets/bg/`, so generated bundles excluded `assets/bg/free/` and `assets/bg/paid/`. Added those nested directories explicitly and confirmed the rebuilt `AssetManifest.bin` now includes all four JPGs.
  - Updated task/memory notes to document the new `shop_visibility = hidden` rollout contract for free compatibility backgrounds.
- Verification:
  - `flutter build bundle`
  - `flutter test test/features/home/room_backgrounds_test.dart`
  - `flutter test test/features/shop/shop_item_compatibility_test.dart`
  - `flutter test test/features/shop/shop_theme_preview_dialog_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-04 Fix Version-Gated Background Purchase RPC)
- [x] Inspect the live background purchase RPC contract against the new version-gated paid background rows and confirm the exact predicate mismatch.
- [x] Apply a minimal Supabase migration so paid version-gated backgrounds remain purchasable while hidden free rollout backgrounds stay blocked from purchase.
- [x] Re-verify the live RPC definitions plus required repo checks, then document the root cause and fix.

# Review (2026-04-04 Fix Version-Gated Background Purchase RPC)
- [x] Implemented and verified.
- Scope:
  - Confirmed the live paid background rows were correct (`category = background`, prices intact), but both purchase RPCs still required `items.is_active = true`, which excluded the new version-gated paid backgrounds and caused `item_not_background`.
  - Added `supabase/migrations/20260404103000_fix_version_gated_background_purchase.sql` and applied the same change live through Supabase MCP. The background purchase RPCs now accept non-hidden version-gated backgrounds in addition to legacy active backgrounds.
  - Kept the hidden free rollout backgrounds blocked from purchase by requiring `coalesce(metadata->>'shop_visibility', '') <> 'hidden'` inside both RPCs.
- Verification:
  - Live `pg_get_functiondef(...)` confirms the updated RPC predicate is deployed.
  - Live item checks confirm `background_bubble_sky` / `background_starlit_dream` now satisfy the RPC predicate while `background_sage_frame` / `background_lilac_frame` remain excluded.
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-04 Fix Room Background Purchase RLS)
- [x] Inspect the live `room_backgrounds` insert policy and confirm why the updated purchase RPC is still blocked.
- [x] Apply the minimal Supabase policy fix so version-gated paid backgrounds can be inserted while hidden free backgrounds remain excluded.
- [x] Re-verify the live RLS policy plus required local checks, then document the root cause and fix.

# Review (2026-04-04 Fix Room Background Purchase RLS)
- [x] Implemented and verified.
- Scope:
  - Confirmed the updated purchase RPCs were correct, but the live `room_backgrounds_insert` RLS policy still required `items.is_active = true`, so inserts for version-gated paid backgrounds failed with a 42501 RLS violation.
  - Added `supabase/migrations/20260404104500_fix_room_backgrounds_insert_policy.sql` and applied it live through Supabase MCP.
  - The new insert policy now matches the updated purchase RPC contract: room member only, `acquired_by = auth.uid()`, category must be `background`, hidden rollout backgrounds stay excluded, and either `is_active = true` or `visibility_mode = version_gated` is accepted.
- Verification:
  - Live `pg_policies` output confirms the deployed `room_backgrounds_insert` policy now includes the version-gated + non-hidden predicate.
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-03 Create Shared Item Rollout Skill)
- [x] Read the repo skill format and collect the current shared-item compatibility rules from code, migrations, and memory-bank notes.
- [x] Create a repo-local skill that documents the mixed-version rollout workflow for shared backgrounds, furniture, and pets.
- [x] Update task/memory notes and verify the new skill file is present in the repo.

# Review (2026-04-03 Create Shared Item Rollout Skill)
- [x] Implemented.
- Scope:
  - Added `.codex/skills/shared-item-rollout/SKILL.md` as a repo-local skill for future mixed-version shared-item updates.
  - Captured the long-term rollout rules for shop-backed decor and pets: version-gated visibility, old-client fallback rendering, shared update prompting, Supabase migration expectations, notification payload sync, and verification steps.
  - Kept the skill concise and repo-specific so future agents can directly reuse the established workflow instead of rediscovering it from recent diffs.
- Verification:
  - Confirmed the skill file exists in `.codex/skills/shared-item-rollout/SKILL.md`

# Plan (2026-04-03 Add Tiger Pet Shared Compatibility)
- [x] Inspect the current pet selection/render/notification flow and identify every surface that can encounter an unsupported shared pet type.
- [x] Add a reusable version-gated tiger pet definition plus old-client fallback behavior across pet selection, home room rendering, room list cards, and update prompting.
- [x] Wire tiger assets/localization/notification avatar mappings, update task/memory notes, and run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-04-03 Add Tiger Pet Shared Compatibility)
- [x] Implemented and verified.
- Scope:
  - Added a version-gated tiger pet definition to `PetCatalog` (`min_app_version = 1.1.0`) so the same shared-item compatibility policy used by backgrounds/furniture now also applies to pets.
  - Updated `PetSelectionPage`, `HomeView`, `HomeRoomManager`, and `RoomSelectionView` so unsupported shared pet types automatically fall back to the default pet on older app versions while compatibility-aware clients continue showing tiger normally.
  - Expanded the existing room compatibility prompt copy to cover pets, added tiger localization/assets, and updated notification avatar payload handling so newer clients prefer the bundled tiger asset while older clients still degrade safely to ghost/default visuals.
  - Added focused regression coverage for version-gated pet visibility and room-list fallback rendering.
- Verification:
  - `dart format lib/features/pet/pet_catalog.dart lib/features/pet/pet_selection_page.dart lib/features/home/home_view.dart lib/features/home/controllers/home_room_manager.dart lib/features/home/room_selection_view.dart test/features/pet/pet_catalog_test.dart test/room_selection_unread_indicator_test.dart`
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-03 Add New Background Catalog)
- [x] Inspect the existing room-background rendering/catalog flow and confirm where Shop/Home/background notifications derive their background metadata.
- [x] Add the four new background assets to the Flutter background registry plus localized shop naming/description paths so they render correctly in Home, Shop, and inventory surfaces.
- [x] Replace the one-off activation plan with a long-term version-gated compatibility flow for shared decor, then run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-04-03 Add New Background Catalog + Shared Decor Compatibility)
- [x] Implemented and verified.
- Scope:
  - Added the four new room background definitions plus localized shop/notification naming for the new free and paid backgrounds.
  - Introduced generic shop-item compatibility metadata parsing (`min_app_version`, `visibility_mode`, fallback metadata) and a reusable Supabase RPC path `get_visible_shop_items(p_app_version)` so new app versions can see gated catalog items while old versions keep the legacy `is_active` view.
  - Converted the new backgrounds to version-gated catalog rows (`is_active = false` + metadata gate) and applied the two Supabase migrations live through MCP.
  - Updated Home to hide unsupported placed furniture, fall back unsupported active backgrounds to the default room background, and show a one-shot update prompt when the current room contains newer shared decor than the client supports.
- Verification:
  - `dart format lib/features/shop/models/shop_item.dart lib/features/home/room_backgrounds.dart lib/features/shop/shop_view.dart lib/features/home/home_view.dart test/features/home/room_backgrounds_test.dart test/features/shop/shop_item_compatibility_test.dart`
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-04-01 Telegram-Style Chat Long-Press Overlay)
- [x] Inspect the active chat long-press route, message bubble renderers, and test seams to keep all action logic unchanged while replacing only the presentation layer.
- [x] Implement a custom full-screen Telegram-style long-press overlay with blurred backdrop, anchored message preview, emoji rail, and frosted options card.
- [x] Update focused widget/chat-route regressions plus task/memory notes, then run `flutter analyze` and `flutter test`.

# Review (2026-04-01 Telegram-Style Chat Long-Press Overlay)
- [x] Implemented and verified.
- Scope:
  - Replaced the chat long-press bottom sheet with a custom transparent overlay route in `lib/features/chat/chat_room_view_v2.dart`, keeping the original action dispatch and reaction toggling logic unchanged.
  - Added a Telegram-style UI in `lib/features/chat/widgets/chat_message_action_sheet.dart` with a blurred/dimmed backdrop, anchored message preview, frosted emoji rail, and frosted options card while preserving the same quick reactions, `More`, `Reply`, `Copy`, `Report`, and `Block` behaviors.
  - Added an overlay-safe text-preview renderer for long-press message previews so the new route can reuse the current bubble visual language without depending on the in-chat `flutter_chat_ui` provider tree, and kept feed/image previews on the existing card renderer.
  - Updated focused widget and chat-route regression coverage for the new overlay keys/structure and preserved optimistic quick-reaction + custom-emoji flows.
- Verification:
  - `flutter test test/features/chat/chat_message_action_sheet_test.dart`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "long press opens legacy message action sheet"`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "selecting an emoji in the long-press action sheet updates inline reaction chips optimistically"`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart --plain-name "selecting a custom emoji through more reactions updates inline chips optimistically"`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-31 Expand Chat Emoji Picker)
- [x] Inspect the current quick-reaction-only chat/photo picker surfaces and lock the shared full-picker integration points.
- [x] Add a shared full emoji picker surface plus `More` wiring for chat long-press, reaction details, and fullscreen photo viewer.
- [x] Update localized CTA copy, focused regression coverage, and memory-bank notes for the expanded reaction flow.
- [x] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-03-31 Expand Chat Emoji Picker)
- [x] Implemented and verified.
- Scope:
  - Added `emoji_picker_flutter` plus a new shared `showChatEmojiPickerSheet(...)` bottom sheet so every chat/photo reaction flow can open the same full emoji picker with search, categories, recents, and a few top suggestion chips.
  - Updated `ChatMessageActionSheet` to keep the existing 6 quick reactions while adding a `More` CTA, and rewired `ChatRoomViewV2` so the long-press path closes the quick sheet and then opens the full picker before sending the chosen emoji through the existing `_toggleReaction(...)` / `ChatMessageActionService.toggleReaction(...)` flow.
  - Updated `ChatReactionDetailsSheet` to add an in-sheet `More` action that opens the shared picker above the details surface, then refreshes the filtered reaction list in place after a custom emoji is selected.
  - Replaced the fullscreen photo viewer’s old quick-only reaction sheet with the same shared picker, added new localization keys for `More`, `All emoji`, and the emoji-search hint across all shipped locales, and documented the new behavior in the memory bank.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-31 WhatsApp-Style Chat Reactions Refresh)
- [x] Inspect the active chat reaction flow, existing reaction data contracts, and test seams so the new details sheet can replace the legacy action sheet cleanly.
- [x] Add the reaction detail model/repository read path plus the new WhatsApp-style reaction details bottom sheet UI.
- [x] Rewire `ChatRoomViewV2` so long-press and reaction-chip taps open the new sheet, keep quick reaction toggles working, and preserve reply/copy/report/block actions.
- [x] Add/update focused regression coverage, update the relevant memory-bank notes, and run `flutter analyze` plus `flutter test`.

# Review (2026-03-31 WhatsApp-Style Chat Reactions Refresh)
- [x] Implemented and verified.
- Scope:
  - Added `ChatMessageReactionDetail` plus a new `fetchReactionDetails(...)` repository path so chat can read per-user reaction rows without changing the existing write contract or schema.
  - Added a new `ChatReactionDetailsSheet` that shows a WhatsApp-style emoji filter bar plus reaction member list, while restoring the original `ChatMessageActionSheet` as the separate long-press surface.
  - Updated `ChatRoomViewV2` so long-press uses the legacy quick-action sheet, existing inline reaction chips open the dedicated reaction-details sheet pre-filtered to the tapped emoji, and in-sheet emoji taps mutate reactions while keeping the inline bubble chips in sync.
  - Added focused widget/repository/chat-route regression coverage and updated `memory-bank/database-schema.md`, `memory-bank/architecture.md`, and `memory-bank/progress.md` for the new reaction details flow.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-26 Replace Furniture +/- Buttons With Pinch Gesture)
- [x] Inspect the current furniture edit interaction flow and remove the now-obsolete button-based resize path cleanly.
- [x] Implement gesture-based furniture transforms in edit mode so single-finger drag still works and pinch-to-resize replaces the `+ / -` controls.
- [x] Update localized furniture edit guidance and project notes, then run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-03-26 Replace Furniture +/- Buttons With Pinch Gesture)
- [x] Implemented and verified.
- Scope:
  - Replaced the selected furniture `+ / -` overlay in `lib/features/home/home_view.dart` with gesture-based transforms: one-finger drag and two-finger pinch now update placed furniture position/scale directly, and the transform persists through the existing Supabase scale/position RPCs when the gesture ends.
  - Removed the obsolete button-based resize code path and updated all localized furniture edit hints to explain pinch resizing.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-26 Reset Furniture Mode Selection + Raise Max Scale To 2.0)
- [x] Inspect the current furniture-mode selection state and end-to-end scale-limit enforcement across Flutter and Supabase.
- [x] Reset transient furniture selection on mode entry so resize controls only appear after tapping a placed furniture item.
- [x] Raise the persisted furniture scale ceiling from `1.6x` to `2.0x` across Flutter math/constants and Supabase constraints/RPC clamp logic.
- [x] Update regression coverage and memory-bank/task notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-26 Reset Furniture Mode Selection + Raise Max Scale To 2.0)
- [x] Implemented and verified.
- Scope:
  - Updated Home furniture-mode entry to clear stale selected inventory/placed-furniture state before edit mode starts, so resize controls stay hidden until the user taps a specific placed furniture item.
  - Raised the shared furniture resize ceiling from `1.6x` to `2.0x` in Flutter sizing math and the live Supabase contract (`room_furniture_scale_range` and `update_room_furniture_scale`), keeping client/server persistence aligned.
  - Updated resize math regression coverage plus memory-bank/task notes to reflect the new selection-reset behavior and `2.0x` max scale.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-26 Fix Furniture Mode Scene Collapse)
- [x] Trace why entering furniture mode makes the pet field appear empty.
- [x] Remove the empty overlay child pattern that collapses the pet-field stack when no furniture is selected.
- [x] Run `flutter analyze` and `flutter test` to verify the scene stays visible in furniture mode.

# Review (2026-03-26 Fix Furniture Mode Scene Collapse)
- [x] Implemented and verified.
- Scope:
  - Fixed `lib/features/home/home_view.dart` so the selected-furniture controls overlay is only inserted into the pet-field `Stack` when a selected furniture item actually exists, preventing the stack from collapsing to zero size on furniture-mode entry.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-26 Fix Furniture Resize Controls Hit Testing)
- [x] Trace why tapping the selected furniture resize controls exits furniture mode instead of invoking the scale action.
- [x] Move the interactive resize controls to the Pet Home field overlay layer so the controls stay inside a real hit-testable region while remaining visually anchored to the selected furniture.
- [x] Run `flutter analyze` and `flutter test` to verify the hit-testing fix.

# Review (2026-03-26 Fix Furniture Resize Controls Hit Testing)
- [x] Implemented and verified.
- Scope:
  - Moved the selected furniture scale controls out of the individual furniture tile widget and into the parent Pet Home field stack in `lib/features/home/home_view.dart`, so the controls are hit-testable even when rendered above the selected furniture.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-26 Fix Furniture Resize Controls Overflow Follow-up)
- [x] Reproduce the new rendering assertion from the resize-controls overlay and identify which constraint path is now unbounded.
- [x] Replace the unconstrained overlay layout with an explicit-width positioning approach that can extend beyond the furniture tile without overflow or infinite-size assertions.
- [x] Run `flutter analyze` and `flutter test` to verify the follow-up fix.

# Review (2026-03-26 Fix Furniture Resize Controls Overflow Follow-up)
- [x] Implemented and verified.
- Scope:
  - Replaced the selected-furniture resize-controls overlay in `lib/features/home/home_view.dart` with a fixed-width, negatively offset `Positioned` layout instead of `OverflowBox`, keeping the controls centered above small furniture tiles without relying on unbounded-axis overflow behavior.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-25 Fix Shared Room Furniture Inventory + Add Resizable Furniture)
- [x] Verify the current Home/Shop furniture inventory and placed-furniture code paths, then lock the exact shared-inventory + resize implementation surface.
- [x] Add a forward-only Supabase migration that introduces shared room furniture inventory aggregation, room-wide placement validation, persistent `room_furniture.scale`, and a room-member-authorized scale update RPC.
- [x] Update Flutter Home and Shop to consume shared room furniture totals, support edit-mode furniture selection and `- / +` resizing, and keep realtime/reload behavior in sync with the new DB contract.
- [x] Add focused regression coverage for shared room inventory availability and furniture resize clamping/persistence, then update memory-bank notes and this task log review.
- [x] Run `flutter analyze` and `flutter test` before wrapping up.

# Review (2026-03-25 Fix Shared Room Furniture Inventory + Add Resizable Furniture)
- [x] Implemented and verified.
- Scope:
  - Added Supabase migration `20260325113000_shared_room_furniture_inventory_and_scale.sql`, applied it through Supabase MCP, and updated the live DB contract with `room_furniture.scale`, `get_room_furniture_inventory`, room-wide furniture placement validation, `update_room_furniture_scale`, and additive `room_total_quantity` purchase RPC fields.
  - Updated Home to load shared room furniture totals via RPC, compute room-wide available counts, parse/persist furniture `scale`, and support edit-mode placed-furniture selection with `- / +` resizing clamped to `0.8x..2.0x`.
  - Updated Shop to load room furniture ownership from the shared inventory RPC and to refresh furniture ownership counts from `room_total_quantity` after purchase.
  - Added focused regression coverage in `test/features/home/home_furniture_math_test.dart` and `test/features/home/widgets/home_room_inventory_panel_test.dart`, and updated memory-bank notes for the new shared furniture behavior.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-24 Review Shop + Chat Refactor)
- [x] Collect the current Shop/chat-related diffs and identify the files touched by the recent refactor.
- [x] Review the changed code for stability, security, and functional regressions, prioritizing concrete bugs and missing safeguards.
- [x] Summarize findings with exact file references and note any important testing gaps or residual risks.

# Review (2026-03-24 Review Shop + Chat Refactor)
- [x] Reviewed.
- Scope inspected:
  - Recent Shop/chat commits on `main`, especially `2859242`, `ce78aa9`, `14c9ebb`, `11c3484`, `7451463`, and `4691aee`.
  - Current implementations in `lib/features/shop/shop_view.dart`, `lib/features/shop/services/shop_purchase_handler.dart`, `lib/features/chat/chat_room_view_v2.dart`, `lib/features/chat/widgets/deterministic_chat_list.dart`, `lib/features/chat/widgets/chat_keyboard_dismiss_shell.dart`, and related tests.
- Verification notes:
  - Initial review run found three concrete issues:
    - `DeterministicChatList` forwarded descending visual indices into `flutter_chat_ui`, while `ChatController.messages` remained ascending; this broke package grouping assumptions in the bounded-window chat path.
    - Received-avatar taps in `ChatMessageEnvelope` still bubbled into the list-level backdrop dismiss handler.
    - `ShopPurchaseHandler` could surface success UI/analytics even when purchase RPCs returned no usable payload.
  - The focused Shop/chat suites in the committed tree also had stale test contracts after the list/banner refactors (`SingleChildScrollView` selector assumptions and mixed-case `Active` badge assertions).

# Plan (2026-03-24 Fix Shop + Chat Review Findings)
- [x] Preserve the current reversed chat UX while aligning the custom timeline builder with the canonical ascending message contract expected by `flutter_chat_ui`.
- [x] Harden the remaining functional edge cases from the review, including avatar tap dismissal and Shop RPC success handling.
- [x] Update focused regressions/tests to the new stable contracts, then re-run targeted and repo-required verification.

# Review (2026-03-24 Fix Shop + Chat Review Findings)
- [x] Implemented.
- Fixes:
  - `DeterministicChatList` now keeps the existing newest-at-bottom UX but translates visual indices back to the canonical ascending `ChatController` order before calling the package item builder. The timeline also exposes a stable `chatTimelineList` key so bounded-window tests no longer depend on the removed `SingleChildScrollView` implementation detail.
  - `ChatMessageEnvelope` now absorbs taps on the received avatar itself, so keyboard dismissal remains limited to true blank-space taps.
  - `ShopPurchaseHandler` now requires a parsed payload from each purchase RPC before updating balances/inventory or showing success UI; empty/malformed purchase responses now fail through the existing error path instead of silently reporting success.
  - Focused tests were updated to the preserved current UX/contracts: the Shop active badge now asserts against the localized uppercased copy, bounded-window chat tests target the keyed timeline and canonical latest-slice persistence contract, and the keyboard-open latest-jump monotonicity assertion now matches the reversed-list scroll metric direction (`0 == latest`).
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart` ✅
  - `flutter test test/features/chat/chat_message_envelope_test.dart` ✅
  - `flutter test test/features/shop/shop_featured_banner_test.dart` ✅
  - `flutter analyze` ✅
  - `flutter test` ✅

# Plan (2026-03-24 Clear Remaining Full-Test Failures)
- [x] Triage the remaining repo-wide red tests after the Shop/chat fixes and separate true regressions from stale expectations.
- [x] Repair the failing chat/Home/force-update suites with the smallest contract-aligned changes while preserving the shipped UX and current dialog layouts.
- [x] Re-run focused verification, `flutter analyze`, and full `flutter test`, then document the final green result.

# Review (2026-03-24 Clear Remaining Full-Test Failures)
- [x] Implemented.
- Fixes:
  - Cleared the remaining chat/Home test drift that surfaced after the Shop/chat refactor by aligning the suites with the current contracts instead of reverting product behavior. `home_game_status_bar_test.dart` is green again after restoring the floating title-only decor guidance contract (including the 5-second auto-dismiss/highlight expectations), `deterministic_chat_list_test.dart` now asserts the current reversed-list threshold/separator behavior, and `chat_keyboard_dismiss_behavior_test.dart` now exercises the intended composer-handle sweep path while the route-level dismiss shell preserves the supported drag-into-composer dismissal flow.
  - Cleared the last repo-wide red block in `force_update_gate_test.dart` by updating the suite to the current What's New dialog hierarchy. The redesigned dialog no longer renders the old visible `Version update` title, so the tests now assert the actual shipped markers (`Version 1.0.5`, `Stability & Security Update`, `What's new`, `Continue`) and verify the preserved vertical hierarchy instead of an obsolete horizontal placement assumption.
- Verification:
  - `flutter test test/features/home/widgets/home_game_status_bar_test.dart` ✅
  - `flutter test test/features/chat/deterministic_chat_list_test.dart` ✅
  - `flutter test test/features/chat/chat_keyboard_dismiss_behavior_test.dart` ✅
  - `flutter test test/shared/force_update/force_update_gate_test.dart` ✅
  - `flutter analyze` ✅
  - `flutter test` ✅

# Plan (2026-03-24 Investigate Debug Pro Override Not Reflected In Shop)
- [x] Trace the Debug Tools Pro toggle path and identify which local state/provider it changes.
- [x] Inspect the Shop membership active-state / CTA-disable logic and compare it against the debug override source of truth.
- [x] Document the exact mismatch causing Shop to still show a subscribable Pro membership after the debug override is enabled.

# Review (2026-03-24 Investigate Debug Pro Override Not Reflected In Shop)
- [x] Investigated and documented.
- Debug Tools toggles `_debugProPlan` in `HomeView`, persists it through `AppSettingsRepository.debugProPlanEnabled`, and exposes the merged access flag through `_hasProPlanAccess = (_isDebugAdmin && _debugProPlan) || _revenueCatProPlan`.
- When Home opens Shop, it correctly passes that merged result as `ShopView(isProUser: _hasProPlanAccess)`; the handoff point is not the bug.
- Inside `ShopView`, the debug/merged access flag is only used by `_hasProAdFreeAccess` for hiding ads. The subscription banner is built with `activeEntitlements: _activeEntitlements` only, so the banner ignores `widget.isProUser`.
- `ShopFeaturedBanner` then derives `isSubscribed` solely from `widget.activeEntitlements.contains(entitlementId)`, which means debug Pro access never flips the `Active` pill and never disables the purchase CTA.
- Existing widget coverage only tests the entitlement-backed subscribed case, so this debug-override path currently has no regression test.

# Plan (2026-03-24 Fix Debug Pro Override In Shop Banner)
- [x] Thread the merged Pro-access flag into the Shop subscription banner so debug Pro access and real entitlements share the same subscribed-state check.
- [x] Add a widget regression that covers `isProUser == true` with no active RevenueCat entitlement.
- [x] Re-run verification and document the result.

# Review (2026-03-24 Fix Debug Pro Override In Shop Banner)
- [x] Implemented.
- Fix:
  - `ShopView` now passes `widget.isProUser` into `ShopFeaturedBanner`.
  - `ShopFeaturedBanner` now treats a subscription as active when either debug/merged Pro access is already true or the matching RevenueCat entitlement is active.
  - Added a focused widget regression covering the debug override path, and aligned the existing banner test expectations with the current UI that no longer renders the old `PREMIUM` / `プレミアム` pill.
- Verification:
  - `flutter test test/features/shop/shop_featured_banner_test.dart` ✅
  - `flutter analyze` ✅
  - `flutter test` ❌
  - Full-suite `flutter test` still reports existing repo-wide failures (`Some tests failed` with `-14` outstanding in the current workspace run). This task did not triage those unrelated failures further.

# Plan (2026-03-24 Review Crashlytics Fatal for 1.0.5)
- [x] Confirm the active Firebase project/app and identify the newest fatal Crashlytics issue affecting `com.cc100053.pet` version `1.0.5`.
- [x] Fetch the selected issue details, sample events, and impact breakdowns needed to understand the crash path.
- [x] Map the failure path back to the current repo, determine whether the bug is still present, and document whether action is needed now.

# Review (2026-03-24 Review Crashlytics Fatal for 1.0.5)
- [x] Investigated and documented.
- Crashlytics MCP returned `404` for the Android app ID, so the available fatal data came from the iOS app ID in the same Firebase project. Both Firebase apps use the same bundle/package identifier `com.cc100053.pet`, so the issue still matches the user's report, but the usable evidence is from iOS Crashlytics.
- Newest `1.0.5`-only fatal issue:
  - Issue `4ae440d82840d916b0f9ef97ad713b34`
  - Title: `package:pet/shared/ui/cached_network_image_view.dart - CachedNetworkImageView._resolveCacheSize`
  - Subtitle: `FlutterError - Unsupported operation: Infinity or NaN toInt`
  - First seen: 2026-03-24 01:33 JST (`2026-03-23T16:33:48Z`)
  - Impact in the last 7 days: 3 fatal events, 1 impacted user, all on `1.0.5 (2)`, all on `iPhone 16 Plus / iOS 26.2.1`
- Root cause:
  - `CachedNetworkImageView._resolveDimension(...)` previously accepted any explicit positive dimension, including `double.infinity`.
  - The Memory calendar day-sheet passes `width: double.infinity` into `CachedNetworkImageView`, so `_resolveCacheSize(...)` later called `.round()` on a non-finite value and threw the fatal.
  - The crashing caller is the Memory bottom sheet in `lib/features/gallery/memory_calendar_view.dart` and the fixed guard now lives in `lib/shared/ui/cached_network_image_view.dart`.
- Current repo status:
  - `main` already contains the fix in commit `188f873` (`fix(images): guard non-finite cache dimensions`).
  - The current code in `lib/shared/ui/cached_network_image_view.dart` only accepts explicit dimensions when `explicit.isFinite && explicit > 0`, which prevents the crash path.
  - Regression coverage exists in `test/shared/ui/cached_network_image_view_test.dart` for the `width: double.infinity` case.
- Action needed now:
  - No new code fix is needed in the repo for this issue.
  - Product/release action may still be needed if users are still on `1.0.5 (2)`, because the crash was emitted by that shipped build and the source fix is now in the newer `1.0.6+1` repo state.
  - Recommended next step is to confirm the fixed build has shipped or ship it if it has not, then monitor whether issue `4ae440d82840d916b0f9ef97ad713b34` stops receiving fresh events from versions newer than `1.0.5 (2)`.

# Plan (2026-03-23 Refine Chat Latest Jump + Scroll Surface)
- [x] Verify why the current chat viewport still feels like the whole background moves during history/latest scrolling and identify the exact padding/viewport behavior to tighten.
- [x] Adjust the active chat route so scroll transitions move only message content while preserving the user's visible reading anchor, including when already at the latest messages.
- [x] Fix the `Latest` pill so tapping it while the keyboard is open keeps the composer focused instead of collapsing the keyboard, and add regression coverage.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-23 Refine Chat Latest Jump + Scroll Surface)
- [x] Implemented and verified.
- Root change:
  - Tightened the `Latest` interaction so it no longer counts as a tap-outside of the composer. The pill now lives inside a `TextFieldTapRegion`, is marked `canRequestFocus: false`, and is excluded from the backdrop unfocus handler, so keyboard-open taps jump straight to latest without collapsing the keyboard.
  - Reworked keyboard-open room behavior so the whole interactive chat surface moves upward with the keyboard while the background stays behind it, instead of locking historical reading to one fixed viewport anchor. This makes the currently viewed message lift upward together with the composer no matter where the user is in the timeline.
  - Stopped restoring a history-mode anchor on keyboard metric changes, since that was canceling the intended upward push and making non-latest positions feel stationary while only latest-mode visibly moved.
  - Added widget regressions that cover keyboard-open `Latest` focus retention, composer upward movement, and history-mode upward push while keeping the viewed message visible above the composer.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Refine Shop Success Icon + Room Decor Hint UI)
- [x] Update Shop success floating notices so the leading icon uses the purchased item's own visual instead of a generic success checkmark.
- [x] Refine the Pet Home room-decor guidance into a floating title-only overlay that does not shift layout, auto-dismisses after 5 seconds, and adds a looping highlight around the inventory/decor action.
- [x] Update localization/tests/docs as needed, then run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-03-23 Refine Shop Success Icon + Room Decor Hint UI)
- [x] Implemented and verified.
- Scope:
  - Shop success floating cards now render the purchased item's own visual payload: furniture keeps its emoji/item icon, backgrounds show a room-preview tile, and pack-style items fall back to their matching candy/diamond art instead of the old generic success check.
  - Pet Home room-decor guidance now stays as a floating title-only chip anchored above the inventory/decor action, so the status bar layout no longer shifts when the hint appears.
  - The decor action now gets a looping sweep/glow border while the hint is active, and the guidance dismisses automatically after 5 seconds or immediately when inventory opens.
  - Updated localized `roomDecorHintTitle` copy plus focused widget tests for the success-card icon payload, the floating decor hint, the highlight affordance, and the 5-second auto-dismiss path.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Refine Chat History Keyboard Anchor + Latest Transition)
- [x] Reproduce the remaining chat regressions in code/tests and identify why history-mode keyboard open still fails to preserve the actually viewed content while `Latest` still jitters.
- [x] Upgrade viewport preservation to anchor the visible reading point instead of a message top edge, and preserve that anchor across composer-height changes as well as keyboard metric changes.
- [x] Replace the `Latest` reset path with a transition window that avoids extent shrink before the explicit bottom animation completes, then add a monotonic-scroll regression and re-run verification.

# Review (2026-03-23 Refine Chat History Keyboard Anchor + Latest Transition)
- [x] Implemented and verified.
- Root change:
  - History-mode viewport preservation now stores an actual reading anchor inside the chosen message surface (`messageLocalY + globalY`) instead of pinning the message's top edge, so keyboard/composer height changes preserve the line the user was reading rather than leaving the content visually behind while only the background resizes.
  - Composer-height changes in history mode now reuse the same anchor-preservation path instead of only handling live-mode latest pinning.
  - `Latest` no longer resets straight to the newest 20-message window before animating. The route now transitions through a merged live window, runs one bottom animation, and only then collapses back to the newest page, removing the previous extent-shrink down-then-up jitter.
  - Added a stronger regression that samples scroll offsets frame-by-frame during `Latest` with keyboard-open delayed reply-preview expansion and asserts the motion stays monotonic instead of oscillating.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Stabilize Chat Keyboard + Latest Scroll)
- [x] Convert the active chat route to a viewport-driven keyboard layout so the keyboard resizes the visible area instead of being simulated through manual keyboard insets.
- [x] Replace max-scroll latest jumps with composer-aware latest alignment and coalesce the route's bottom-lock sync triggers.
- [x] Preserve the current reading viewport across keyboard open/close when the user is not pinned to latest, while keeping live-mode rooms pinned above the composer.
- [x] Add focused widget coverage for keyboard-open viewport preservation and latest-entry/latest-button stability, then run `flutter analyze` and `flutter test`.

# Review (2026-03-23 Stabilize Chat Keyboard + Latest Scroll)
- [x] Implemented and verified.
- Root change:
  - `ChatRoomViewV2` now lets the scaffold/body resize with the keyboard and stops feeding runtime keyboard height into manual composer/list/jump-pill positioning. The composer/list bottom spacing now only uses safe-area spacing plus measured composer height.
  - The route replaced raw `maxScrollExtent` latest jumps with a viewport-aware sync path that aligns the newest message against the actual visible bottom above the composer, using the measured composer interaction region as the occlusion boundary.
  - Keyboard metric changes now capture the current viewport anchor when the user is browsing history and restore that anchor after layout settles, while live-mode / explicit latest flows stay pinned to the newest message instead.
  - Added widget coverage for keyboard-open room entry, keyboard-open `Latest`, and mid-history keyboard-open anchor preservation on top of the existing bounded-window suite.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Shop Success Floating Cards + Room Decor Guidance)
- [x] Generalize Shop floating notices so purchase success uses the same floating-card system as shortage feedback, including optional return-to-room CTA for furniture/background purchases.
- [x] Replace bare Shop route returns with a typed result and wire Home to consume the returned room/decor-hint intent.
- [x] Add the transient Pet Home room-decor guidance bubble near the inventory/backpack control and dismiss it when inventory opens or the user closes it.
- [x] Add/update localization and widget coverage, then run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.

# Review (2026-03-23 Shop Success Floating Cards + Room Decor Guidance)
- [x] Implemented and verified.
- Scope:
  - Generalized the Shop floating notice model so purchase success now uses the same in-shop floating card system as shortage feedback, with optional copy and CTA support.
  - Added a typed `ShopRouteResult` so room-scoped cosmetic purchases can return Home with an explicit `showRoomDecorHint` intent instead of overloading a bare room-id string.
  - Wired Pet Home to surface a one-shot room-decor guidance bubble next to the inventory/backpack control after the user returns from a furniture/background purchase, and dismiss that hint when inventory opens or the user closes it.
  - Added localized copy plus focused widget coverage for the new success notice, route-result factories, Home guidance bubble, and restored featured-banner premium/status badges required by the existing suite.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Investigate AdMob app-ads.txt Authorization)
- [x] Confirm the repo contains the expected `app-ads.txt` content and identify where it is hosted from.
- [x] Verify the live hosted `app-ads.txt` response and headers on the public site.
- [x] Cross-check repo/App Store metadata for the developer website domain that AdMob is expected to crawl, then document the likely mismatch/risk.

# Review (2026-03-23 Investigate AdMob app-ads.txt Authorization)
- [x] Investigated and documented.
- Findings:
  - The repo already ships [html/app-ads.txt](/Users/fatboy/pet/html/app-ads.txt) with the exact AdMob line: `google.com, pub-5585639540156039, DIRECT, f08c47fec0942fa0`.
  - Firebase Hosting is configured to publish the `html/` folder via [firebase.json](/Users/fatboy/pet/firebase.json), so the expected public URL is `https://pet-app-702be.web.app/app-ads.txt`.
  - Live verification on 2026-03-23 confirmed `https://pet-app-702be.web.app/app-ads.txt` returns `HTTP/2 200`, `content-type: text/plain; charset=utf-8`, and the correct file contents.
  - Repo/App Store metadata consistently references `pet-app-702be.web.app` for privacy/support URLs, but the checked App Store localization snapshot in [locs.json](/Users/fatboy/pet/locs.json) only shows `marketingUrl` on the Japanese localization and not on the English, Korean, or Traditional Chinese localizations.
  - Inference: the low AdMob authorization rate is more likely a store-listing website association problem than a file-hosting problem. If the developer website / marketing URL is missing or inconsistent for some storefront/localization paths, AdMob may only be able to validate a subset of requests.
- Verification:
  - `curl -I -sS https://pet-app-702be.web.app/app-ads.txt`
  - `curl -sS https://pet-app-702be.web.app/app-ads.txt`

# Plan (2026-03-23 Move Shop Icons Into assets/shop/icon)
- [x] Move the Shop-specific icon assets from `assets/icon/shop/` into `assets/shop/icon/` and update the declared asset bundle path.
- [x] Rewrite all app code that loads Shop icons so it points at the new `assets/shop/icon/*` paths.
- [x] Run verification, update memory-bank notes, and record the asset move outcome below.

# Review (2026-03-23 Move Shop Icons Into assets/shop/icon)
- [x] Implemented and verified.
- Scope:
  - Moved the Shop icon files into `assets/shop/icon/` and removed the old empty `assets/icon/shop/` folder.
  - Updated `pubspec.yaml` and all in-app image asset references to use the new Shop icon path.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Rename Store Feature To Shop)
- [x] Inventory every Store-related feature file, class, import, asset, and localization touchpoint that needs renaming while preserving external compatibility contracts like App Store URLs and `store_purchase`.
- [x] Rename the Store feature folders/files/types/assets to Shop and update in-app Shop copy/localization references across the app.
- [x] Regenerate localizations, run verification, update memory-bank notes, and record the rename outcome below.

# Review (2026-03-23 Rename Store Feature To Shop)
- [x] Implemented and verified.
- Scope:
  - Renamed the app feature module from Store to Shop across feature files, tests, imports, assets, and feature-owned widget/class names.
  - Updated in-app localization keys/copy so the user-facing section now presents as Shop instead of Store.
  - Preserved external/backward-compatible contracts such as Apple `App Store` integrations, config keys like `store_url`, review fallback behavior, and message payload kinds like `store_purchase`.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Harden Intermittent Chat Send Crash Path)
- [x] Inspect the active chat send flow for intermittent crash candidates around async lifecycle, composer state, and route teardown.
- [x] Harden the most plausible send-time race(s) in `ChatRoomViewV2` with minimal behavioral change.
- [x] Re-run targeted/full verification, update memory-bank notes, and record the investigation outcome below.

# Review (2026-03-23 Harden Intermittent Chat Send Crash Path)
- [x] Implemented and verified.
- Investigation:
  - The active send path in `ChatRoomViewV2._handleSendMessage(...)` performs multiple async steps after the user taps send: latest-window reconciliation, optimistic insert, Supabase insert, optimistic removal, and best-effort refresh.
  - Before this fix, the route only flipped `_sending = true` after awaiting `_ensureLatestWindowForCompose()`, leaving a short re-entrancy window for a second tap/submit to enter a parallel send path.
  - On send failure, the `catch` branch restored `_composerController.text` and selection before re-checking `mounted`, so a late failure that arrived after the route/controller had been disposed could hit a `TextEditingController used after being disposed` style crash instead of a normal error snackbar.
- Fix:
  - `_handleSendMessage(...)` now exits immediately when `_sending` is already true and marks the route as sending before awaiting any pre-send async work.
  - The failure-recovery path now checks `mounted` before mutating the composer controller or reply state.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-23 Fix Memory Photo Infinity Cache Size Crash)
- [x] Trace the Memory photo crash path and confirm which `CachedNetworkImageView` call site can feed `Infinity` or `NaN` into cache-size rounding.
- [x] Harden shared cache-size resolution so explicit non-finite dimensions fall back to layout constraints instead of crashing.
- [x] Add focused regression coverage, update memory-bank notes, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-23 Fix Memory Photo Infinity Cache Size Crash)
- [x] Implemented and verified.
- Root cause:
  - `Memory` day-sheet photos pass `width: double.infinity` into `CachedNetworkImageView` so the image can fill the available sheet width.
  - `_resolveDimension(...)` accepted any explicit size greater than zero, including `double.infinity`, and `_resolveCacheSize(...)` later called `.round()` on that non-finite value.
  - That produced the Crashlytics `Unsupported operation: Infinity or NaN toInt` failure in `CachedNetworkImageView._resolveCacheSize`.
- Fix:
  - Treat explicit dimensions as valid only when they are finite and positive.
  - When callers pass `double.infinity`, fall back to the finite layout constraint from `LayoutBuilder`, preserving the intended full-width layout without crashing the cache-size calculation.
  - Added a widget regression that covers the `width: double.infinity` path and asserts no exception is thrown.
- Verification:
  - `flutter test test/shared/ui/cached_network_image_view_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-23 Add Store Insufficient Funds Feedback)
- [x] Keep non-IAP store grid buy taps active when the user lacks enough candy or diamonds so the existing localized snackbar feedback can surface.
- [x] Add focused widget coverage for coin-shortage, diamond-shortage, and owned-item tap behavior in the store grid card.
- [x] Update memory-bank/progress notes if needed, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-23 Add Store Insufficient Funds Feedback)
- [x] Implemented and verified.
- Root change:
  - Extracted a reusable `StoreGridItemCard` widget so the single-buy grid-card routing is testable in isolation while preserving the existing store card visuals.
  - Non-IAP `Buy` taps now stay active for insufficient-balance states and route into the existing `_purchaseItem(...)` / `_purchaseDiamondItem(...)` guards, but the old bottom snackbar was replaced with a themed floating store notice that shows the localized insufficient-funds copy plus the current/required balance in a game-style card.
  - Added a shared raised-button shell so the normal store purchase CTAs press in with the same 3D interaction feel as the subscription banner CTA instead of staying visually static on tap.
  - Owned items, unavailable IAP items, and recovery-letter cards without a valid departed-pet target remain non-interactive.
  - Cleaned pre-existing unused store declarations so `flutter analyze` returns clean again, and restored the featured subscription banner's localized premium/title/status-owned behavior so the full suite stays green.
- Verification:
  - `flutter test test/features/store/store_grid_item_card_test.dart`
  - `flutter test test/features/store/store_featured_banner_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-21 Fix Store Rebuild Regressions)
- [x] Restore the featured subscription banner state handling so active subscribers see the correct localized status/renewal messaging and a disabled owned CTA.
- [x] Remove the hard-coded banner copy and restore a full theme preview path for background items while keeping the new single buy action.
- [x] Add focused regression coverage for the restored store behaviors, update memory-bank notes, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-21 Fix Store Rebuild Regressions)
- [x] Implemented and verified.
- Root change:
  - `StoreFeaturedBanner` now receives the active entitlement set and current purchase/loading flags from `StoreView`, recomputes the subscription CTA state per item, restores localized premium/status/renewal copy, and disables the CTA with an owned label for already-entitled users instead of always firing a purchase callback.
  - Removed the banner’s hard-coded `'Pro'` / `'プレミアム'` strings and stopped mutating localized title/description strings with `replaceAll(...)`; the banner now renders the existing localized store keys directly.
  - Restored background preview access by adding a dedicated preview affordance to background cards and reintroducing the full room-theme preview dialog through a reusable `showStoreThemePreviewDialog(...)` helper, while preserving the new single-buy card action.
  - Added widget coverage for the banner’s active-state/localization behavior and for the restored theme preview dialog. Also cleaned the unused imports/constants from the rebuild so `flutter analyze` is fully clean again.
- Verification:
  - `flutter test test/features/store/store_featured_banner_test.dart test/features/store/store_theme_preview_dialog_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-21 Investigate Intermittent Feed Camera Stuck After Send)
- [x] Trace the send path from `FeedCaptureView` back to Pet Home and confirm where a synchronous exception can block `Navigator.pop()`.
- [x] Harden the feed send callbacks so optimistic/upload callback failures do not strand the camera route, and add lifecycle guards on the Home feed handlers.
- [x] Add focused regression coverage, update memory-bank notes, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-21 Investigate Intermittent Feed Camera Stuck After Send)
- [x] Implemented and verified.
- Root cause:
  - `FeedCaptureView` called its parent `onOptimisticMessage` callback synchronously before `Navigator.pop()`. If the parent callback threw, `_sendFeed()` stayed on the feed page and surfaced a send error instead of returning to Pet Home.
  - The Home feed handlers (`_handleOptimisticFeed`, `_handleFeedUploadCompleted`, `_handleFeedUploadFailed`) mutated Home state through `_setStateForFeedOrchestrator()` without an upfront `mounted` guard, which left them vulnerable to lifecycle races if Home had been torn down while the feed route was still active.
  - Because this path depends on route timing and widget lifecycle, it matches the user-reported symptom of an intermittent, hard-to-reproduce failure rather than a deterministic navigation bug.
- Fix:
  - Added `dispatchFeedCaptureCallback()` in `FeedCaptureView` so optimistic/upload callbacks are fail-safe: exceptions are reported through `FlutterError.reportError`, but they no longer block the camera route from popping.
  - Added `mounted` guards at the start of the Home feed callbacks so stale Home states do not call `_setStateForFeedOrchestrator()` after teardown.
  - Added a regression test that verifies the new callback wrapper still executes callbacks and swallows thrown exceptions instead of propagating them.
- Verification:
  - `flutter test test/features/feed/feed_capture_view_callback_safety_test.dart`
  - `flutter test`
  - `flutter analyze` (reports 4 pre-existing warnings in `home_game_status_bar.dart` and `store_view.dart`, unrelated to this change)

# Plan (2026-03-20 Fix Chat Latest Scroll Visibility)
- [x] Trace the entry/jump-to-latest scroll path and identify why the newest message can end up slightly hidden under the composer.
- [x] Implement a pinned-to-latest follow-up scroll path so live-mode rooms stay anchored when later layout updates change message/composer height.
- [x] Add regression coverage for both initial room entry and the `Latest` pill path with delayed height-affecting updates.
- [x] Update memory-bank notes, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-20 Fix Chat Latest Scroll Visibility)
- [x] Implemented and verified.
- Root cause:
  - The chat route scrolled to `position.maxScrollExtent` only once when entering the room or tapping `Latest`.
  - After that first scroll, later height-affecting updates could still land: composer measurement, reply-preview hydration, sender-profile hydration, and reaction summary updates. Those post-scroll layout changes increased the timeline height slightly, leaving the newest message partially hidden behind the composer even though the route had already "jumped to latest."
- Fix:
  - Added a live-mode `shouldKeepLatestVisible` check and a follow-up latest-scroll scheduler with frame-based retries, so rooms already pinned near the bottom automatically re-anchor after later height changes.
  - Applied that bottom-pin behavior to composer height changes plus async profile/reply/reaction hydration paths, which are the main late layout-expansion sources in this route.
  - Added regression coverage that simulates delayed reply-preview loading after both room entry and `Latest` pill navigation, then asserts the newest message surface remains fully above the composer input.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-20 Telegram-Style Chat Polish Pass)
- [x] Flatten reply preview surfaces in composer and message bubbles so replies stay legible without consuming as much vertical space.
- [x] Make grouped message runs read more clearly by tightening inter-bubble spacing and varying grouped bubble corners for first/middle/last positions.
- [x] Replace the generic jump-to-latest FAB with a more semantic chat pill that communicates both direction and pending new-message count.
- [x] Add/update widget coverage for the new reply-preview density, grouped bubble presentation, and jump-to-latest affordance.
- [x] Update memory-bank notes, run `flutter analyze` and `flutter test`, and record the verification below.

# Review (2026-03-20 Telegram-Style Chat Polish Pass)
- [x] Implemented and verified.
- Root change:
  - `ChatReplyPreviewPanel` now uses denser compact spacing/typography, and both bubble reply strips plus the composer reply strip now clamp preview text to one line. The composer also removes the extra divider row and folds the cancel affordance into the preview row, which keeps reply state visible without pushing the input down as much.
  - Grouped message runs now apply tighter outer spacing in `ChatMessageEnvelope` and dynamic Telegram-style corners in both text bubbles and feed cards, so consecutive messages from the same sender visually read as one stack instead of separate detached cards.
  - The old floating jump button is now a labeled `Latest` pill with the existing pending-count badge, which makes the action feel like chat navigation instead of a generic FAB while preserving the reset-to-latest behavior.
  - Added widget coverage for the flatter reply preview panel, the new jump-to-latest pill, and tighter grouped-message spacing while keeping prior bounded-window/history tests green.
- Verification:
  - `flutter gen-l10n`
  - `flutter test test/features/chat/chat_reply_preview_panel_test.dart`
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-20 Fix Chat Room Auto Refresh on New Messages)
- [x] Trace `ChatRoomViewV2` realtime message updates, history-mode buffering, and foreground notification handling to find why newly arrived messages can fail to appear while the room is open.
- [x] Implement the smallest fix that restores automatic visible refresh for newly arrived chat messages without regressing bounded-window/history behavior.
- [x] Add regression coverage, run `flutter analyze` and `flutter test`, and record the outcome below.

# Review (2026-03-20 Fix Chat Room Auto Refresh on New Messages)
- [x] Implemented and verified.
- Root cause:
  - `ChatRoomViewV2` relied on the live Supabase channel for in-room freshness but had no lifecycle reconciliation when the route resumed after a backgrounded period.
  - In the affected path, the user was still logically "in chat", a push notification could arrive while the app was backgrounded, and on return the room sometimes kept showing the pre-background latest window because no explicit `_refreshLatest()` ran on resume.
  - This matched the symptom where notification delivery proved a new message existed, but the room view did not visibly refresh until another manual action happened.
- Fix:
  - `ChatRoomViewV2` now implements `WidgetsBindingObserver` and triggers a best-effort `_refreshLatest()` whenever the route resumes, as long as it is not already loading.
  - The refresh uses the existing bounded-window merge path, so live-mode rooms pull in the latest server page without changing the established history-mode/load-more architecture.
  - Added a widget regression test that simulates a background/resume gap with realtime disabled, appends a new canonical server message, resumes the app lifecycle, and asserts the new message becomes visible.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-20 Investigate Missing Whats New on 1.0.5 Upgrade)
- [x] Trace the `What's New` trigger path in app startup, including version detection, stored Hive keys, and ForceUpdateGate sequencing.
- [x] Verify the bundled `1.0.5` release-note content and existing tests/logic to determine which gate suppressed the modal after upgrade.
- [x] Record the root cause, impact, and recommended fix or follow-up in this file after verification.

# Review (2026-03-20 Investigate Missing Whats New on 1.0.5 Upgrade)
- [x] Implemented and verified.
- Root cause:
  - The shipped `What's New` gate only compared `PackageInfo.version`, so `1.0.5+1 -> 1.0.5+2` never counted as an upgrade because both launches looked like public version `1.0.5`.
  - The feature itself was first introduced in commit `370c06c` together with app build `1.0.5+1`, so upgrades from pre-tracking builds had no stored `last_launched_app_version` yet and were treated like fresh installs.
  - `WhatsNewService.prepareForLaunch()` also persisted `last_launched_app_version` immediately before the dialog actually rendered, which meant any first-launch interruption could permanently suppress the modal on later relaunches.
- Fix:
  - Added persisted `last_launched_app_release_signature` tracking so `ForceUpdateGate` and `WhatsNewPolicy` can detect same-public-version build upgrades when the current version's modal was never shown.
  - Added a legacy-install signal from `AppSettingsRepository.init()` using the pre-existing `app_settings` Hive box, allowing the first tracked `What's New` release to show for upgraded installs that predate version tracking without showing on true fresh installs.
  - Deferred launch-state persistence until the modal is actually dismissed (or until the policy decides no modal should show), preventing first-launch interruptions from permanently marking the version as already launched.
  - Added policy and gate regression tests covering legacy installs, same-version build upgrades, and deferred persistence behavior.
- Verification:
  - `flutter test test/shared/whats_new/whats_new_policy_test.dart`
  - `flutter test test/shared/force_update/force_update_gate_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-20 Telegram-Style Sender Name Grouping)
- [x] Use existing chat `groupStatus` metadata so received sender names only render on the first message in a grouped run.
- [x] Apply the same sender-name rule to both text bubbles and feed cards without changing sent/system/reply behavior or avatar grouping.
- [x] Add widget coverage for grouped and broken-group sender-name visibility, update repo notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-20 Telegram-Style Sender Name Grouping)
- [x] Implemented and verified.
- Root change:
  - `ChatRoomViewV2` now passes a `showSenderName` flag into both `_TelegramTextMessageBubble` and `_FeedCard`, using existing `flutter_chat_ui` `groupStatus.isFirst` metadata so received sender names only render on the first message in a grouped run.
  - Sent messages, system pills, reply previews, and received-avatar grouping remain unchanged. Avatars still follow the existing `groupStatus.isLast` rule.
  - Added a small pagination-boundary exception in history mode so the previously visible top message keeps its sender label when older pages are prepended; this preserves the existing viewport-anchor behavior instead of causing a visible jump during load-more.
  - Added widget coverage for grouped text+feed messages and for timeout-broken groups that should re-show the sender name.
- Verification:
  - `flutter test test/features/chat/chat_room_view_v2_bounded_window_test.dart`
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-19 Fix HomeView Crashlytics Lifecycle Crashes)
- [x] Guard the `HomeView` pet refresh async path so it no longer touches `context` or `setState` after disposal.
- [x] Guard the furniture inventory async path with the same mounted checks to prevent the fresh Crashlytics fatal.
- [x] Update repo notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Fix HomeView Crashlytics Lifecycle Crashes)
- [x] Implemented and verified.
- Root change:
  - Added mounted guards immediately after the awaited pet-id and pet-state fetches in `HomeView._refreshPetState`, and before the error UI update in its `catch`, so room-entry work now exits quietly if `HomeView` was disposed mid-flight.
  - Added the same post-await / catch mounted guards in `HomeView._loadFurnitureInventory`, preventing the store inventory refresh path from calling `AppLocalizations.of(context)!` or `setState` on a dead `State`.
  - This directly addresses the fresh Crashlytics fatals `9861065cc5b9361c4c837c524cfa7380` and `e671d70a27168c4d25cfa75d9998b128`.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Crashlytics New Issues Triage)
- [x] Confirm the active Firebase project/app and pull the newest iOS Crashlytics issues, affected versions, and recent sample events.
- [x] Map the new issue paths back to the current repo to determine whether each issue is current code, already-fixed old-build noise, or external/transient behavior.
- [x] Record the triage outcome, action decision, and recommended next steps.

# Review (2026-03-19 Crashlytics New Issues Triage)
- [x] Investigated and summarized.
- Scope:
  - Firebase MCP target confirmed as `pet-app-702be`, using iOS app `1:69520994244:ios:d6fc14579fda1a1ca33e91`.
  - Current repo version is `1.0.5+1` from `pubspec.yaml`, while the newest sampled Crashlytics events are on shipped version `1.0.4 (1)`.
- Findings:
  - `9861065cc5b9361c4c837c524cfa7380` (`_HomeViewState._refreshPetState.<fn>`, 2 fatal events / 2 users, first seen 2026-03-19):
    - Still present in current repo logic. `home_view.dart` awaits room-entry work and then calls `setState` with `AppLocalizations.of(context)!` inside `_refreshPetState` without a pre-check that the widget is still mounted, so a disposed `State` can crash on `State.context`.
    - Supporting current code: `lib/features/home/home_view.dart` around the current async path at lines 1797-1841.
  - `e671d70a27168c4d25cfa75d9998b128` (`_HomeViewState._loadFurnitureInventory.<fn>`, 1 fatal event / 1 user, first seen 2026-03-19):
    - Same root class and also still present in current repo logic. `_loadFurnitureInventory` does async Supabase fetches, then calls `setState` / `AppLocalizations.of(context)!` without guarding for disposal after the await.
    - Supporting current code: `lib/features/home/home_view.dart` around the current inventory path at lines 2763-2814.
  - `6cd7b77a79bd9f95739614da34231c2c` (Flutter Impeller `shadow_path_geometry.cc`, 2 fatal events / 2 users in the last 7 days, first seen 2026-03-17):
    - Still open and affecting `1.0.4 (1)`, but the blamed frame is fully inside Flutter raster/Impeller, not app Dart code.
    - Recent events show this happens after navigation/room-switch activity under high memory pressure, but current evidence is not enough to pin a precise app-owned root cause.
  - `adf4620a60fc4130740584cf31e3ba51` (`invalid_invite`, 2 non-fatal events / 2 users in the last 7 days):
    - This is user-facing bad invite code / expired invite behavior already recorded as `fatal: false`, not a crash regression.
- Action decision:
  - Action is needed now for the two fresh `home_view.dart` fatal issues because they are real lifecycle bugs in code that still exists in the current repo and can affect the next release unless fixed.
  - The Impeller crash should be monitored/instrumented separately unless the user wants a deeper investigation pass focused on Flutter engine workarounds or memory correlations.

# Plan (2026-03-19 Nudge Chat Avatar Upward)
- [x] Add a proportional upward offset to the received-message sender avatar while preserving the existing Telegram-style last-message anchor rule.
- [x] Extend widget coverage for the proportional avatar offset and update memory/task notes.
- [x] Run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Nudge Chat Avatar Upward)
- [x] Implemented and verified.
- Root change:
  - `ChatMessageEnvelope` now applies a small proportional upward `Transform.translate` offset (`10%` of the 32px avatar size) to the received sender icon while keeping the existing bottom-anchored last-message grouping rule intact.
  - Extended `chat_message_envelope_test.dart` so the received-avatar test now verifies both the fixed left slot width and the expected proportional upward offset relative to the message bubble.
  - Updated progress/task notes to describe the visual nudge without changing the Telegram-style anchor semantics.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Undo Chat Avatar Row Alignment)
- [x] Revert the received-message avatar row alignment tweak so the sender icon stays anchored to the last message in the grouped stack.
- [x] Remove the temporary top-alignment regression assertion and correct the related memory/task notes.
- [x] Run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Undo Chat Avatar Row Alignment)
- [x] Implemented and verified.
- Root change:
  - Restored `ChatMessageEnvelope` received rows to bottom alignment so the sender icon remains anchored to the last message in the grouped received stack.
  - Removed the temporary top-edge assertion from the envelope widget test while keeping the existing spacer/alignment coverage for Telegram-style avatar placement.
  - Corrected task and memory notes to reflect the reverted behavior, and added a lesson to avoid changing avatar-anchor semantics when the user only wants a high/low adjustment.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Stabilize Chat History Loading)
- [x] Remove layout-affecting inline history-loading UI from the deterministic chat list.
- [x] Add top-overlay history loading feedback and anchor-based viewport preservation in `ChatRoomViewV2`.
- [x] Extend chat widget tests for overlay rendering and viewport stability, update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Stabilize Chat History Loading)
- [x] Implemented and verified.
- Root change:
  - `DeterministicChatList` no longer inserts an inline load-more spinner, so older-history fetches stop changing the scrollable timeline height mid-scroll.
  - `ChatRoomViewV2` now shows a compact non-interactive top overlay while loading older messages and preserves the viewport by re-anchoring to the first visible message across follow-up frames after older pages are prepended.
  - Added regression coverage for the new overlay behavior and for keeping the visible viewport effectively anchored during older-page loads; exposed stable per-message surface keys for widget assertions without changing product behavior.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Remove Unused Petcoins120 IAP)
- [x] Confirm whether any active store catalog row still references the retired `Petcoins120` App Store product.
- [x] Remove or deactivate the retired coin-pack reference from the live Supabase `items` catalog and commit the same change into local migrations/seed data.
- [x] Update task tracking and memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Remove Unused Petcoins120 IAP)
- [x] Implemented and verified.
- Root change:
  - Confirmed the live `public.items` catalog on the repo-target `ilxzpszgirhwxpeocygs` project no longer exposed `Petcoins120` as an active item, but the inactive `iap_coin_pack_small` row still carried stale IAP metadata.
  - Applied Supabase migration `20260319110000_remove_retired_petcoins120_product_reference.sql` locally and via MCP so the retired row keeps its historical inactive record while dropping `iap_product_id`, `iap_type`, and `coin_amount`.
  - Updated memory-bank notes so the current store architecture/progress now reflect that only the monthly subscription and diamond pack remain part of the live IAP integration surface.
- Verification:
  - Re-queried live `public.items` after the migration and confirmed `iap_coin_pack_small` metadata no longer contains `Petcoins120`.
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Chat Date Labels + Self-Action Unread)
- [x] Restore chat day separators in the active deterministic timeline with the previous Today/Yesterday/date formatting rules.
- [x] Make the self-action unread decision explicit and add regression coverage for self feed/self system vs other-user messages.
- [x] Add and apply a Supabase migration so new `clean_poop` system messages carry `sender_id = auth.uid()`.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Chat Date Labels + Self-Action Unread)
- [x] Implemented and verified.
- Root change:
  - `DeterministicChatList` now restores localized day separators in the active chat timeline and includes regression coverage for one-day, multi-day, and today/yesterday rendering.
  - Home unread increments now flow through `home_unread_rules.dart`, making the self-message rule explicit and test-covered without changing unread behavior for other users' text/system messages.
  - Added and applied Supabase migration `20260319091549_preserve_clean_poop_actor_for_unread.sql`, updating `clean_poop` so only future clean-poop system messages carry `sender_id = auth.uid()` for actor-safe unread reconciliation.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-19 Bounded Chat Window Pagination)
- [x] Add bounded chat-window state ownership for latest/live/history slices and pending live message tracking.
- [x] Limit chat cache hydration/persistence to the latest 20 canonical messages per room.
- [x] Refactor `ChatRoomViewV2` to use automatic older pagination with an 80-message in-memory cap and reset-to-latest behavior.
- [x] Add repository, helper, and chat widget tests for the bounded-window flows.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-19 Bounded Chat Window Pagination)
- [x] Implemented and verified.
- Root change:
  - Added `ChatWindowState` so chat now has one bounded state owner for live/latest vs history mode, pending realtime counts, prepend-older trimming, and latest-window resets.
  - `ChatMessageRepository` cache hydration/persistence now stays on the newest 20 canonical messages per room, which removes the previous 200-message cold-open cache spike.
  - `ChatRoomViewV2` now opens on the latest 20, auto-loads older pages near the top, caps visible in-memory history at 80 by trimming the newest tail during history browsing, buffers realtime inserts while browsing history, and makes the floating button reset back to the newest window instead of only scrolling.
  - Added tests for helper logic, repository cache trimming, and widget-level chat-room behavior covering initial latest-slice load, auto older pagination, realtime buffering in history mode, and reset-to-latest.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Telegram-Style Incoming Message Avatars)
- [x] Extract the chat message envelope into a shared widget with Telegram-style received-avatar slot support.
- [x] Wire the active chat route to pass avatar data and Telegram grouping visibility rules for received messages.
- [x] Add widget coverage for received/sent alignment and reaction-bar positioning, then update memory-bank notes.
- [x] Run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Telegram-Style Incoming Message Avatars)
- [x] Implemented and verified.
- Root change:
  - Extracted the chat row wrapper into `lib/features/chat/widgets/chat_message_envelope.dart`, which now owns the shared sent/received layout, the fixed left avatar slot for received messages, and the reaction-bar attachment point.
  - `ChatRoomViewV2` now feeds that wrapper the existing profile avatar/nickname cache data and applies Telegram grouping behavior so only the last bubble in a consecutive received-message run shows the circular avatar while earlier bubbles keep the same left slot width.
  - Added widget coverage for received-avatar visibility, spacer alignment, sent-message right alignment, and reaction-bar positioning in `test/features/chat/chat_message_envelope_test.dart`.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Crashlytics Skill Workflow Update)
- [x] Update the repo-local Crashlytics triage skill so its final report explicitly states whether action is needed in detail.
- [x] Require the skill to end by asking whether the user wants the recommended action executed.
- [x] Run `flutter analyze` and `flutter test` after the skill update.

# Review (2026-03-17 Crashlytics Skill Workflow Update)
- [x] Implemented and verified.
- Root change:
  - Updated `.codex/skills/firebase-crashlytics-triage/SKILL.md` so the required output now includes a dedicated action section that explicitly answers whether action is needed right now, explains that decision in detail, and summarizes concrete next steps when action is recommended.
  - The skill now must end by asking the user whether they want the recommended action executed.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Crashlytics Triage)
- [x] Pull the current iOS Crashlytics fatal issues, affected versions, and sample events from Firebase MCP.
- [x] Map the top crash paths back to the current repo to determine whether each issue is still present, already fixed, or likely external/tooling noise.
- [x] Record the triage outcome and next actions in this file.

# Review (2026-03-17 Crashlytics Triage)
- [x] Investigated and summarized.
- Scope:
  - Firebase MCP target confirmed as `pet-app-702be`, using iOS app `1:69520994244:ios:d6fc14579fda1a1ca33e91`.
  - Current repo/app version is `1.0.5+1`, but the fatal Crashlytics events in the last 7 days are from `1.0.0 (15)`, `1.0.1 (3)`, and `1.0.2 (1)`. No sampled fatal event in this pull came from `1.0.5`.
- Findings:
  - `1d17d2cef8aaab07652ca69c9b7ef756` (`google_fonts` host lookup failure, 1 event / 1 user, `2026-03-10T11:44:08Z`):
    - Most likely still present in current code. `lib/shared/theme/app_theme.dart` still builds the global text theme from `GoogleFonts.poppinsTextTheme()` with no bundled-font fallback, so an offline DNS failure at bootstrap can still throw before the app settles.
    - This is not a native iOS crash; it is a runtime font fetch exception recorded as fatal by the global zone/error hooks in `lib/main.dart`.
  - `51d63e291417d0f7cfcb5c37d165c1f6` (legacy `chat_message_list.dart` null check, 3 events / 2 users across sampled history, `2026-03-08T00:50:50Z`, `2026-03-10T04:58:12Z`):
    - Already fixed in the repo. The blamed file no longer exists, and `git log --diff-filter=D` shows `lib/features/chat/chat_message_list.dart` was deleted in commit `89f61ce` on `2026-03-10`.
    - Current chat code uses `lib/features/chat/chat_room_view_v2.dart` plus `lib/features/chat/widgets/deterministic_chat_list.dart`, so this issue is old-build noise until users leave `1.0.0 (15)`.
  - `6cd7b77a79bd9f95739614da34231c2c` (Flutter Impeller `shadow_path_geometry.cc`, 1 event / 1 user, `2026-03-11T04:00:27Z`):
    - Evidence points to a Flutter engine / Impeller raster crash, not an app-owned Dart exception. The blamed frame is fully inside Flutter raster code with no Dart frames.
    - Context is thin: the breadcrumbs show room switching, camera open, feed send success, then another route push right before the crash. The event memory footprint was high (`~6.0 GB used, ~307 MB free`), so memory pressure may be a contributing factor, but the stack alone is not enough to identify a precise app-level root cause.
  - `faba429c9f9c47073b49d24eb91366af` (`AuthRetryableFetchException` refresh-token path, 1 event / 1 user, `2026-03-12T15:31:35Z`):
    - Most likely a reporting-classification problem, not a true crash. The thrown exception is a retryable auth/network error, but `lib/main.dart` reports all uncaught zoned errors as `fatal: true`.
    - The related high-volume non-fatal issue (`5f2e809db34b69a598977233280e18a1`) shows the same Supabase/app-config network family during `force_update_check`, which supports the conclusion that transient network/auth failures are being over-promoted into crash signals.
- Recommended next actions:
  - Fix first: stop treating transient `google_fonts` network fetch failures as fatal by bundling the font locally or replacing the runtime-fetched theme path.
  - Fix second: narrow fatal reporting in `lib/main.dart` so known retryable network/auth exceptions are recorded non-fatally instead of tripping the crash screen and polluting fatal issue counts.
  - Monitor separately: the Impeller crash needs more samples or a Flutter-engine upgrade correlation before making an app-level code change.

# Plan (2026-03-17 Crashlytics Cleanup)
- [x] Inspect the current Google Fonts loading path and global crash-reporting hooks to choose the minimal safe fixes.
- [x] Patch the app to avoid runtime font fetch crashes and downgrade retryable network/auth exceptions from fatal.
- [x] Update task tracking and memory-bank notes for the new behavior.
- [x] Run `flutter analyze` and `flutter test` to verify the changes.

# Review (2026-03-17 Crashlytics Cleanup)
- [x] Implemented and verified.
- Root change:
  - Replaced the global light-theme dependency on `GoogleFonts.poppinsTextTheme()` with a local Material typography base, so app startup no longer relies on a runtime fetch to `fonts.gstatic.com`.
  - Added fatality classification inside `CrashReportingService.reportError`, so requested-fatal reports are downgraded to non-fatal for retryable network/auth transport failures such as `AuthRetryableFetchException`, DNS/socket failures, and timeouts.
  - Added unit coverage for the new crash fatality classifier in `test/services/crash/crash_reporting_service_test.dart`.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Chat Memory Diagnostics)
- [x] Add a shared memory diagnostics service that snapshots image-cache, realtime-channel, and chat-message counts.
- [x] Wire diagnostics capture into Home room switching, chat-room lifecycle checkpoints, and fullscreen viewer open events.
- [x] Expose diagnostics through the existing debug drawer and add lightweight release breadcrumbs.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Chat Memory Diagnostics)
- [x] Implemented and verified.
- Root change:
  - Added `MemoryDiagnosticsService` to capture normalized image-cache, message-count, optimistic-message, and active-channel snapshots, with rolling in-memory history plus Crashlytics breadcrumb/custom-key emission.
  - Hooked snapshot capture into Home room switching, chat route enter/exit/load checkpoints, and fullscreen viewer open events so multi-room repros now produce comparable traces without changing runtime image policy yet.
  - Added a debug-admin diagnostics flow in the Home drawer: manual snapshot capture, image-cache clear plus snapshot, and a bottom sheet that shows recent snapshot summaries.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Chat Bright Status Bar)
- [x] Inspect the chat route and compare bright/dark status-bar handling with other screens.
- [x] Apply the minimal fix so bright chat backgrounds use dark iPhone status-bar content while dark themes keep light content.
- [x] Update memory-bank notes if behavior changed, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Chat Bright Status Bar)
- [x] Implemented and verified.
- Root change:
  - Kept the existing bright/dark room-background decision path in `ChatRoomViewV2`, but now pass the same resolved `overlayStyle` directly into the chat `AppBar`.
  - This keeps iPhone status-bar content aligned with the active chat theme: bright chat backgrounds use dark time/battery text, while dark chat themes still use light content.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without the required Supabase env vars, as expected.

# Plan (2026-03-17 Global AppBar Status Bar)
- [x] Audit all AppBar/status-bar handling and identify the correct shared default.
- [x] Enforce dark status-bar content for non-Home/non-Chat AppBars while preserving explicit dark-theme overrides.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Global AppBar Status Bar)
- [x] Implemented and verified.
- Root change:
  - Added `AppStatusBarStyles.light` to the shared `AppBarTheme` inside `AppTheme.lightTheme`, so every standard light-surface `AppBar` now defaults to dark iPhone status-bar content.
  - Home and chat keep their explicit route-level overlay handling, so they remain the only places where dark-theme status-bar content can appear.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without the required Supabase env vars, as expected.

# Plan (2026-03-23 Store Pro Banner UI Polish)
- [x] Update the featured Pro banner title so long localized text scales down to fit the available width instead of truncating with ellipsis.
- [x] Remove the inner scrolling dependency from the banner body so the Pro description stays readable within the card on English and other locales.
- [x] Tighten the English Pro description copy if the current sentence is still too long for the available mobile space.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-23 Store Pro Banner UI Polish)
- [x] Implemented and verified.
- Root change:
  - Added `_StoreAdaptiveStrokeTitle` so the Pro banner's premium label and localized product name now scale down to fit the available width instead of truncating with ellipsis.
  - Reworked the banner body to use a height-aware compact mode rather than an inner `SingleChildScrollView`, which keeps the description/status/renewal copy visible within the fixed banner card even when the subscribed-state status line is present.
  - Shortened the English Pro description to `Unlimited rooms and no ads for a smoother pet home.` so the compact mobile layout reads cleanly without relying on overflow-prone wrapping.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test test/features/store/store_featured_banner_test.dart`
  - `flutter test`

# Plan (2026-03-23 Store Grid Card Adaptive Titles)
- [x] Reuse the adaptive stroke-title treatment for store grid card titles so long localized item names scale down instead of clipping visually.
- [x] Update memory-bank notes for the broader store title-fitting behavior.
- [x] Run `flutter analyze` and `flutter test`.

# Review (2026-03-23 Store Grid Card Adaptive Titles)
- [x] Implemented and verified.
- Root change:
  - Reused `_StoreAdaptiveStrokeTitle` for the store grid card title row, so localized item names now scale down inside the card header instead of relying on fixed-size stroke text.
  - Kept the card-specific title treatment visually tighter by using the existing smaller stroke width with a shorter 24px title slot, so the card layout stays compact while still fitting longer names.
- Verification:
  - `flutter analyze`
  - `flutter test`

# Plan (2026-03-23 Room Selection Adaptive Title)
- [x] Replace the fixed `ellipsis` header title in Room Selection with an adaptive scale-down title that preserves the current visual style.
- [x] Update memory-bank notes for the expanded adaptive-title usage.
- [x] Run `flutter analyze` and `flutter test`.

# Review (2026-03-23 Room Selection Adaptive Title)
- [x] Implemented and verified.
- Root change:
  - Added a small `_AdaptiveHeaderTitle` wrapper in `room_selection_view.dart` so the Home `Room Selection` header now uses `FittedBox(BoxFit.scaleDown)` inside the existing `Expanded` slot instead of a one-line `ellipsis` text.
  - Kept the current visual hierarchy intact by preserving the same responsive `titleLarge` / `headlineSmall` styling, only changing how the title fits within the available width.
- Verification:
  - `flutter analyze`
  - `flutter test`
