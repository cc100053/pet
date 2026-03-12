# TODO

## Plan (2026-03-12 Pet Home Gallery 10 Photos + Feed Ordering Fix)
- [x] Introduce a shared Pet Home gallery photo-limit utility, update Home feed/gallery state paths from 3 to 10, and keep compact summary surfaces capped at 3.
- [x] Rework optimistic self-feed reconciliation so local-path optimistic entries are replaced by canonical remote feed records without transient duplicates or wrong ordering.
- [x] Add widget/unit regression coverage for the 10-photo gallery behavior, minimum placeholder floor, own-feed jump-to-latest behavior, and optimistic reconciliation/truncation rules.
- [x] Update `memory-bank/architecture.md`, `memory-bank/progress.md`, and this file with the shipped behavior, then run `flutter analyze` and `flutter test`.

## Review (2026-03-12 Pet Home Gallery 10 Photos + Feed Ordering Fix)
- [x] Implemented and verified.
- Root change:
  - Added `lib/features/home/home_gallery_feed_utils.dart` as the shared source of truth for Pet Home gallery limits, snapshot hydration, optimistic pending-feed matching, canonical image replacement, and compact 3-photo summary previews.
  - Updated Pet Home gallery fetch/hydration paths in `HomeView` controllers to keep up to 10 recent feed photos in active-room state and room snapshots, while leaving compact summary cards capped at 3 via `compactSummaryPhotoUrls(...)`.
  - `PetPhotoGallery` now accepts a `jumpToLatestEventId`, keeps the 3-slot minimum placeholder floor, and auto-scrolls back to page 0 only after the current user successfully completes a feed upload.
  - Realtime image-feed inserts now reconcile against pending optimistic self-feeds by room/sender/caption/client-created-at/message-id, so the uploaded remote photo replaces the optimistic local-path card instead of briefly appearing as a second item.
- Tests:
  - Added `test/features/home/home_gallery_feed_utils_test.dart` for 10-item truncation, optimistic reconciliation, room-snapshot retention, and compact 3-photo summary behavior.
  - Added `test/features/home/widgets/pet_photo_gallery_test.dart` for the 10-slot gallery cap, 3-slot minimum floor, and jump-to-latest trigger.
- Verification:
  - `flutter test test/features/home/home_gallery_feed_utils_test.dart test/features/home/widgets/pet_photo_gallery_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Targeted new tests passed.
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

## Plan (2026-03-11 Global Keyboard Collapse Rollout)
- [x] Audit every in-repo keyboard input surface and map which ones already have chat-style dismiss behavior versus missing tap/drag collapse.
- [x] Add a shared keyboard-dismiss helper so non-chat input fields can consistently collapse on outside taps, and wire drag-to-dismiss into scrollable input screens.
- [x] Verify the audited input surfaces after the rollout, update `memory-bank/progress.md` and `memory-bank/architecture.md`, and record the review here.
- [x] Run required verification (`flutter analyze`, `flutter test`) and document the results.

## Review (2026-03-11 Global Keyboard Collapse Rollout)
- [x] Implemented and verified.
- Audited input surfaces:
  - Existing chat collapse behavior already lived in `ChatRoomViewV2` composer; the repo had 7 other non-chat `TextField` sites missing a consistent collapse affordance.
  - All 8 current `TextField` usages are now covered: chat composer/report dialog, feed caption, profile nickname dialog, pet selection name field, onboarding profile nickname, pet rename dialog, and room join-code dialog.
- Root change:
  - Added `lib/shared/ui/keyboard_dismiss_utils.dart` with a shared `dismissKeyboardOnTapOutside` callback plus `formScrollKeyboardDismissBehavior`.
  - Wired `onTapOutside` into every audited `TextField` so tapping blank space or other non-input UI collapses the keyboard consistently.
  - Enabled drag-to-dismiss on the three scrollable input surfaces: `FeedCaptureView`, `PetSelectionPage`, and the onboarding profile setup overlay in `HomeView`.
  - Added `test/shared/ui/keyboard_dismiss_utils_test.dart` to lock the shared tap-outside and drag-dismiss behavior.
- Verification so far:
  - `dart format lib/shared/ui/keyboard_dismiss_utils.dart lib/features/feed/feed_capture_view.dart lib/features/pet/pet_selection_page.dart lib/features/home/home_view.dart lib/features/home/flows/home_onboarding_flow.dart lib/features/home/controllers/home_room_manager.dart lib/features/profile/profile_view.dart lib/features/chat/chat_room_view_v2.dart test/shared/ui/keyboard_dismiss_utils_test.dart`
  - `flutter test test/shared/ui/keyboard_dismiss_utils_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Targeted keyboard-dismiss test passed.
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

## Plan (2026-03-11 Chat Crash Vulnerability Review)
- [x] Inspect the active chat stack for crash-prone lifecycle, scrolling, gesture, async, and null-safety patterns.
- [x] Record concrete findings with file/line references and decide whether any issue warrants an immediate fix.
- [x] If a clear bug is found, implement the smallest safe fix, run required verification (`flutter analyze`, `flutter test`), and document the result.

## Review (2026-03-11 Chat Crash Vulnerability Review)
- [x] Implemented and verified.
- Findings:
  - `lib/features/chat/chat_room_view_v2.dart` had several async chat-load/send paths that awaited network work and then continued mutating `_chatController` / `_messages` even if the route had already been popped and disposed. That made the active chat stack vulnerable to disposed-controller exceptions during fast leave/send/realtime races.
  - `lib/features/feed/feed_capture_view.dart` passes the original picked file path into the optimistic chat message, and `lib/features/chat/chat_room_view_v2.dart` rendered that path with a raw `Image.file(...)` in the feed card. On large camera photos this can decode far more pixels than the card actually needs, which is a realistic iOS memory-pressure / app-termination risk while using chat.
- Fixes:
  - Added mounted guards before post-await chat-controller mutations in the active chat load/refresh/send paths, and skipped optimistic-message cleanup work when feed callbacks arrive after the chat route is gone.
  - Downsampled local optimistic feed images in the chat card with `cacheWidth` / `cacheHeight` sized to the rendered card, plus a safe broken-image fallback.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped without required env vars, as expected.

## Plan (2026-03-11 Update Reminder Investigation)
- [x] Trace the existing update reminder flow and confirm why publishing a new App Store version does not trigger a prompt.
- [x] Make the iOS update check resilient by falling back to live App Store version lookup when Supabase config is missing or stale.
- [x] Add regression coverage, run required verification (`flutter analyze`, `flutter test`), and document the confirmed behavior/fix.

## Review (2026-03-11 Update Reminder Investigation)
- [x] Implemented and verified.
- Root cause:
  - `ForceUpdateGate` only compared the installed app version against Supabase `app_config` values fetched by `AppConfigService`; it did not inspect the live App Store version at all.
  - If `app_config` was missing, stale, or the `app_config` table was unavailable, `fetchForceUpdateConfig()` returned `null` and the app skipped the update reminder entirely.
- Fixes:
  - Added `lib/services/app_config/app_store_lookup_service.dart` plus conditional HTTP client helpers so iOS can query Apple’s lookup API for the current App Store version and store URL.
  - Updated `lib/services/app_config/app_config_service.dart` to safely treat Supabase config reads as best-effort, merge App Store version data with configured versions, and fall back to a soft-update-only minimum (`0.0.0`) when only App Store latest-version data is available.
  - Added regression coverage in `test/services/app_config/app_config_service_test.dart` and `test/services/app_config/app_store_lookup_service_test.dart` to lock the fallback and merge behavior.
- Verification:
  - `flutter test test/services/app_config/app_config_service_test.dart test/services/app_config/app_store_lookup_service_test.dart test/shared/force_update/update_policy_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped without required env vars, as expected.

## Plan (2026-03-11 Tighten Chat Reaction Attachment)
- [x] Inspect the active V2 reaction-row layout and identify why the emoji chips feel detached from their message.
- [x] Tighten the message/reaction spacing and alignment so reaction chips read as part of the same message surface.
- [x] Update project notes and run required verification (`flutter analyze`, `flutter test`).

## Plan (2026-03-10 Remove Chat Camera Button Shadow)
- [x] Inspect the active V2 composer styling and confirm where the camera button's dark background/shadow is coming from.
- [x] Remove the camera button's black shadow/background artifact with the smallest possible UI change.
- [x] Update project notes and run required verification (`flutter analyze`, `flutter test`).

## Plan (2026-03-10 Simplify Reply Swipe Gesture)
- [x] Inspect the active V2 reply-swipe implementation and confirm why the current gesture feels too strict.
- [x] Simplify the swipe trigger so any non-system message, including self-sent messages, can left-swipe into reply more easily.
- [x] Add regression coverage for the new swipe rule/threshold and update project notes.
- [x] Run required verification (`flutter analyze`, `flutter test`) and record the results.

## Plan (2026-03-10 Remove Legacy Chat Room Code)
- [x] Confirm the active chat entry points and isolate files/components that are only used by the legacy `ChatRoomView` path.
- [x] Remove the legacy chat-room route switch from `HomeView` so the app always opens `ChatRoomViewV2`.
- [x] Delete legacy-only chat files/tests, then update `memory-bank/progress.md`, `memory-bank/architecture.md`, and this file with the cleanup summary.
- [x] Run required verification (`flutter analyze`, `flutter test`) and record the results.

## Review (2026-03-10 Remove Legacy Chat Room Code)
- [x] Implemented and verified.
- Root change:
  - `lib/features/home/home_view.dart` now always opens `ChatRoomViewV2`; the old V1/V2 prototype switch, legacy imports, and unused chat-list key were removed.
  - Deleted the legacy-only chat stack: `lib/features/chat/chat_room_view.dart`, `lib/features/chat/chat_message_list.dart`, `lib/features/chat/widgets/chat_message_tile.dart`, plus the matching widget tests `test/chat_message_tile_reply_test.dart` and `test/chat_message_tile_system_message_test.dart`.
  - Removed dead `_chatListKey` refresh/optimistic-message hooks from `lib/features/home/controllers/home_feed_orchestrator.dart` and `lib/features/home/controllers/home_unread_manager.dart`; those callbacks were leftovers from the deleted legacy list and were not attached to the active V2 route.
- Verification:
  - `dart format lib/features/home/home_view.dart lib/features/home/controllers/home_feed_orchestrator.dart lib/features/home/controllers/home_unread_manager.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped as expected because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` were not set.

## Review (2026-03-10 Simplify Reply Swipe Gesture)
- [x] Implemented and verified.
- Root change:
  - `lib/features/chat/chat_room_view_v2.dart` now treats every non-system message as reply-swipable, so self-sent messages can also trigger the swipe-to-reply action.
  - The reply swipe wrapper now uses a lower left-swipe threshold and fires as soon as the drag crosses that threshold, instead of waiting for drag-end.
  - Added `test/features/chat/chat_reply_swipe_test.dart` to cover both the new eligibility rule and the immediate left-swipe trigger.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart test/features/chat/chat_reply_swipe_test.dart`
  - `flutter test test/features/chat/chat_reply_swipe_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped as expected because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` were not set.

