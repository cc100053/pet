# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260509_pre_compaction.md`.

## Source Of Truth
- App/runtime behavior: `lib/`, `test/`
- DB/RPC/RLS/Edge Functions: `supabase/migrations/`, `supabase/functions/`
- Workflow/runbooks: `docs/`
- Historical notes: `memory-bank/archive/`

Use this file as a map, not as canonical source.

## App Shape
- `lib/features/home/`: signed-in shell, rooms, shared-room rendering, pet HUD,
  decor, invites, compatibility prompts, and pet equipment UI.
- `lib/features/chat/`: `ChatRoomViewV2` owns bounded history, realtime, Hive
  cache, replies/reactions, edit/delete, and keyboard behavior.
- `lib/features/feed/`: capture and durable Hive/Riverpod upload queue.
- `lib/features/shop/`: decor, consumables, room-scoped pet equipment,
  RevenueCat, and purchase feedback.
- `lib/features/profile/`, `gallery/`, `pet`, `ads`: avatar/profile, memory
  photos, pet visuals/selection, and ATT-aware AdMob.
- `lib/services/`, `lib/shared/`: Supabase/FCM/IAP/config/crash services,
  force update, What's New, shared widgets, and debug tools.

## Current Decisions
- Profile bootstrap is centralized in `ProfileBootstrapService`.
- Shared room content is mixed-version safe. New shared backgrounds, furniture,
  and pets need version-gated visibility, old-client fallback, and the existing
  compatibility prompt; `SharedDecorCompatibility` is the app-side hub.
- Pet equipment is room-scoped end to end: purchase, inventory, equip state, and
  preview rendering key off `room_id`.
- Pet rendering prefers bundled PNG frame sequences while keeping GIF paths as
  stable source/fallback ids. Runtime sequence playback flows through
  `PetAnimationFrames`, `PetAnimationFrameBuilder`, and `PetAnimatedImage`.
- Socket placement is authored in Godot, then translated into
  `PetSocketCatalog` and `EquipmentCatalog`; the Flutter fit tool is debug-only.
- `PetSocketConfig.sleepHiddenSlots` controls which equipment slots are suppressed
  during the sleep animation for a given pet (e.g. tiger hides `body` because the
  sleeping pose occludes the torso). `resolve()` returns `null` for hidden slots;
  `PetEquipmentOverlay` already skips `null` sockets, so no overlay changes are needed.
- Shop economy RPC calls and parsing are behind `EconomyPurchaseAdapter`; UI
  state deltas land in `ShopEconomyState`.
- Chat opens on the latest 20 messages, pages older messages by 20, caps visible
  history at 80, and caches newest canonical messages in Hive.
- Feed uploads are queue-owned. Home owns global completion/failure effects and
  refreshes the feed's original room; Chat reconciles optimistic rows locally.
- Force update and What's New remain separate gates.
- Invite links use `invite_code`; avoid bare `code` because Supabase Auth can
  treat it as a PKCE callback parameter.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back room-scoped gameplay and chat.
- Active Edge Functions: `notify_friend/feed_validate`, `notify_friend`,
  `hunger_tick_dispatch`, `avatar_upload`, `delete_account`.
- `notify_friend` remains `verify_jwt=false` for webhook compatibility and does
  function-level auth checks; `verify_jwt=true` functions expect HS256 Supabase
  Auth JWTs at the gateway.
- Firebase Hosting static pages and GEOFlow work live in
  `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- iOS Crashlytics dSYM upload goes through
  `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Workflow notes: `memory-bank/progress.md`, `docs/`
- Historical snapshots: `memory-bank/archive/`
