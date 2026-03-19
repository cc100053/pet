# TODO

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
