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
- Multi-pet v2.0.0 keeps `pets` strictly one-row-per-room (unique constraint
  intact) so legacy clients' `.maybeSingle()` never breaks; extra pets live in
  `room_extra_pets` and are only visible through the v2.0.0 `get_room_pets`
  RPC. `rooms.main_pet_id` points at the canonical main pet in `pets`;
  `set_room_main_pet` swaps rows between the two tables to promote/demote.
- Hunger/mood/level/exp are room-shared in `room_pet_state`. The main pet's
  `pet_state` mirrors it (both directions kept in sync: actions and passive
  `tick_pet_state` decay both write `room_pet_state`); `pets`/`room_extra_pets`
  `level`/`exp` mirror the room via triggers, and new pets inherit the room's
  current level on insert.
- Naming model B: `rooms.name` mirrors the main pet's name (trigger on main-pet
  rename + name copy in `set_room_main_pet`). Each pet still has its own name
  for identity; there is no separate room-rename flow.
- Extra pets are first-class on screen: each has its own AnimatedPositioned
  wander (shared timer; pets may overlap freely, no repulsion), drag,
  tap-to-show name
  tag, full avatar size, and the same walk/sleep/stay animation state machine
  as the main pet. Feeding summons all pets to the food. The top-left avatar
  opens a main-pet switcher; equip prompts a per-pet target picker.
- New room pets are added through a v2.0.0-gated pet ticket flow. New ticket
  purchases use `purchase_and_use_pet_ticket` so the 150-diamond charge and pet
  insert commit together; already-owned tickets use `use_pet_ticket`. Both
  insert into `room_extra_pets` when a main already exists. Same pet types are
  intentionally allowed.
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