## Review (2026-03-10 Remove Chat Camera Button Shadow)
- [x] Implemented and verified.
- Root change:
  - `lib/features/chat/chat_room_view_v2.dart` no longer applies the dark-mode black box shadow behind the composer camera action button, so the button keeps its circular fill/border without the extra black backdrop artifact.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped as expected because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` were not set.

## Review (2026-03-11 Tighten Chat Reaction Attachment)
- [x] Implemented and verified.
- Root change:
  - `lib/features/chat/chat_room_view_v2.dart` now brings the reaction row closer to the message bubble/card, trims the extra bottom gap under message envelopes, and horizontally insets the reactions so they align more clearly under the same message surface.
  - `lib/features/chat/widgets/chat_reaction_bar.dart` now uses slightly tighter chip spacing/padding so the reaction group reads more like a compact extension of the message instead of a separate row.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart lib/features/chat/widgets/chat_reaction_bar.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` passed; `test/feed_flow_integration_test.dart` remained skipped as expected because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` were not set.

## Plan (2026-03-10 Chat Latest Button + Long-Press Regression)
- [x] Trace the active V2 chat path to confirm why the jump-to-latest affordance disappeared and why long-press actions no longer open.
- [x] Restore the missing latest-message button and reattach long-press handling at the deterministic list layer used by `ChatRoomViewV2`.
- [x] Add targeted regression coverage, run required verification (`dart format`, `flutter analyze`, `flutter test`), and update task/memory notes with the confirmed root cause.

## Review (2026-03-10 Chat Latest Button + Long-Press Regression)
- [x] Implemented and verified.
- Root cause:
  - `ChatRoomViewV2` replaced the package-managed animated list with a custom deterministic scroll view to own reply-jump behavior, but that custom list only rendered message widgets.
  - The migration did not recreate the package-level list affordances that used to sit around each rendered item, so the chat lost both the long-press action entry point and the built-in jump-to-latest button.
- Fixes:
  - `lib/features/chat/widgets/deterministic_chat_list.dart` now owns the deterministic list implementation, forwards per-message long-press events, and exposes a shared helper for deciding when the jump-to-latest affordance should appear.
  - `lib/features/chat/chat_room_view_v2.dart` now routes long-presses from the deterministic list back into the existing reaction/action sheet flow and restores a floating jump-to-latest button above the composer whenever the user scrolls far enough away from the newest message.
  - `test/features/chat/deterministic_chat_list_test.dart` locks the long-press forwarding and jump-button visibility threshold behavior.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart lib/features/chat/widgets/deterministic_chat_list.dart test/features/chat/deterministic_chat_list_test.dart`
  - `flutter analyze`
  - `flutter test test/features/chat/deterministic_chat_list_test.dart`
  - `flutter test`

## Plan (2026-03-10 Chat Long-Press + Integrated Reply + Dark Bubble + Half-Screen Back Swipe)
- [x] Add Supabase `message_reactions` schema via MCP-first migration, including RLS, indexes, updated_at trigger, and realtime publication; save matching repo migration file.
- [x] Extend chat message domain/cache/V2 state to load grouped reaction summaries, toggle per-user reactions, and subscribe to reaction realtime changes.
- [x] Upgrade V2 long-press actions to support all non-system messages with quick reactions and ownership-aware action rows.
- [x] Integrate reply previews into the existing composer/input surface and into text/feed message bubbles so reply UI no longer renders as separate cards.
- [x] Lighten dark-theme sent text/feed bubble surfaces and add a left-half back-swipe pop gesture that excludes the composer region.
- [x] Add widget coverage for action-sheet variants, reaction chips/toggles, integrated reply layouts, and half-screen back swipe behavior.
- [x] Run required verification (`flutter gen-l10n` if needed, `flutter analyze`, `flutter test`) and update `memory-bank/architecture.md`, `memory-bank/progress.md`, and this file with review notes.

## Review (2026-03-10 Chat Long-Press + Integrated Reply + Dark Bubble + Half-Screen Back Swipe)
- [x] Implemented and verified.
- Root change:
  - Added Supabase-backed `message_reactions` with room-member RLS, realtime publication, and a follow-up `user_id` FK index (`supabase/migrations/20260310113000_add_message_reactions.sql`, `supabase/migrations/20260310114500_add_message_reactions_user_id_idx.sql`).
  - `ChatMessage` cache/domain models now persist grouped reaction summaries, and `ChatRoomViewV2` loads reactions in a best-effort secondary query, applies optimistic one-reaction-per-user toggles, and refreshes reactions from `message_reactions` realtime events.
  - V2 long-press now works on all non-system messages and uses a type-aware bottom sheet with quick reactions plus ownership-aware `Reply` / `Copy` / `Report` / `Block`.
  - Reply UI is now integrated into the existing surfaces: the composer input pill expands upward for reply state, text bubbles render reply preview inside `SimpleTextMessage.topWidget`, and feed cards render the same embedded preview at the top of the card instead of a detached card above.
  - Dark-theme sent text/feed surfaces were lifted to a lighter muted teal, and a new left-half `ChatBackSwipePopLayer` now enables right-drag pop while excluding the composer region.
  - Added widget/unit coverage for action-sheet variants, reaction summary toggle rules, reaction chip taps, and half-screen back swipe behavior.
- Verification:
  - `dart format lib/features/chat/chat_message.dart lib/services/chat/chat_message_repository.dart lib/features/chat/chat_room_view_v2.dart lib/features/chat/chat_reaction_utils.dart lib/features/chat/widgets/chat_keyboard_dismiss_shell.dart lib/features/chat/widgets/chat_message_action_sheet.dart lib/features/chat/widgets/chat_reaction_bar.dart lib/features/chat/widgets/chat_reply_preview_panel.dart test/features/chat/chat_message_action_sheet_test.dart test/features/chat/chat_reaction_bar_test.dart test/features/chat/chat_reaction_utils_test.dart test/features/chat/chat_keyboard_dismiss_behavior_test.dart`
  - `flutter analyze`
  - `flutter test test/features/chat/chat_message_action_sheet_test.dart test/features/chat/chat_reaction_utils_test.dart test/features/chat/chat_reaction_bar_test.dart test/features/chat/chat_keyboard_dismiss_behavior_test.dart`
  - `flutter test`
  - `flutter analyze` passed.
  - Targeted chat tests passed.
  - Full `flutter test` passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).
  - Supabase advisors still report pre-existing project-level security/performance lints (for example `notification_delivery_logs` missing policies and older mutable-search-path / auth-initplan findings); the new `message_reactions.user_id` FK index was added immediately after the initial advisor run.

# Plan (2026-03-10 Game SFX Respect Silent Mode)
- [x] Read `memory-bank/*.md` and locate the shared gameplay SFX playback path for eating and coin/candy sounds.
- [x] Update the shared SFX service so gameplay sound effects respect the device silent-mode setting instead of always forcing playback.
- [x] Format touched files and update project task/memory notes without running `flutter analyze` or `flutter test` per user instruction.

# Review (2026-03-10 Game SFX Respect Silent Mode)
- [x] Implemented and locally checked without `flutter analyze` / `flutter test` per user instruction.
- Root change:
  - `lib/services/audio/app_sfx.dart` now plays all shared gameplay SFX with an `AudioContextConfig(respectSilence: true)`, so eating and coin/candy gain sounds follow the phone's silent-mode setting instead of bypassing it.
  - Because both Home eating SFX and the HUD coin/candy reward SFX already route through `AppSfx`, no caller-specific changes were needed.
- Verification:
  - `dart format lib/services/audio/app_sfx.dart`
  - `git diff -- lib/services/audio/app_sfx.dart memory-bank/progress.md memory-bank/architecture.md tasks/todo.md`
  - Did not run `flutter analyze` or `flutter test` because the user explicitly said this change does not need them.

## Plan (2026-03-10 Notification Tap Room Routing)
- [x] Add a unified notification intent model/parser in `FCMService`, including `message_kind` normalization, target resolution, and dedupe.
- [x] Wire notification tap sources into that intent pipeline: `onMessageOpenedApp`, `getInitialMessage`, foreground local-notification taps, and Android launch-intent / `onNewIntent` bridge.
- [x] Update `HomeView` to consume pending notification intents after bootstrap/room readiness, switch to the target room, and open chat only for text notifications.
- [x] Add regression coverage for notification intent parsing and Home routing fallbacks.
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `memory-bank/architecture.md`, and this file with the shipped behavior + verification results.

