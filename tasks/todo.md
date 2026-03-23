# TODO

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
