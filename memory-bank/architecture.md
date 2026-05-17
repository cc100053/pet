# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260516_pre_compaction.md`.

## Source Of Truth
- App/runtime: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows: `docs/`, `.codex/skills/`
- History: `memory-bank/archive/`

## App Shape
- `lib/features/home/`: signed-in shell, rooms, shared rendering, pet HUD,
  decor, invites, compatibility prompts, and equipment UI.
- `lib/features/chat/`: `ChatRoomViewV2` owns bounded history, realtime, Hive
  cache, replies/reactions, edit/delete, and keyboard behavior.
- `lib/features/feed/`: capture and durable upload queue.
- `lib/features/shop/`: decor, consumables, room equipment, RevenueCat, and
  purchase feedback.
- `lib/features/profile/`, `gallery/`, `pet`, `ads`: avatar/profile, memory
  photos, pet visuals/selection, and ATT-aware AdMob.
- `lib/services/`, `lib/shared/`: Supabase/FCM/IAP/config/crash services,
  force update, What's New, shared widgets, and debug tools.

## Current Decisions
- Profile bootstrap is centralized in `ProfileBootstrapService`.
- Shared room content is mixed-version safe: new backgrounds, furniture, and
  pets need version gates, fallback rendering, and the compatibility prompt.
- Multi-pet v2.0.0 foundation is additive: rooms can have multiple `pets`,
  `rooms.main_pet_id` drives one-pet summaries, and `room_pet_state` stores
  shared room hunger/mood while old `pet_state` remains for compatibility.
- New room pets are added through a v2.0.0-gated pet ticket flow. New ticket
  purchases use `purchase_and_use_pet_ticket` so the 150-diamond charge and pet
  insert commit together; already-owned tickets use `use_pet_ticket`. Same pet
  types are intentionally allowed.
- Pet equipment is room-scoped end to end: purchase, inventory, equip state, and
  preview rendering key off `room_id`.
- Equipment ownership is a shared closet with quantity; one owned copy can only
  be equipped on one pet at a time.
- Equipment slots are logical equip groups, not always distinct socket anchors:
  `head` hats are mutually exclusive with other hats, `face` sunglasses can
  coexist with hats while resolving through the head socket anchor, and `body`
  ribbons can coexist with both.
- Pet rendering prefers bundled PNG frame sequences while keeping GIF paths as
  stable source/fallback ids.
- Socket placement is authored in Godot, then translated into
  `PetSocketCatalog` and `EquipmentCatalog`; the Flutter fit tool is debug-only.
- Shop economy RPC calls and parsing are behind `EconomyPurchaseAdapter`; UI
  state deltas land in `ShopEconomyState`.
- Chat opens on latest 20, pages by 20, caps visible history at 80, and caches
  newest canonical messages in Hive.
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
