# TODO

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