## Review (2026-03-10 Notification Tap Room Routing)
- [x] Implemented and verified.
- Root change:
  - `lib/services/fcm_service.dart` now exposes a typed `AppNotificationIntent` pipeline with `message_kind` / legacy `message_type` normalization, target resolution (`chat` vs `petHome`), dedupe, pending-intent buffering, and tap ingestion from `FirebaseMessaging.onMessageOpenedApp`, `FirebaseMessaging.getInitialMessage()`, iOS foreground local-notification responses, and the Android `pet/notification_taps` method channel.
  - `android/app/src/main/kotlin/com/example/pet/MainActivity.kt` now captures cold-start notification extras and forwards resumed-app notification taps through `onNewIntent`, while `PetTomoFirebaseMessagingService` now includes `message_kind` in launch extras for Flutter-side routing.
  - `lib/features/home/home_view.dart` and `lib/features/home/controllers/home_room_manager.dart` now queue notification intents until bootstrap/room entry is ready, pop back to Home before applying notification-driven navigation, switch into the requested room, open chat only for `text`, and keep `image_feed` / `hunger_alert_*` / other non-text intents on Pet home. Missing/stale rooms fall back safely to Room Selection.
  - `test/fcm_service_notification_intent_test.dart` locks parser, dedupe, and room-routing decision behavior.
- Verification:
  - `dart format lib/services/fcm_service.dart lib/features/home/home_view.dart lib/features/home/controllers/home_room_manager.dart test/fcm_service_notification_intent_test.dart`
  - `flutter analyze`
  - `flutter test test/fcm_service_notification_intent_test.dart`
  - `flutter test`
  - `flutter analyze` passed.
  - Targeted notification intent test passed.
  - Full `flutter test` passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Chat Keyboard Dismiss UX)
- [x] Replace chat timeline `keyboardDismissBehavior` with a shared manual setting so dragging the message list no longer collapses the composer.
- [x] Add a composer-aware downward-dismiss helper and wire it into both `ChatRoomViewV2` and the legacy `ChatRoomView` without touching reply/scroll anchoring logic.
- [x] Extend the dismiss interaction so a downward swipe that starts in the message list and sweeps into the composer also collapses the keyboard.
- [x] Add widget regression coverage for list-drag retention, tap-outside dismiss, composer-edge downward dismiss, list-to-composer sweep dismiss, and the shared manual dismiss behavior constant.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `memory-bank/architecture.md`, and this file with the shipped behavior + verification results.

## Review (2026-03-10 Chat Keyboard Dismiss UX)
- [x] Implemented and verified.
- Root change:
  - Chat timelines now use a shared manual keyboard-dismiss setting, so dragging either the active V2 timeline or the legacy fallback timeline keeps the keyboard/composer open.
  - Chat routes now add a pointer-tracking dismiss layer keyed to the composer bounds, so a downward drag can start in the message list and continue into the composer area without immediately dismissing on first contact.
  - Once the drag enters the composer zone, the route now treats that entry point as the start of a second threshold: users must drag farther down into the composer before dismissal happens, and dragging back up before crossing that threshold cancels the dismiss.
  - The composer still keeps its narrow top-edge drag affordance, so direct composer-origin swipes continue to dismiss too.
  - Active chat bottom spacing now clamps keyboard inset against the safe-area inset during keyboard collapse, removing the previous “drops downward, then snaps back up” motion at the end of the dismiss animation.
  - Active V2 composer height measurement no longer re-runs on every build during keyboard animation; it now only remeasures when composer content actually changes, removing the remaining top-edge / reply-bar jitter during collapse.
- Files:
  - `lib/features/chat/widgets/chat_keyboard_dismiss_shell.dart`: added the shared manual timeline constant, composer shell helper, and route-level sweep-dismiss listener keyed to the composer / protected input region.
  - `lib/features/chat/chat_room_view_v2.dart`: wrapped the active chat route in the shared sweep-dismiss layer, keyed the composer/input regions, kept the deterministic scroll view on manual keyboard dismissal, unified list/composer bottom inset math around a safe-area-clamped keyboard inset, and changed composer height measurement to a content-change-driven schedule instead of per-build post-frame remeasurement.
  - `lib/features/chat/chat_room_view.dart` / `lib/features/chat/chat_message_list.dart`: applied the same sweep-dismiss helper and manual timeline behavior to the legacy route and all legacy list empty/loading/main states; the legacy route now reuses the shared safe-area keyboard inset helper too.
  - `test/features/chat/chat_keyboard_dismiss_behavior_test.dart`: added regression tests for list drag retention, tap-outside dismiss, composer-edge drag dismiss, list-to-composer sweep dismiss, partial-entry cancellation, and the shared manual dismiss constant.
- Verification:
  - `dart format lib/features/chat/widgets/chat_keyboard_dismiss_shell.dart lib/features/chat/chat_room_view_v2.dart lib/features/chat/chat_room_view.dart lib/features/chat/chat_message_list.dart test/features/chat/chat_keyboard_dismiss_behavior_test.dart`
  - `flutter test test/features/chat/chat_keyboard_dismiss_behavior_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - The new targeted chat keyboard regression test passed.
  - Full `flutter test` passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Reply Jump Deterministic Centering)
- [x] Replace the current reply-jump centering flow with a deterministic viewport-offset calculation instead of relying on approximate package alignment / repeated `ensureVisible` corrections.
- [x] Wire an explicit chat `ScrollController` into `ChatAnimatedList` so reply jumps can animate to a precise center offset once the target surface is rendered.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the final deterministic-centering fix summary and verification results.

## Review (2026-03-10 Reply Jump Deterministic Centering)
- [x] Implemented and verified.
- Root cause:
  - The last two fixes still depended on `flutter_chat_ui` / `scrollview_observer` alignment behavior to materialize off-screen reply targets and then used `ensureVisible` as a follow-up correction.
  - In the reversed lazy chat list, that combination still produced visible two-stage motion, so targets could first land too high or too low before settling.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: removed package-managed `ChatAnimatedList` ownership for the active timeline and replaced it with `_DeterministicChatList`, which eagerly renders all loaded messages inside a single `SingleChildScrollView + Column`.
  - `lib/features/chat/chat_room_view_v2.dart`: reply jumps now load older pages first, wait for the actual target widget to exist, then run one deterministic `ScrollController.animateTo(...)` using `RenderAbstractViewport.getOffsetToReveal(..., 0.5)`.
  - `lib/features/chat/chat_room_view_v2.dart`: composer height and prepend-pagination anchoring are now managed in `ChatRoomViewV2` itself, so the list/composer spacing and top-pagination position stay under one scroll owner.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test test/pet_chat_message_adapter_test.dart`
  - `flutter test test/chat_message_tile_reply_test.dart`
  - `flutter analyze` passed.
  - Both targeted chat-related test files passed.
  - I treated the two targeted chat-related test runs as the practical verification for this pass; full `flutter test` in this repo still has unrelated suite-level timeouts established earlier in the same session.

## Plan (2026-03-10 Reply Jump Centering Regression)
- [x] Confirm why reply targets fell back to bottom alignment again after the smooth-scroll refactor.
- [x] Restore a post-render centering correction for fallback reply jumps without reintroducing the old zero-duration overshoot behavior.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the regression-fix summary and verification results.

## Review (2026-03-10 Reply Jump Centering Regression)
- [x] Implemented and verified.
- Root cause:
  - The smooth-scroll refactor removed the fallback path’s post-render centering correction and relied on `_chatController.scrollToMessage(... alignment: 0.5)` alone when the target row was not yet rendered.
  - In this reversed `flutter_chat_ui` list, that package-level alignment remains approximate, so older reply targets reappeared near the bottom instead of landing in the viewport center.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: added `_centerReplyTargetIfRendered(...)` so reply jumps still try widget-anchor centering first.
  - `lib/features/chat/chat_room_view_v2.dart`: when the target is not yet rendered, the app now performs one smooth `_chatController.scrollToMessage(...)` pre-scroll and then a short post-render `Scrollable.ensureVisible(... alignment: 0.5)` correction to truly center the message.
  - The previous harsh `Duration.zero` pre-jump remains removed, so this restores centering without bringing back the strong overshoot/bounce behavior.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test test/pet_chat_message_adapter_test.dart`
  - `flutter test test/chat_message_tile_reply_test.dart`
  - `flutter analyze` passed.
  - Both targeted chat-related test files passed.
  - I did not rerun the full `flutter test` suite in this regression pass because the same session already established that the repo currently has multiple unrelated suite-level timeouts outside this chat change.

## Plan (2026-03-10 Reply Jump Smoothness + Local Highlight)
- [x] Trace the current reply-jump path in `ChatRoomViewV2` and remove the double-scroll behavior that causes the overshoot/bounce effect.
- [x] Move reply-target highlight styling from the outer message envelope into the actual text bubble / feed card so only the content frame is emphasized.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the final UX change summary and verification results.

## Review (2026-03-10 Reply Jump Smoothness + Local Highlight)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view_v2.dart` used a two-step reply jump: an immediate `scrollToMessage(... duration: Duration.zero)` followed by `Scrollable.ensureVisible(...)`.
  - That double movement made the list overshoot aggressively in the reversed chat, then visibly settle back onto the target message.
  - Highlight styling also lived on `_MessageEnvelope`, so the temporary emphasis wrapped the whole reply/message block instead of the actual content bubble/card.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: reply jumps now use a single path per case. If the target bubble/card is already rendered, the app uses one smooth `Scrollable.ensureVisible(...)` animation to center it. If it is not rendered yet, the app falls back to one animated `_chatController.scrollToMessage(...)` call without the previous zero-duration pre-jump.
  - `lib/features/chat/chat_room_view_v2.dart`: moved reply-target highlight treatment into the actual text bubble and feed-card surfaces via `_MessageHighlightFrame`, so only the message box/image card gets the temporary outline/glow.
  - `lib/features/chat/chat_room_view_v2.dart`: anchor keys now sit on the real text/feed surfaces rather than the outer message envelope, keeping the scroll target and highlight target aligned.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter test test/pet_chat_message_adapter_test.dart`
  - `flutter test test/chat_message_tile_reply_test.dart`
  - `flutter analyze` passed.
  - The two targeted chat-related test files passed.
  - `flutter test` did not complete cleanly because the repo currently has unrelated long-running test-loader timeouts (for example `test/store_legal_links_row_test.dart`, `test/admob_startup_service_test.dart`, `test/room_selection_unread_indicator_test.dart`, `test/store_item_test.dart`) plus `flutter_test_listener` temp-file cleanup errors after the suite aborts.

## Plan (2026-03-10 Reply Jump Root Cause Fix)
- [x] Verify why changing `scrollToMessage` alignment alone did not center reply targets in the reversed `flutter_chat_ui` list.
- [x] Replace the fragile alignment-only jump with a widget-anchor based centering path that uses the rendered message context.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the true root-cause fix and verification results.

## Review (2026-03-10 Reply Jump Root Cause Fix)
- [x] Implemented and verified.
- Root cause:
  - `flutter_chat_core` exposes `alignment` as if it were viewport-based, but the underlying `scrollview_observer` path used by `flutter_chat_ui` does not center reversed-list items the way that API comment implies.
  - As a result, changing `_chatController.scrollToMessage(... alignment: 0.5)` still left reply targets visually anchored too low.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: added stable per-message anchor keys in the custom message builder so reply jumps can reference the actual rendered widget.
  - `lib/features/chat/chat_room_view_v2.dart`: reply jumps now first bring the target into view with the chat controller, then call `Scrollable.ensureVisible(... alignment: 0.5)` on the real target widget context to center it in the viewport.
  - `lib/features/chat/chat_room_view_v2.dart`: pruned anchor keys when messages leave the in-memory list to avoid stale references.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Reply Jump Centering)
- [x] Trace why tapping a reply preview lands the source message near the bottom of the screen instead of centered.
- [x] Update `ChatRoomViewV2` reply jump scrolling so the source message is positioned around the middle of the viewport.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the jump-centering fix and verification results.

## Review (2026-03-10 Reply Jump Centering)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view_v2.dart` called `_chatController.scrollToMessage(... alignment: 0.25)` when jumping to a replied-to source.
  - In `flutter_chat_core`, `alignment` is viewport-based (`0 = top`, `0.5 = middle`, `1 = bottom`), so `0.25` kept the source message visibly too low instead of centered.
