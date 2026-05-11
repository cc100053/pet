# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshot:
`memory-bank/archive/architecture_20260502_pre_compaction.md`.

## Source Of Truth
- App/runtime behavior: `lib/`, `test/`
- DB/RPC/RLS/Edge Functions: `supabase/migrations/`, `supabase/functions/`
- Workflow/runbooks: `docs/`
- Historical notes: `memory-bank/archive/`

Use this file as a map, not as canonical source.

## App Shape
- `lib/features/home/`: signed-in shell, room switching, shared-room rendering,
  pet HUD, decor, invite flows, compatibility prompts, and pet equipment UI.
- `lib/features/chat/`: `ChatRoomViewV2` owns bounded message windows, realtime,
  Hive cache refresh, replies/reactions, and keyboard behavior.
- `lib/features/feed/`: capture plus durable Hive/Riverpod upload queue.
- `lib/features/shop/`: decor, consumables, room-scoped pet equipment,
  RevenueCat, and purchase feedback.
- `lib/features/profile/`, `gallery/`, `pet/`, `ads/`: profile/avatar flows,
  memory photos, pet visuals/selection, ATT-aware AdMob.
- `lib/services/` and `lib/shared/`: Supabase/FCM/IAP/config/crash services,
  force update, What's New, shared widgets, and debug tools.

## Current Decisions
- Profile bootstrap is centralized in `ProfileBootstrapService`; Home and
  Profile share missing-profile creation and timezone sync.
- Shared room content is mixed-version safe. New shared backgrounds, furniture,
  and pets must use version-gated visibility plus old-client fallback and the
  shared compatibility prompt. `SharedDecorCompatibility` is the app-side hub.
- Pet equipment is room-scoped end to end: purchase, inventory, equip state,
  and preview rendering all key off `room_id`.
- Pet rendering prefers bundled PNG frame sequences while keeping GIF asset
  paths as stable source/fallback ids. Sequence playback flows through
  `PetAnimationFrames`, `PetAnimationFrameBuilder`, `PetAnimatedImage`, and
  `PetAnimationTimeline`.
- Socket placement is authored in Godot, then translated into
  `PetSocketCatalog` and `EquipmentCatalog`. Keep the legacy Flutter fit tool as
  debug-only; future fitting should happen in Godot.
- Shop economy RPC calls and parsing are concentrated behind
  `EconomyPurchaseAdapter`; UI state deltas land in `ShopEconomyState`.
- Chat opens on the latest 20 messages, loads 20-message older pages, caps the
  visible window at 80, and caches the newest 20 canonical messages in Hive.
- Feed uploads are queue-owned. Home owns global completion/failure side
  effects, replays unacknowledged terminal jobs after lifecycle resume, and
  refreshes the feed's original room state; Chat only reconciles optimistic rows
  locally.
- Force update and What's New remain separate gates: hard update first, then
  eligible bundled release notes once.
- Invite links use `invite_code` in the URL and complete joining through
  `join_room_by_code`; avoid bare `code` query params because Supabase Auth can
  treat them as PKCE callback parameters.

## Backend And Platform
- Supabase Auth + Postgres + Realtime back room-scoped gameplay and chat. Use
  RPCs for gameplay/economy/shared-state invariants.
- Edge Functions in active use: `notify_friend/feed_validate`,
  `notify_friend`, `hunger_tick_dispatch`, `avatar_upload`, `delete_account`.
- `notify_friend` remains `verify_jwt=false` for webhook-mode compatibility and
  does function-level auth checks; functions with `verify_jwt=true` expect HS256
  Supabase Auth JWTs at the gateway.
- Firebase Hosting static marketing, guides, support/legal pages, invite
  fallback pages, and app/universal-link files are now owned by the external
  `/Users/fatboy/geo-marketing` workspace, not this Flutter app repo.
- iOS Crashlytics dSYM upload goes through
  `ios/scripts/upload_crashlytics_symbols.sh`, which supports CocoaPods and SPM
  Firebase layouts.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Workflow notes: `memory-bank/progress.md`, `docs/`
- Historical snapshot: `memory-bank/archive/architecture_20260502_pre_compaction.md`
