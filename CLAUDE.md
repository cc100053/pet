# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Before Non-Trivial Work

Read all `memory-bank/*.md` files (excluding `memory-bank/archive/`) before making non-trivial code changes. Update them if your work changes current behavior or decisions. For repo-specific workflows, read the matching skill file first:
- Shared item rollout (new backgrounds, furniture, pets): `.codex/skills/shared-item-rollout/SKILL.md`
- Release notes / App Store Connect metadata: `.codex/skills/release-notes-sync/SKILL.md`
- Crashlytics triage: `.codex/skills/firebase-crashlytics-triage/SKILL.md`

## Commands

```sh
# Dependencies
flutter pub get

# Run
flutter run

# Lint (required before shipping)
flutter analyze

# Format
dart format lib test

# Tests
flutter test
flutter test test/widget_test.dart
flutter test test/widget_test.dart --plain-name "test name"
flutter test -r expanded   # verbose output

# Localization (after editing any lib/l10n/*.arb file)
flutter gen-l10n

# Asset bundle verification (after adding nested asset folders)
flutter build bundle

# iOS clean build (when CocoaPods/Xcode gets flaky)
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run
```

### App Store Connect metadata
```sh
asc versions list --app 6757725650
asc localizations upload --version <VERSION_ID> --locale ja --path .asc/version-localizations/ja.strings
asc localizations list --version <VERSION_ID> --output table
```

## Architecture

### Feature Layout (`lib/features/`)
- **`home/`** — signed-in shell: room switching, pet HUD, decor editing, unread badges, invite code/link sharing, feed/gallery previews, shared-item compatibility prompts. Owns global feed upload completion/failure side effects.
- **`chat/`** — active route is `ChatRoomViewV2`. Manages bounded message windows (latest 20 open, 20-message older pages, 80-message visible cap), Hive cache (newest 20 per room), realtime, replies/reactions, edit/delete, and keyboard behavior. Chat observes the feed upload queue only for local optimistic-row reconciliation.
- **`feed/`** — photo capture + durable Hive/Riverpod upload queue. `FeedCaptureView` only enqueues; it does not process.
- **`shop/`** — backgrounds, furniture, consumables, RevenueCat IAP, floating purchase notices, repeatable furniture purchase.
- **`profile/`** — profile editing, avatar framing editor (full-screen circle crop with drag/pinch/slider), R2 upload via `avatar_upload` Edge Function, account deletion.
- **`gallery/`** — Memory photo calendar.
- **`ads/`** — ATT-aware AdMob rewarded + banner. iOS AdMob banner `AdWidget`s are disabled in debug by default to avoid hot-restart platform-view id collisions; set `ADMOB_ENABLE_DEBUG_BANNER_VIEWS=true` only for intentional local banner tests.

### Services & Shared (`lib/services/`, `lib/shared/`)
- `ProfileBootstrapService` — centralized profile creation and timezone sync, shared by Home and Profile.
- `AppInviteLinkService` — handles app/universal links, persists pending invite codes for signed-out opens, joins via `join_room_by_code` after Home bootstrap.
- Invite URLs use `invite_code` query param (not `code`) to avoid Supabase Auth PKCE callback collisions.
- Firebase Hosting serves the `/invite` fallback page and `.well-known` association files.

### State Management
Riverpod throughout. Use `ref.watch(...)` in `build`, `ref.read(...)` in callbacks. Keep providers pure; do I/O in services. Define providers at file/library scope, not inside widgets.

### Backend
- **Supabase** (Auth, Postgres with strict RLS, Realtime). Use RPCs for gameplay, economy, ownership, and shared-room invariants.
- **Supabase MCP** — always use MCP tools for schema/function/policy changes; execute SQL directly, never just display it. Migrations go in `supabase/migrations/` with timestamp prefix.
- **Edge Functions**: `notify_friend`, `feed_validate`, `hunger_tick_dispatch`, `avatar_upload`, `delete_account`. Functions with `verify_jwt=true` require HS256 JWTs; ES256 tokens 401 at the gateway.
- **Cloudflare R2** — feed photos and avatars (10 MB cap, WebP target ~100 KB).
- **Realtime** — chat/system events, reaction refresh, furniture inventory revision signals (`room_item_inventory_revisions`).

### Database Key Contracts
- `profiles.avatar_url` — `preset:<id>` or remote R2 URL.
- `rooms.invite_code` — legacy primary; `room_invite_codes` table supports up to 3 active codes. Normal share calls `get_or_create_room_invite_code(...)`.
- `messages` — `edited_at`, `deleted_at`, `deleted_by` for soft edit/delete. Soft delete clears `body` and leaves a timeline placeholder. `sender_id` may be null for system events.
- `items.metadata` — carries `asset_path`, `visibility_mode`, `min_app_version`, `shop_visibility`, fallback metadata.
- `room_furniture.scale` clamped `0.8..2.0`; positions normalized `0..1`; `flip_x` for per-instance horizontal flip.
- Version-gated shared decor: `is_active = false`, visible via `get_visible_shop_items(p_app_version)`. Hidden catalog-only decor uses `metadata.shop_visibility = 'hidden'`.

### Backward-Compatibility Rules
- If a parameter change can affect old app versions, propose backward-compatible alternatives (version-gated flags, new optional params, additive RPCs) and wait for approval before implementing.
- Prefer additive/backward-compatible RPCs over changing parameters used by old clients.
- New shared items (pets, furniture, backgrounds) must include version-gated visibility and old-client render fallbacks. Use the shared-item rollout skill.

## UI System (Juice UI)

- **All clickable elements**: use `JuicyScaleButton`. Trigger business logic immediately on release; do not await animations.
- **Blocking feedback/confirmations**: `showJuiceToast` — `JuicePosition.center` for complex inputs/confirmations, `JuicePosition.bottom` for standard warnings. Validate inside the dialog with `StatefulBuilder`; only `Navigator.pop` on success.
- **Non-blocking success feedback**: `showJuiceSnackbar` — uses Overlay, does not dim, auto-dismisses after 2.5 s.
- **Visual**: thick black borders (2–3 px), `BorderRadius.circular(32)` for cards/toasts, soft cream gradient (`white` → `0xFFFFF7EA`), `BoxShadow` depth (`alpha: 0.15`, `offset: Offset(0,4)`). Font: `GoogleFonts.mPlusRounded1c` w900 headings / w700–800 body. Use `withValues(alpha: ...)` not `withOpacity(...)`.

## Localization

ARB files live in `lib/l10n/`. All user-facing strings must use `AppLocalizations.of(context)!`. After editing any `.arb` file run `flutter gen-l10n`. App Store Connect strings live in `.asc/version-localizations/`; keep them separate from in-app What's New bullets.

## MLKit Build Toggle

MLKit binary frameworks do not support iOS Simulator on Xcode 26+. Toggle in `pubspec.yaml`:
- **Simulator**: comment out `google_mlkit_image_labeling` (uses mock labels).
- **Device/TestFlight**: uncomment it.
After toggling: `flutter clean && flutter pub get && cd ios && pod install`.

## Task & Lesson Tracking

- Write plans to `tasks/todo.md` with checkable items before starting implementation.
- After any correction from the user, update `tasks/lessons.md` with the pattern to prevent recurrence.
- After changes, always run `flutter analyze` and `flutter test`.
- When a step requires a website or dashboard action, mark it `[USER ACTION REQUIRED]`.