- Fix:
  - `lib/features/chat/chat_room_view_v2.dart`: changed reply jump alignment from `0.25` to `0.5` so the target message scrolls to the middle of the screen before highlight state is applied.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Feed Card Theme Alignment)
- [x] Trace why feed-card metadata rows ignore the active dark-background styling and confirm whether they still depend on `Theme.brightness` instead of chat-route background mode.
- [x] Align `ChatRoomViewV2` feed card colors with the text-bubble palette by driving sender/caption/time/card surfaces from `isDarkBackground`.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the theme-alignment fix and verification results.

## Review (2026-03-10 Feed Card Theme Alignment)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view_v2.dart` text bubbles already key off `isDarkBackground`, but `_FeedCard` metadata rows still used `Theme.brightness`.
  - In dark-background / bright-frame combinations, that mismatch left feed metadata on the wrong light surface.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: `_FeedCard` now accepts `isDarkBackground` from the chat route.
  - `lib/features/chat/chat_room_view_v2.dart`: card surface, caption text, inline time text, and no-caption overlay pill now all use the same dark/bright palette rules as text bubbles.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Feed Card Outside-Image Metadata)
- [x] Refine `ChatRoomViewV2` feed cards so the incoming sender label sits in its own row above the image, matching the text-bubble sender treatment.
- [x] Move caption into its own row below the image with text-bubble-style inline time handling, while preserving the bottom-right time pill only for no-caption feed cards.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the follow-up layout fix and verification results.

## Review (2026-03-10 Feed Card Outside-Image Metadata)
- [x] Implemented and verified.
- Follow-up changes:
  - `lib/features/chat/chat_room_view_v2.dart` now renders incoming feed sender names in a dedicated row above the image instead of inside the photo area.
  - `lib/features/chat/chat_room_view_v2.dart` now renders caption in its own row below the image, with the timestamp inline on the right using the same small text treatment as message bubbles.
  - When a feed image has no caption, the lower metadata row is omitted and the timestamp falls back to the bottom-right image overlay pill.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Feed Card Overlay Follow-up)
- [x] Refine the just-updated `ChatRoomViewV2` feed card so incoming sender names use the same plain text style as text bubbles instead of a pill.
- [x] Split feed caption/time overlays into two independent bottom components: optional caption pill on the left, time pill fixed on the right.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the follow-up style fix and verification results.

## Review (2026-03-10 Feed Card Overlay Follow-up)
- [x] Implemented and verified.
- Follow-up changes:
  - `lib/features/chat/chat_room_view_v2.dart` incoming feed sender names now use the same plain top-left text treatment as received text bubbles instead of a pill.
  - `lib/features/chat/chat_room_view_v2.dart` now renders caption and time as two separate bottom overlays: caption pill only when caption exists, plus a time pill fixed at the bottom-right.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Feed Card Overlay Restyle)
- [x] Inspect the active `ChatRoomViewV2` feed card hierarchy and identify the smallest layout change that moves sender info into the image overlay while collapsing caption/time into a floating pill.
- [x] Refactor the feed card so sender name sits at the top-left, while caption and time share a bottom floating pill instead of a dedicated lower text section.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the style-change summary and verification results.

## Review (2026-03-10 Feed Card Overlay Restyle)
- [x] Implemented and verified.
- Root change:
  - `lib/features/chat/chat_room_view_v2.dart` feed cards no longer reserve a separate lower text block below the image.
  - Sender name now renders as a top-left glass pill overlay, while caption and time render inside a bottom floating glass pill with tighter visual grouping.
- UI details:
  - Caption and time now share one overlay row; the time chip is bottom-aligned so it reads closer to the caption baseline instead of floating on a separate line.
  - Existing reward badge remains top-right, restyled to match the new glass-pill treatment for a more consistent overlay hierarchy.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Chat Latest Message Gap)
- [x] Trace why the newest chat message sits too high above the composer in `ChatRoomViewV2` and confirm whether list bottom spacing is double-counting composer area.
- [x] Fix the active chat route so the message list uses the real floating-composer inset instead of an oversized hardcoded bottom gap.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the fix summary and verification results.

## Review (2026-03-10 Chat Latest Message Gap)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view_v2.dart` passed `bottomPadding: 108` into `ChatAnimatedList`.
  - `flutter_chat_ui` already adds the measured composer height via `ComposerHeightNotifier`, so the extra `108` created an oversized blank gap between the latest message and the floating composer.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: replaced the hardcoded list bottom padding with the same bottom-inset formula used by the floating composer (`keyboardInset + 8` or `safeArea + 10`).
  - The list now reserves only the composer height plus its real distance from the screen bottom, so the newest message sits flush above the input bar again.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Chat Swipe Dispose Crash)
- [x] Trace the `Looking up a deactivated widget's ancestor is unsafe` exception in `ChatRoomViewV2` and confirm the exact lifecycle misuse around reply-swipe animation setup.
- [x] Fix the reply-swipe wrapper so ticker/animation resources are created and disposed only from safe widget lifecycle points, without changing swipe-to-reply behavior.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the fix summary and verification results.

## Review (2026-03-10 Chat Swipe Dispose Crash)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view_v2.dart` declared `_ReplySwipeWrapperState._controller` as a lazy `late final AnimationController`.
  - For message rows that were never swiped, the first `_controller` access happened inside `dispose()`, which tried to create a ticker after the widget had already been deactivated, triggering `Looking up a deactivated widget's ancestor is unsafe`.
- Fixes:
  - `lib/features/chat/chat_room_view_v2.dart`: moved `AnimationController` creation into `initState()` so ticker lookup always happens while the element tree is active.
  - `lib/features/chat/chat_room_view_v2.dart`: track the current reply-reset animation explicitly, remove its listener in `dispose()`, and stop the controller when a new drag update starts to avoid stale animation callbacks.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 flutter_chat_ui Migration Spike)
- [x] Write the approved `flutter_chat_ui` migration/spec into this file so the adapter/controller/custom-renderer boundaries are explicit before code moves.
- [x] Add `flutter_chat_ui` / `flutter_chat_core` dependencies and fetch packages.
- [x] Build a non-production `ChatRoomViewV2` spike that proves package-based rendering for text, package reply structure, custom feed card, system message builder, and package composer integration.
- [x] Keep Supabase/realtime/cache/moderation business logic outside the package by introducing an adapter/controller seam instead of rewriting domain data first.
- [x] Validate package extensibility for Telegram-style swipe reply and jump-to-source highlight before replacing the production route.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with spike findings, chosen boundaries, and verification results.

## Spec (2026-03-08 flutter_chat_ui Migration Spike)
- Package choice:
  - `flutter_chat_ui` owns list/bubble/composer/reply shell.
  - `flutter_chat_core` owns the message/user/theme/controller types required by the UI package.
- Product decisions already confirmed:
  - Use package reply structure.
  - Package composer replaces the current custom composer.
  - Feed messages stay custom via a package custom-message path.
  - System messages move to package system-message rendering.
  - Swipe reply should feel Telegram-like (distance threshold, not instant trigger).
  - Tapping a reply quote should jump back to the source message and briefly highlight it.
  - Feed card keeps the `+coins` badge.
- Adapter boundary:
  - Existing `ChatMessage` / Supabase rows remain the source of truth.
  - Add a `PetChatMessageAdapter` that maps `text` -> package text message, `system` -> package system message, and `image_feed` -> package custom message with feed metadata.
  - Reply linkage continues using `reply_to_message_id`; package reply payload is derived from already-fetched/best-effort-loaded source messages.
- Controller boundary:
  - Add a `PetChatSessionController` to own initial load, pagination, realtime insert, optimistic temp messages, blocked filtering, scroll-to-latest, and jump-to-source lookup.
  - Package widgets must not call Supabase directly.
- Renderer boundary:
  - Text/default reply visuals stay package-native.
  - Feed card becomes a package custom-message builder, redesigned closer to package spacing/typography while keeping image tap, optimistic local image, caption, sender, reply preview, and `+coins`.
  - System messages use a package system-message builder but keep the app’s existing localized parsing for hunger/rename/cleanup strings.
- Composer boundary:
  - Package composer is used end-to-end.
  - Camera/feed action is injected through package composer actions.
  - Send still routes into the current optimistic insert + Supabase insert + notification flow.
  - iOS Enter-key behavior remains required.
