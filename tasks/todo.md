# TODO

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
