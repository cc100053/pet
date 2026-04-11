# Architecture

This active file is intentionally compact because agents must read every active
`memory-bank/*.md` file before non-trivial work. The full pre-compaction snapshot
is in `memory-bank/archive/architecture_20260411_pre_compaction.md`.

## Source Of Truth
- Flutter app code: `lib/`
- Tests: `test/`
- Supabase migrations and RPC definitions: `supabase/migrations/`
- Edge Functions: `supabase/functions/`
- Longer product/design notes: `docs/`
- Current operational summary: this file plus `memory-bank/database-schema.md`

When exact behavior matters, inspect the current code, latest relevant migration,
and live Supabase state. Do not rely on older memory-bank wording as canonical.

## App Shape
- `lib/app/`: app bootstrap, theme, status-bar defaults.
- `lib/features/auth/`: auth gate and OAuth sign-in UI.
- `lib/features/home/`: signed-in home shell, room switching, pet HUD, room decor,
  unread badges, feed/gallery previews, and room compatibility prompts.
- `lib/features/chat/`: active chat route is `ChatRoomViewV2`; it owns bounded
  message windows, realtime/cache refresh, deterministic timeline rendering,
  reply/reaction flows, keyboard behavior, and photo/chat actions.
- `lib/features/feed/`: camera capture, ML Kit labeling, client-side WebP
  preparation, `feed_validate` invocation, and reward feedback.
- `lib/features/shop/`: in-app Shop for backgrounds, furniture, consumables,
  RevenueCat products, floating purchase notices, and room-decor return flow.
- `lib/features/profile/`: profile editing, avatar presets/upload, account deletion.
- `lib/features/gallery/`: Memory calendar and fullscreen photo entry points.
- `lib/features/pet/`: pet catalog, version-gated pet availability, and leveling.
- `lib/features/ads/`: ATT-aware AdMob startup and ad surfaces.
- `lib/services/`: shared Supabase, FCM, IAP, app-config, crash, profile, chat,
  review, timezone, audio, and performance services.
- `lib/shared/`: reusable UI, dialogs, image wrappers, keyboard helpers, debug
  tools, What's New, and force-update surfaces.

## Current Architecture Decisions
- Home and Profile share `ProfileBootstrapService` so profile creation and device
  timezone sync do not drift.
- Shared room content must be mixed-version safe:
  - new shared decor is version-gated in Supabase catalog metadata
  - unsupported active backgrounds fall back to the default background
  - unsupported placed furniture is hidden
  - unsupported shared pet types fall back to `PetCatalog.defaultPetId`
  - affected clients reuse the one-shot room compatibility update prompt
- Furniture inventory is room-shared on new clients via
  `get_room_furniture_inventory`; `room_item_inventories` still records buyer
  attribution for backward compatibility.
- Furniture transform persistence prefers `update_room_furniture_transform(...)`
  for atomic scale + position writes, with legacy per-field RPC fallback.
- Chat opens with only the latest 20 messages, loads older pages in chunks of 20,
  keeps an 80-message visible cap, buffers realtime while browsing history, and
  stores only the newest 20 canonical messages per room in Hive.
- Chat reactions use separate surfaces: long-press quick actions and reaction-chip
  details. The shared emoji picker intentionally has no search mode.
- Shared image display uses `CachedNetworkImageView` cache bounds from rendered
  layout, while preserving original displayed provider semantics.
- Startup caps Flutter image cache to reduce iOS retained decoded-image pressure.
- Force-update and What's New are sequenced together: hard update blocks What's
  New; eligible upgraded versions show bundled release notes once.

## Backend Shape
- Supabase Auth supports Apple/Google sign-in.
- Postgres data is room-scoped with strict RLS; use RPCs for writes that need
  gameplay, economy, or ownership invariants.
- Realtime powers chat/system events and reaction refreshes.
- Cloudflare R2 stores feed/avatar media.
- Edge Functions:
  - `notify_friend/feed_validate`: image validation/upload, label mapping, feed
    rewards, message insert, and notification trigger.
  - `notify_friend`: FCM sender for feed/store/system messages; currently runs
    with `verify_jwt=false` and performs function-level auth checks.
  - `hunger_tick_dispatch`: scheduled hunger tick and alert dispatcher.
  - `avatar_upload`: avatar image upload to R2 and `profiles.avatar_url` update.
  - `delete_account`: authenticated account deletion using service role.
- Edge Functions with gateway `verify_jwt=true` require HS256 Supabase Auth JWTs;
  ES256/asymmetric tokens are rejected at the gateway.

## Platform Notes
- Android notifications use a native `FirebaseMessagingService` with room-thread
  grouping, pet-avatar large icons, and Flutter tap routing through `MainActivity`.
- iOS notifications use `PetTomoNotificationServiceExtension` for reliable
  title/body rewrite and room thread IDs.
- iOS Crashlytics dSYM upload is wired through `ios/scripts/upload_crashlytics_symbols.sh`
  and runs late in the Runner build phases.
- ML Kit binary frameworks do not support iOS Simulator on Xcode 26+; see
  `memory-bank/tech-stack.md` for the pubspec toggle.

## When To Read More
- Exact DB/RPC shape: inspect latest matching files in `supabase/migrations/` and
  live Supabase MCP state.
- Historical architecture detail: `memory-bank/archive/architecture_20260411_pre_compaction.md`.
- Older implementation logs: `memory-bank/archive/progress_archive.md`.