- Interaction boundary:
  - Long-press actions remain `Reply`, `Copy`, `Report`, `Block`.
  - Swipe reply is implemented as a thin wrapper around package message rows instead of forking package internals.
  - Jump-to-source highlight should work for both already-loaded and paged-in older messages.
- Spike success criteria:
  - No package fork required.
  - Package composer can host the camera/feed affordance without deep hacks.
  - Custom feed card and package system-message builder can coexist in one chat timeline.
  - Reply state can be driven from both long-press and Telegram-style swipe.
  - If any two of the above require deep internal overrides, fall back to a mixed approach before production replacement.

## Review (2026-03-08 flutter_chat_ui Migration Spike)
- [x] Implemented and verified.
- Result:
  - Added `flutter_chat_ui` / `flutter_chat_core` to `pubspec.yaml` and fetched packages.
  - Added `lib/features/chat/adapters/pet_chat_message_adapter.dart` to map existing `ChatMessage` domain rows into package `TextMessage` / `SystemMessage` / `CustomMessage`.
  - Added `lib/features/chat/chat_room_view_v2.dart` as the package-based spike route that keeps Supabase fetch/realtime/cache/moderation in app code while letting `flutter_chat_ui` handle list/composer shell.
  - Added a safe route toggle in `lib/features/home/home_view.dart`; after user confirmation, `_useChatRoomV2Prototype` is now `true`, so Home currently opens the V2 route.
  - Promoted the active V2 route beyond spike-level by restoring glass top-bar parity, room-members entry, blocked-users management entry, and keeping the package chat list padded correctly under the overlay header.
  - Added `test/pet_chat_message_adapter_test.dart` to lock the adapter mapping for text, feed, and localized system messages.
- Key findings:
  - `flutter_chat_core` exposes `replyToMessageId`, so package data structure fits the backend schema.
  - `flutter_chat_ui` 2.11.1 does not appear to ship built-in quoted-reply rendering in the UI layer, so the spike keeps package reply structure but uses a thin wrapper builder for reply preview, Telegram-style swipe trigger, and jump-to-source highlight.
  - Package composer is flexible enough for the camera action, Enter-key behavior, and a custom top reply bar without forking the package.
  - Feed cards fit cleanly through `customMessageBuilder`, so product-specific feed UI can stay isolated.
- Verification:
  - `flutter pub get`
  - `dart format lib/features/chat/adapters/pet_chat_message_adapter.dart lib/features/chat/chat_room_view_v2.dart lib/features/home/home_view.dart test/pet_chat_message_adapter_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 Chat Reply Fetch Regression)
- [x] Trace the chat load failure after reply rollout and confirm whether the new `messages` fetch path depends on a brittle self-referential PostgREST relation.
- [x] Remove the initial chat-load dependency on the `messages -> messages` join while keeping reply previews available through the existing follow-up lookup path.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `tasks/lessons.md`, and this file with the regression fix and verification results.

## Review (2026-03-08 Chat Reply Fetch Regression)
- [x] Implemented and verified.
- Root cause:
  - `lib/services/chat/chat_message_repository.dart` made the primary chat history query depend on a self-referential PostgREST join (`messages!messages_reply_to_message_id_fkey`) to hydrate reply previews inline.
  - In production, PostgREST schema cache did not expose that self-relationship yet, so the entire message load failed with `PGRST200` instead of just missing reply previews.
- Fix:
  - `lib/services/chat/chat_message_repository.dart`: removed the inline self-join from the main `messages` select and now fetches only direct message columns plus `reply_to_message_id`.
  - Reply preview hydration remains on the existing best-effort secondary lookup path in `ChatMessageList`, so quoted replies still resolve when available without blocking chatroom load.
- Verification:
  - `dart format lib/services/chat/chat_message_repository.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 Chat Reply Interaction)
- [x] Inspect current chat data flow, message actions, and composer layout to identify the smallest backward-compatible path for message replies.
- [x] Add reply data support for chat messages, including a nullable message self-reference and client model/cache/query updates.
- [x] Implement modern reply interactions in chat: long-press action sheet with `Reply`/`Copy`/existing moderation actions, left-swipe-to-reply on other users' messages, inline quoted preview in reply messages, and a composer reply preview with dismiss.
- [x] Add or update focused tests for the new reply UI behavior.
- [x] Run `flutter gen-l10n`.
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/*.md` and this file with the new behavior and verification results.

## Review (2026-03-08 Chat Reply Interaction)
- [x] Implemented and verified.
- Root cause / gap:
  - Chat messages had no reply reference in schema or client model, so the app could not persist or render quoted replies.
  - Existing message interactions only exposed `report` and `block` from long-press, with no reply gesture path or composer state for quoted context.
- Fixes:
  - Added migration `supabase/migrations/20260308110504_add_message_reply_support.sql` to introduce nullable `messages.reply_to_message_id` with self-reference + index.
  - `lib/features/chat/chat_message.dart` and `lib/services/chat/chat_message_repository.dart` now carry reply metadata through fetch/cache paths, including preview payload support for quoted messages.
  - `lib/features/chat/chat_message_list.dart` now supports reply requests from both long-press and left-swipe, includes `Copy` in the action sheet, resolves reply previews/sender names, and best-effort loads missing quoted targets.
  - `lib/features/chat/widgets/chat_message_tile.dart` now renders modern inline quoted previews inside text/feed bubbles and adds swipe-to-reply affordance for other users' messages.
  - `lib/features/chat/chat_room_view.dart` now keeps composer reply state, shows a dismissible reply preview bar above the input, and sends `reply_to_message_id` with outgoing text messages while preserving optimistic UI/failure recovery.
  - `lib/l10n/app_*.arb` gained reply/copy strings and generated localizations were refreshed with `flutter gen-l10n`.
  - Added `test/chat_message_tile_reply_test.dart` to cover quoted preview rendering and swipe-to-reply trigger behavior.
- Verification:
  - `flutter gen-l10n`
  - `dart format lib/features/chat/chat_message.dart lib/services/chat/chat_message_repository.dart lib/features/chat/chat_message_list.dart lib/features/chat/widgets/chat_message_tile.dart lib/features/chat/chat_room_view.dart lib/features/home/controllers/home_feed_orchestrator.dart test/chat_message_tile_system_message_test.dart test/chat_message_tile_reply_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 HomeView Localization Init Crash)
- [x] Trace the Crashlytics stack to confirm which onboarding initialization path reads `AppLocalizations.of(context)` before `initState()` finishes.
- [x] Move the onboarding initialization trigger onto a dependency-safe lifecycle point and keep it one-shot.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `tasks/lessons.md`, and this file with the fix summary and verification results.

## Review (2026-03-08 HomeView Localization Init Crash)
- [x] Implemented and verified.
- Root cause:
  - `HomeView.initState()` directly started `_loadBasicOnboardingState()`.
  - That flow called `_syncOnboardingProfileDraftFromCurrentData()`, which resolves `_defaultProfileNickname` via `AppLocalizations.of(context)`, so an inherited-widget lookup happened before `initState()` completed.
- Fixes:
  - `lib/features/home/home_view.dart`: deferred the one-shot onboarding-state bootstrap from `initState()` to `didChangeDependencies()`, where inherited widgets like localization are safe to read.
  - `lib/features/home/home_view.dart`: added `_basicOnboardingLoadStarted` so the onboarding bootstrap still runs only once.
- Verification:
  - `dart format lib/features/home/home_view.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 HomeView Ref Lifecycle Crash)
- [x] Trace the `HomeView` Crashlytics stack to locate the unsafe `ref.read(...)` call happening after widget deactivation.
- [x] Replace dispose-unsafe provider reads in `HomeView` async/lifecycle paths with cached service references created while the widget is still mounted.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `tasks/lessons.md`, and this file with the fix summary and verification results.

## Review (2026-03-08 HomeView Ref Lifecycle Crash)
- [x] Implemented and verified.
- Root cause:
  - `HomeView.initState()` scheduled a post-frame callback that later called `_initializeRewardedAds()`, and that method performed `ref.read(rewardedAdsServiceProvider)`.
  - If `HomeView` had already been deactivated before the callback ran, Riverpod rejected the `ref` access because `ConsumerState.ref` depends on a live `BuildContext`.
- Fixes:
  - `lib/features/home/home_view.dart`: cached `FCMService` and `RewardedAdsService` into `late final` fields during `initState()`, when `ref.read(...)` is still safe.
  - `lib/features/home/home_view.dart`: switched post-frame/lifecycle/debug-notification paths to use those cached fields instead of reading providers again later.
- Verification:
  - `dart format lib/features/home/home_view.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 Lightweight Profile Onboarding Step)
- [x] Trace current first-login onboarding state machine and existing profile editing/upload logic to identify the lowest-risk insertion point.
- [x] Add a lightweight profile onboarding step before create-pet onboarding, requiring nickname setup while keeping avatar upload optional.
- [x] Reuse existing profile persistence/upload rules so Home onboarding updates `profiles.nickname` / `profiles.avatar_url` and refreshes local UI state immediately.
- [x] Add or update localization keys for the new onboarding profile step.
- [x] Run `flutter gen-l10n`.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md`, `tasks/lessons.md`, and this file with the change summary and verification results.

## Review (2026-03-08 Lightweight Profile Onboarding Step)
- [x] Implemented and partially verified.
- Root cause / decision:
  - First-login onboarding previously jumped straight to room creation, so users had no lightweight moment to personalize their identity before chat/invite surfaces started using the default profile nickname.
  - The existing Profile page already supported nickname edits and avatar upload, but it was too heavy to force as a first-run screen.
- Fixes:
  - `lib/features/home/home_view.dart`: added a new onboarding state enum step (`profileSetup`) plus local draft state for nickname/avatar onboarding.
  - `lib/features/home/flows/home_onboarding_flow.dart`: fresh onboarding now starts with a centered profile setup modal on Room Selection; nickname must change from the default value before continuing, while avatar upload remains optional.
  - `lib/features/home/flows/home_onboarding_flow.dart`: added lightweight avatar upload handling in Home onboarding using the existing `avatar_upload` edge-function path and immediate local cache/UI refresh.
  - `lib/l10n/app_*.arb`: added dedicated onboarding profile-step copy across supported locales.
- Verification:
  - `flutter gen-l10n`
  - `dart format lib/features/home/home_view.dart lib/features/home/flows/home_onboarding_flow.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter analyze` passed.
  - `flutter test` now passes after the fullscreen photo viewer test coverage was stabilized around rendering assertions instead of brittle `InteractiveViewer` gesture simulation.

## Plan (2026-03-08 Photo Viewer Option 1 Fullscreen Redesign)
- [x] Confirm the target Option 1 interaction model for fullscreen photo viewing with persistent-but-non-blocking metadata.
- [x] Refactor `FullScreenPhotoViewer` from a boxed `Column + SizedBox` layout into a full-bleed image canvas with overlay chrome layered above it.
- [x] Separate image interaction state from overlay visibility so pinch/pan/double-tap behave like iPhone Photos while metadata remains available without constraining the image.
- [x] Redesign metadata presentation (`sender`, `sent time`, `caption`) as top/bottom overlays with tap-to-toggle chrome visibility and zoom-aware auto-hide behavior.
- [x] Preserve multi-photo paging, swipe-to-dismiss, download, and current-index return behavior across all viewer entry points (chat, home latest photo, gallery).
- [x] Add or update focused widget/logic tests for overlay visibility rules and gesture/state transitions where practical.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the redesign summary, key decisions, and verification results.

## Review (2026-03-08 Photo Viewer Option 1 Fullscreen Redesign)
- [x] Implemented and verified.
- Root cause:
  - The original boxed layout constrained zoom/pan to a metadata-sized image region.
  - The first custom fullscreen rewrite still depended on `InteractiveViewer`, which kept coupling centering, pan bounds, tap handling, and overlay composition in a brittle way. Repeated alignment issues were a sign that we were fighting the gesture/layout engine instead of reusing a purpose-built photo viewer core.
- Fixes:
  - `lib/shared/ui/full_screen_photo_viewer.dart`: replaced the custom `InteractiveViewer` core with `photo_view` / `PhotoViewGallery`, using per-page `PhotoViewController`s to track active zoom state and lock page swiping only while the current photo is zoomed.
  - `lib/shared/ui/full_screen_photo_viewer.dart`: kept the product-specific chrome on top of the new viewer core, including sender/time, caption, close, download, swipe-down dismiss, and current-index return behavior.
  - `lib/shared/ui/full_screen_photo_viewer.dart`: simplified bottom chrome from a full-width gradient slab into floating caption / indicator surfaces so overlay layout no longer distorts the perceived image center.
  - `pubspec.yaml`: added `photo_view`.
  - `test/full_screen_photo_viewer_test.dart`: added stable rendering coverage for fullscreen metadata/caption overlays and the empty-metadata case.
- Verification:
  - `flutter pub get`
  - `dart format lib/shared/ui/full_screen_photo_viewer.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 Room/Gallery Refresh Freshness)
- [x] Trace notification/open-room and room-selection refresh paths to confirm why the active room photo gallery and room cards can show stale cached photos.
- [x] Update the active-room latest-feed refresh flow so entering a room refreshes the gallery immediately and syncs fresh photo metadata back into the cached room snapshot.
- [x] Improve room-selection refresh responsiveness and add visible loading feedback while the refresh is running.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the root cause, fixes, and verification results.

## Review (2026-03-08 Room/Gallery Refresh Freshness)
- [x] Implemented and verified.
- Root cause:
  - Entering a room seeds the gallery from cached `_myRooms` snapshot first, then refreshes latest feed data asynchronously, so notification-driven entry could briefly stay on stale cached photos.
  - `_refreshLatestFeed(roomId)` updated the active gallery but did not sync the refreshed photo metadata back into the corresponding `_myRooms` entry, so Room Selection could keep showing old photos until the slower full refresh loop completed.
  - Room Selection refresh ticked each pet sequentially and had no visible loading feedback, so refreshes felt sluggish even when they were still in progress.
- Fixes:
  - `lib/features/home/controllers/home_feed_orchestrator.dart`: `_refreshLatestFeed(roomId)` now shows a lightweight in-gallery loading state for the active room, guards against cross-room async overwrite races, and writes fresh latest-photo metadata back into `_myRooms` plus bootstrap cache.
  - `lib/features/home/home_view.dart`: app resume now refreshes the active room gallery when the user is already inside a room, and Room Selection now exposes a refresh indicator state.
  - `lib/features/home/home_view.dart`: Room Selection refresh now runs per-room pet ticks concurrently instead of serially, then reloads the room list.
  - `lib/features/home/widgets/pet_photo_gallery.dart`: added a small spinner overlay while latest photos are refreshing so stale cached content is clearly transitioning.
  - `lib/features/home/room_selection_view.dart`: added a compact header loading pill while room cards are being refreshed.
- Verification:
  - `dart format lib/features/home/home_view.dart lib/features/home/controllers/home_feed_orchestrator.dart lib/features/home/room_selection_view.dart lib/features/home/widgets/pet_photo_gallery.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-08 Chat Keyboard Enter Key)
- [x] Inspect the chat composer input configuration and confirm why the iOS keyboard shows a send action in the bottom-right corner.
- [x] Change the composer input to use the standard multiline Enter key while keeping message send on the dedicated composer send button.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the behavior change and verification results.

## Review (2026-03-08 Chat Keyboard Enter Key)
- [x] Implemented and verified.
- Root cause:
  - `lib/features/chat/chat_room_view.dart` explicitly set the composer `TextField` to `TextInputAction.send` and handled `onSubmitted`, which tells iOS to replace the keyboard bottom-right Return key with a Send action.
- Fix:
  - `lib/features/chat/chat_room_view.dart`: changed the composer input to multiline keyboard behavior with `TextInputType.multiline` + `TextInputAction.newline`, and removed keyboard-submit sending so the iPhone keyboard shows the normal Enter/return key again.
  - The existing in-composer send button remains the message send trigger.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-07 Feed Double Reward Prompt Reliability)
- [x] Inspect the post-feed reward flow and locate the conditions that control showing the rewarded-ad prompt after a successful feed.
- [x] Implement the minimal fix so eligible feed completions trigger the double reward prompt again without regressing reward state handling.
- [x] Add or update focused tests if the affected flow is testable, then run formatting, `flutter analyze`, and `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the root cause, fix, and verification results.

## Review (2026-03-07 Feed Double Reward Prompt Reliability)
- [x] Implemented and verified.
- Root cause:
  - The feed double-reward affordance used a custom `OverlayEntry` pill, which is a fragile presentation path right after the camera route dismisses.
  - The eligibility fallback was also too narrow when the feed response omitted or normalized reward metadata differently than expected.
- Fixes:
  - `lib/features/home/controllers/home_feed_orchestrator.dart`: replaced the overlay pill prompt with a standard `showAppDialog` modal so successful feed rewards surface a reliable watch-ad choice.
  - `lib/features/home/controllers/home_feed_orchestrator.dart`: hardened `_shouldOfferFeedDoubleReward()` to trim/normalize `reward_status` and fall back to `!cooldownActive` when reward metadata is missing.
  - `lib/features/home/controllers/home_feed_orchestrator.dart`: added debug logging around prompt presentation failure instead of silently swallowing the path.
  - `lib/features/home/home_view.dart`: removed the now-unused custom `_FeedDoubleRewardPill` widget.
- Verification:
  - `dart format lib/features/home/controllers/home_feed_orchestrator.dart lib/features/home/home_view.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-07 Onboarding Explicit Skip Action)
- [x] Trace first-login onboarding interaction path and identify how incidental taps can affect the flow.
- [x] Tighten onboarding interaction so only explicit coach-card actions can advance or skip it.
- [x] Add a dedicated localized `Skip` button to the onboarding coach card and block background tap passthrough while onboarding is visible.
- [x] Run `flutter gen-l10n` if localization keys change.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with the onboarding interaction change.
- [x] Update this file with review outcomes.

## Review (2026-03-07 Onboarding Explicit Skip Action)
- [x] Implemented and verified.
- Root cause:
  - The onboarding spotlight overlay used `IgnorePointer`, so taps outside the coach card passed through to `RoomSelectionView`.
  - On first sign-in, iOS notification permission prompts can return control mid-tap, making incidental touches hit underlying onboarding targets and effectively skip the intended tutorial moment.
- Fixes:
  - `lib/features/home/flows/home_onboarding_flow.dart`: changed the coach card to add only a localized `Skip` button, matching the existing room-creation interaction instead of duplicating the primary CTA inside onboarding chrome.
  - `lib/features/home/flows/home_onboarding_flow.dart`: kept the spotlight overlay visual-only so users still tap the original highlighted `Create New Room` button in `RoomSelectionView`.
  - `lib/l10n/app_*.arb`: added `commonSkip` across shipped locales and regenerated localizations.
- Verification:
  - `flutter gen-l10n`
  - `dart format lib/features/home/flows/home_onboarding_flow.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).
- UI follow-up:
  - Refined the onboarding coach card into a more deliberate guidance surface with stronger spacing, a numbered badge, softer layered highlights, and a visual pointer toward the existing CTA while preserving the same interaction model.

## Plan (2026-03-07 Rewarded Ads Without ATT Requirement)
- [x] Trace current AdMob startup and rewarded-ad gating so ATT denial no longer blocks ad availability.
- [x] Update the ads startup/service flow to allow iOS rewarded ads without tracking authorization and adjust user-facing messaging accordingly.
- [x] Add focused regression tests for the startup decision path.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with the behavior change.
- [x] Update this file with review outcomes.

## Review (2026-03-07 Rewarded Ads Without ATT Requirement)
- [x] Implemented and verified.
- Root cause:
  - `AdMobStartupService` returned failure whenever `TrackingConsentService.ensureTrackingAuthorization()` was false.
  - Rewarded/banner flows treated that as a hard dependency and surfaced `Rewarded ads require tracking permission on iOS.` even though AdMob can still serve non-personalized ads without ATT authorization.
- Fixes:
  - `lib/services/ads/admob_startup_service.dart`: replaced the ATT hard gate with an ATT-aware startup result that always initializes AdMob on supported iOS builds and caches whether requests must be non-personalized.
  - `lib/services/ads/rewarded_ads_service.dart`: switched rewarded loads to the startup service’s consent-aware `AdRequest` and removed the misleading tracking-required messages.
  - `lib/features/ads/admob_banner_slot.dart`: switched banner loads to the same consent-aware startup/request path so ATT denial does not suppress banner ads either.
  - `test/admob_startup_service_test.dart`: added regression coverage for denied ATT, authorized ATT, and cached initialization behavior.
- Verification:
  - `dart format lib/services/ads/admob_startup_service.dart lib/services/ads/rewarded_ads_service.dart lib/features/ads/admob_banner_slot.dart test/admob_startup_service_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-05 App Review Store Fallback)
- [x] Refactor `ReviewPromptService` with injectable review/settings dependencies for deterministic tests.
- [x] Add App Store fallback flow (`openStoreListing` with app id `6757725650`) when in-app review is unavailable or fails.
- [x] Add analytics events for review prompt shown / store fallback opened / fallback failure.
- [x] Add unit tests covering in-app review path and App Store fallback path.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this behavior.
- [x] Update this file with review outcomes.

## Review (2026-03-05 App Review Store Fallback)
- [x] Implemented and verified.
- Changes:
  - `lib/services/review/review_prompt_service.dart` now uses injectable interfaces (`AppReviewGateway`, `ReviewPromptSettingsStore`) for testability.
  - Added iOS fallback to App Store rating page via `openStoreListing(appStoreId: '6757725650')` when `isAvailable` is false or `requestReview` throws.
  - Added analytics events: `review_prompt_shown`, `review_store_opened`, `review_prompt_failed`, `review_store_open_failed`.
  - Prompt milestone progression and `reviewLastPromptAt` are updated only when in-app prompt or store fallback succeeds.
- Tests:
  - Added `test/review_prompt_service_test.dart` covering:
    - in-app prompt success path
    - unavailable -> App Store fallback path
    - `requestReview` failure -> App Store fallback path
    - fallback failure -> milestone not advanced
- Verification:
  - `dart format lib/services/review/review_prompt_service.dart test/review_prompt_service_test.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-05 Force Update Store URL + Auto Detection Check)
- [x] Trace force-update prompt store URL source and identify incorrect/default fallback paths.
- [x] Update iOS force-update store URL fallback to `https://apps.apple.com/jp/app/id6757725650`.
- [x] Align debug force-update prompt and crash fallback update button with the same App Store URL.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with behavior changes.
- [x] Update this file's review section with verification outcomes.

## Review (2026-03-05 Force Update Store URL + Auto Detection Check)
- [x] Implemented and verified.
- Store URL path/root cause:
  - Force update prompts read `app_config.store_url` through `AppConfigService`.
  - Debug prompt fallback URL still pointed to placeholder `https://example.com/update`.
  - Crash fallback path had no guaranteed app-store URL when config was unavailable.
- Fixes:
  - `lib/services/app_config/app_config_service.dart`: added `iosAppStoreUrl = https://apps.apple.com/app/id6757725650` and made iOS force-update prompts always use this URL (independent from backend `store_url`).
  - `lib/shared/force_update/force_update_gate.dart`: debug prompt fallback URL now uses `AppConfigService.iosAppStoreUrl`.
  - `lib/shared/force_update/crash_update_guard.dart`: crash-screen update button now falls back to `AppConfigService.iosAppStoreUrl`.
- Auto-detection check result:
  - Existing auto-detection is already implemented in `ForceUpdateGate`.
  - Trigger points: app start (`initState`) and app foreground resume (`didChangeAppLifecycleState` on `resumed`).
  - Behavior: compares current app version against `minimum_required_version` / `latest_available_version` from `app_config` and shows hard/soft update dialogs accordingly.
- Verification:
  - `dart format lib/services/app_config/app_config_service.dart lib/shared/force_update/force_update_gate.dart lib/shared/force_update/crash_update_guard.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-05 Localized IAP Currency)
- [x] Trace current store IAP price-render path and confirm why JPY fallback is used for non-JPY storefronts.
- [x] Update store price formatting logic to prefer App Store localized price strings for all storefront currencies.
- [x] Add regression tests for `StoreItem.localizedIapPrice` covering non-JPY storefront prices and fallback scenarios.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with root cause + fix details.
- [x] Update this file's review section with verification outcomes.

## Review (2026-03-05 Localized IAP Currency)
- [x] Implemented and verified.
- Root cause: `StoreItem.localizedIapPrice()` used `_shouldUseCatalogJpyFallback` to replace valid storefront-localized prices with catalog JPY when the storefront currency code was not `JPY`, causing users in non-JP regions to still see `JPY 300`.
- Fix in `lib/features/store/models/store_item.dart`:
  - Removed non-JPY forced JPY fallback logic.
  - Now always prefers `Package.storeProduct.priceString` or `StoreProduct.priceString` when available.
  - Keeps JPY fallback only when no store price string is available and catalog currency is JPY.
- Regression tests added in `test/store_item_test.dart`:
  - package localized price is used even when catalog currency is JPY.
  - direct store localized price is used for non-JPY storefront currency.
  - JPY fallback only when store price is unavailable.
  - unavailable label when neither localized price nor JPY fallback exists.
- Verification:
  - `dart format lib/features/store/models/store_item.dart test/store_item_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `flutter test test/store_item_test.dart`
  - All passed.

## Plan
- [x] Reproduce and trace chatroom focus-loss path where tapping composer opens keyboard then immediately closes.
- [x] Stabilize chat composer/message-list widget identity across keyboard visibility transitions so TextField focus is preserved.
- [x] Keep keyboard-dismiss affordance without allowing composer tap-to-focus to trigger unintended dismiss.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with root cause + fix details.
- [x] Update `tasks/todo.md` review section with verification outcomes.
- [x] Update `tasks/lessons.md` with this regression pattern (user-follow-up correction).

## Review
- [x] Implemented and verified.
- Root cause: `ChatRoomView` inserted/removes `Stack` children based on keyboard visibility; without stable keys, composer subtree could be rematched/rebuilt on inset changes and drop `TextField` focus immediately after tap.
- Fixes in `lib/features/chat/chat_room_view.dart`:
  - Added stable keys for keyboard underlay, message list container, dismiss strip, and composer container so keyboard visibility transitions preserve composer element identity/focus.
  - Kept dismiss strip in tree and gated it with `IgnorePointer(ignoring: !isKeyboardVisible)` instead of conditionally adding/removing it during focus transitions.
  - Restored `tap outside` dismiss on the message-list layer only and kept drag-dismiss trigger on positive downward delta (`dy > 0`) so dismiss works reliably without impacting composer tap focus.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.

## Follow-up Plan (2026-03-04)
- [x] Switch chat message-list `keyboardDismissBehavior` to `ScrollViewKeyboardDismissBehavior.onDrag`.
- [x] Remove custom 24px drag-dismiss strip from `ChatRoomView` to simplify keyboard-dismiss logic.
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with the simplification change.
- [x] Update `tasks/lessons.md` per user correction/preference for simpler built-in behavior.

## Follow-up Review (2026-03-04)
- [x] Implemented and verified.
- Changed `ChatMessageList` keyboard dismiss mode from `manual` to `onDrag` so drag-to-dismiss is handled natively by Flutter list scrolling.
- Removed the custom 24px keyboard-dismiss strip from `ChatRoomView` to reduce bespoke gesture code and avoid duplicate drag-dismiss paths.
- Kept message-list-layer tap-outside dismiss in `ChatRoomView` for explicit tap-based keyboard close behavior.
- Verification:
  - `dart format lib/features/chat/chat_message_list.dart lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.

## Follow-up Plan 2 (2026-03-04)
- [x] Investigate keyboard-hide end-frame screen shake (downward overshoot then upward snap) after switching to `onDrag`.
- [x] Clamp composer bottom inset so it never drops below safe-area bottom during keyboard dismissal animation.
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this optimization.
- [x] Update `tasks/lessons.md` with keyboard-inset clamping guideline.

## Follow-up Review 2 (2026-03-04)
- [x] Implemented and verified.
- Root cause: during keyboard hide animation, `viewInsets.bottom` can transiently drop below device safe-area bottom; composer/list bottom spacing followed that lower value, creating a short downward overshoot then final upward snap when inset reached zero.
- Fix in `lib/features/chat/chat_room_view.dart`: compute composer base inset as `max(viewInsets.bottom, media.padding.bottom)` before applying composer bottom padding.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.

## Follow-up Plan 3 (2026-03-04)
- [x] Align iOS keyboard-corner underlay color with chatroom background to remove gray-square corner mismatch.
- [x] Keep scaffold background logic unchanged (no keyboard-visible global swap).
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this visual fix.
- [x] Update `tasks/lessons.md` with underlay color-source guideline.

## Follow-up Review 3 (2026-03-04)
- [x] Implemented and verified.
- Root cause: keyboard corner underlay was using a hardcoded gray tone that did not match the chatroom background surface.
- Fix in `lib/features/chat/chat_room_view.dart`: set `keyboardUnderlayColor` to `scaffoldBackgroundColor`, so exposed keyboard-corner area inherits the same base background color as the room.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.

## Follow-up Plan 4 (2026-03-04)
- [x] Fix white keyboard-corner artifacts for gradient/image room backgrounds where flat-color underlay still mismatches.
- [x] Remove iOS keyboard underlay color layer so keyboard corner cutouts reveal the actual chatroom background rendering.
- [x] Run `dart format` on touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this final keyboard-corner fix.
- [x] Update `tasks/lessons.md` with underlay-removal guideline for decorated backgrounds.

## Follow-up Review 4 (2026-03-04)
- [x] Implemented and verified.
- Root cause: even after switching to a shared flat color source, keyboard-corner artifacts persisted on gradient/image room backgrounds because a single-color underlay cannot match decorated backgrounds.
- Fix in `lib/features/chat/chat_room_view.dart`: removed the keyboard underlay `Positioned` layer entirely, so rounded keyboard corners expose the actual room decoration (gradient/image) instead of a synthetic fill color.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.

## Plan (2026-03-05 Room Invite Code Failure Investigation)
- [x] Reproduce the invite-code request failure path and capture the exact failing callsite/error payload.
- [x] Trace frontend invite-code flow (UI action -> repository/service -> Supabase RPC/query) and identify failure branch.
- [x] Verify backend contract and constraints (RPC logic/RLS/room ownership rules) against affected multi-room behavior.
- [x] Implement minimal fix for confirmed root cause (frontend/backend as needed) without breaking existing room flows.
- [x] Run `dart format` on touched Dart files (if any).
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with root cause + fix details.
- [x] Update this file with review outcomes.

## Review (2026-03-05 Room Invite Code Failure Investigation)
- [x] Implemented and verified.
- Root cause:
  - Home invite CTA always called owner-only RPC `regenerate_invite_code` for every room.
  - Backend function explicitly requires `room_members.role = 'owner'`, so members consistently received `not_owner`.
  - `userFacingError` lacked `not_owner` mapping, so users saw generic retry-style failure text.
- Fixes:
  - `lib/features/home/flows/home_invite_flow.dart`: gate invite behavior by current room role.
    - Owner: keep current behavior (`regenerate_invite_code`).
    - Member: no regenerate call; open invite dialog using current room invite code when available.
    - Member + no local code: show localized permission-denied snackbar.
  - `lib/shared/errors/user_facing_error.dart`: map `not_owner` to localized permission-denied text.
- Verification:
  - `dart format lib/features/home/flows/home_invite_flow.dart lib/shared/errors/user_facing_error.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-05 Multi Invite Codes + Member Generation)
- [x] Design backward-compatible invite-code model that supports up to 3 active codes and member generation without breaking old clients.
- [x] Implement Supabase migration (new table + backfill + RPC updates for create/list/revoke/join/create_room/regenerate behavior).
- [x] Apply migration through Supabase MCP and verify schema/function availability.
- [x] Update Flutter invite flow to call new member-capable RPC and display active invite codes.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update memory-bank docs with new invite-code architecture/schema/progress.
- [x] Update this file with review outcomes.

## Review (2026-03-05 Multi Invite Codes + Member Generation)
- [x] Implemented and verified.
- Backend changes:
  - Added migration `supabase/migrations/20260305231000_add_multi_invite_codes_and_member_generation.sql`.
  - New table: `public.room_invite_codes` (room-scoped multi-code storage with expiry/revoke metadata).
  - Backfilled legacy `rooms.invite_code` into `room_invite_codes` (including null-`created_by` legacy compatibility).
  - New RPCs:
    - `create_room_invite_code(p_room_id uuid, p_expires_in_minutes int default 60)` (members can generate; max 3 active; owner rotates oldest when full; members rotate own oldest when needed).
    - `list_room_invite_codes(p_room_id uuid)` (returns active codes for room members).
    - `revoke_room_invite_code(p_room_id uuid, p_code text)` (owner can revoke any; members can revoke own non-null-created codes).
  - Updated RPCs:
    - `join_room_by_code(code text)` now checks `room_invite_codes` first, then legacy `rooms.invite_code`.
    - `regenerate_invite_code(p_room_id uuid)` now delegates to `create_room_invite_code` (owner-only gate retained).
    - `create_room(p_name text)` now seeds `room_invite_codes` for backward-compatible initial room code creation.
- Frontend changes:
  - `lib/features/home/flows/home_invite_flow.dart`:
    - Invite action now calls `create_room_invite_code` (member-capable) instead of owner-only regenerate RPC.
    - Invite dialog now supports and displays multiple active codes (up to 3), each tap-to-copy.
    - Added fallback path: if room is full (`invite_code_limit_reached`), fetch and display existing active codes.
  - `lib/shared/errors/user_facing_error.dart`:
    - Added error mapping for `not_member` and `invite_code_limit_reached` to localized permission-denied message.
- Supabase MCP verification:
  - Applied migration successfully via `mcp__supabase__apply_migration`.
  - Verified new table/functions exist via `mcp__supabase__execute_sql`.
  - Ran advisors (`security`, `performance`) to sanity-check post-migration state.
- Verification:
  - `dart format lib/features/home/flows/home_invite_flow.dart lib/shared/errors/user_facing_error.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Plan (2026-03-05 Single-Code Invite Dialog UX)
- [x] Keep multi-code backend validity model unchanged (up to 3 active codes) while reducing invite dialog output to a single code.
- [x] Update Home invite dialog rendering to show only one copyable code (same UX shape as original flow).
- [x] Preserve fallback behavior for limit/full cases by selecting one active code to display.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update memory-bank progress log with this UX decision.
- [x] Update this file review section.

## Follow-up Review (2026-03-05 Single-Code Invite Dialog UX)
- [x] Implemented and verified.
- Kept backend semantics unchanged: rooms can still have up to 3 simultaneously active invite codes.
- Changed `lib/features/home/flows/home_invite_flow.dart` so invite dialog now shows exactly one code:
  - successful new-code generation shows the newly generated code;
  - limit/fallback path shows one existing active code (`list_room_invite_codes` newest item).
- Verification:
  - `dart format lib/features/home/flows/home_invite_flow.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Plan (2026-03-05 Shared Invite Rotation Rule)
- [x] Change invite-code cap behavior so rotation is shared across owner/members (no role-based distinction when full).
- [x] Apply a Supabase migration updating `create_room_invite_code` logic.
- [x] Verify updated RPC exists and behavior is deployed.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update memory-bank progress with the policy change.
- [x] Update this file review section.

## Follow-up Review (2026-03-05 Shared Invite Rotation Rule)
- [x] Implemented and verified.
- Added migration `supabase/migrations/20260305235500_share_invite_code_rotation_across_members.sql`.
- Updated DB function `create_room_invite_code` so once a room has 3 active codes, the oldest active code is rotated out regardless of caller role (owner/member now share the same rotation pool).
- Kept other invite mechanics unchanged (member must still be active room member; max active codes remains 3; single-code dialog UX remains unchanged).
- Deployment/verification:
  - Applied migration via Supabase MCP (`apply_migration`).
  - Verified active function definition via `pg_get_functiondef('public.create_room_invite_code(uuid, integer)'::regprocedure)`.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Plan (2026-03-10 Telegram-Style Chat Composer Polish)
- [x] Inspect the active `ChatRoomViewV2` composer path and package constraints before changing visuals.
- [x] Update the active chat composer shell, input field, send-state treatment, and reply preview toward a Telegram-like UI.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` and this file with the composer-polish summary and verification results.

## Review (2026-03-10 Telegram-Style Chat Composer Polish)
- [x] Implemented and verified.
- UI changes:
  - `lib/features/chat/chat_room_view_v2.dart`: replaced the stock `flutter_chat_ui` composer shell with a custom `_TelegramComposer` that still uses package callbacks/height spacing but renders a rounded floating surface, a cleaner inner input pill, a circular attachment action, and an animated send button that visibly switches between inactive and active states.
  - `lib/features/chat/chat_room_view_v2.dart`: tightened `_ReplyComposerBar` spacing, tinted it with the active chat accent, and reduced the close affordance weight so it reads more like a quoted-message preview than a secondary card.
  - `pubspec.yaml`: added direct `provider` dependency because the custom composer now reads `ComposerHeightNotifier` from the package provider tree instead of relying on a transitive-only import.
- Verification:
  - `flutter pub get`
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Telegram Composer Pill Simplification)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` so the composer no longer draws an outer black/white wrapper around the row; the visible chat bar now consists only of the camera pill, message-input pill, and send pill.
- Standardized the action-pill sizing with the input pill by setting both camera and send buttons to a 48px circle and giving the text input a matching 48px minimum height.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Dark Composer Contrast Tuning)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` dark-mode composer materials so the camera/input/send pills use more solid charcoal fills while keeping slight translucency.
- Added subtle dark-mode borders and shadows to all three pills so they separate cleanly from dark room backgrounds without reintroducing the removed outer wrapper.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Keyboard Corner Backdrop Removal)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` so the chat route no longer relies on `Scaffold` keyboard resize; the custom composer now positions itself from `MediaQuery.viewInsets.bottom` instead.
- This removes the separate rectangular background that was showing through the iOS keyboard’s rounded top-left/top-right corners while keeping the composer lifted just above the keyboard.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Telegram Message Bubble Polish)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` to use a custom `_TelegramTextMessageBubble` for text messages so sent/received bubbles now have flatter Telegram-style color blocks, asymmetric bubble corners, tighter padding, and quieter timestamp styling.
- Tightened `_MessageEnvelope` quoted-reply presentation so reply previews feel like inline references instead of separate cards, and refreshed `_FeedCard` / `_SystemPill` to match the flatter bubble hierarchy.
- Left the top bar unchanged for this pass, per request.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Text Bubble Width Fix)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` so `_MessageEnvelope` no longer stretches its child across the available row width; text bubbles and quoted previews now size to their content while preserving right alignment for the current user and left alignment for the other party.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Text Size + Timestamp Placement)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` text bubbles so the main message body now uses a more standard 16px chat size, and the timestamp label is slightly larger and explicitly positioned at the bubble’s bottom-right corner.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).

## Follow-up Review (2026-03-10 Sender Labels + Feed Metadata Restore)
- [x] Implemented and verified.
- Updated `lib/features/chat/chat_room_view_v2.dart` so received text bubbles now show the sender name at the top-left, and feed cards now also show the sender name in that position.
- Updated `lib/features/chat/chat_room_view_v2.dart` feed cards so the `+coins` badge includes the candy icon again and the card shows a small timestamp at the bottom-right.
- Verification:
  - `dart format lib/features/chat/chat_room_view_v2.dart`
  - `flutter analyze`
  - `flutter test`
  - Passed (`feed_flow_integration_test` remained skipped without required env vars, as expected).
