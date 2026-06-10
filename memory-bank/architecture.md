# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260606_pre_compaction.md`.

## Source Of Truth
- App/runtime: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows: `docs/`, `.codex/skills/`
- History: `memory-bank/archive/`

## App Shape
- `lib/features/home/`: signed-in shell, rooms, shared rendering, pet HUD,
  decor, invites, compatibility prompts, debug controls, and equipment UI.
- `lib/features/chat/`: `ChatRoomViewV2` owns bounded history, realtime, Hive
  cache, replies/reactions, edit/delete, and keyboard behavior.
- `lib/features/feed/`: capture and durable upload queue.
- `lib/features/shop/`: decor, consumables, room equipment, RevenueCat, and
  purchase feedback.
- `lib/features/profile/`, `gallery/`, `pet`, `ads`: avatar/profile, memory
  photos, pet visuals/selection, and ATT-aware AdMob.
- `lib/services/`, `lib/shared/`: Supabase/FCM/IAP/config/crash services,
  force update, What's New, shared widgets, and debug tools.

## View Layer Structure
- Large stateful views are split into `part` files using
  `extension _Xxx on _<View>State` domains:
  - `home_view.dart` core plus room-decor, equipment, pet-tick, debug, build,
    controller/flow/scene/drawer parts.
  - `chat_room_view_v2.dart` core plus scroll, actions, build, overlay,
    composer, message, chrome, and data-helper parts.
  - `shop_view.dart` core plus decoration widgets and purchase service parts.
- Part-extension conventions are analyzer-enforced:
  - Do not call protected `State.setState` from extensions; route through the
    owning State wrapper (`_setStateForRoomDecor`, `_setStateForEquipment`,
    `_setStateForDebug`, `_setStateChat`, etc.).
  - Qualify `static` members on the extended State class.
  - Subdirectory parts use `part of '../<core>.dart';`.
- Cross-file byte-identical helpers are centralized in `lib/shared/utils/`:
  `removeRealtimeChannelSafely`, `parseOptionalDate` / `parseDate`,
  `globalRectForKey`. Same-named-but-divergent helpers are intentionally NOT
  merged (e.g. `_withNetworkTimeout`, shop's `_removeRealtimeChannel`).
- A few tests are source-introspection tests (`readAsStringSync()` + symbol
  greps); moving code between parts can require updating which file they read.

## Current Decisions
- Profile bootstrap is centralized in `ProfileBootstrapService`.
- Shared room content is mixed-version safe: new backgrounds, furniture, and
  pets need version gates, fallback rendering, and the compatibility prompt.
- Multi-pet v2.0.0 keeps `pets` strictly one-row-per-room (unique constraint
  intact) so legacy clients' `.maybeSingle()` never breaks; extra pets live in
  `room_extra_pets` and are only visible through the v2.0.0 `get_room_pets`
  RPC. `rooms.main_pet_id` points at the canonical main pet in `pets`;
  `set_room_main_pet` swaps rows between the two tables to promote/demote.
- Hunger/mood/level/exp are room-shared in `room_pet_state`; main-pet
  `pet_state` mirrors it for old clients. Actions and passive decay keep both
  tables in sync, and pets inherit room level/exp through triggers.
- Naming model B: `rooms.name` mirrors the main pet's name (trigger on main-pet
  rename + name copy in `set_room_main_pet`). Each pet still has its own name
  for identity; there is no separate room-rename flow.
- Extra pets are first-class on screen: independent wander/drag/tap-name,
  full-size animation, no collision repulsion, group feeding, main-pet switcher,
  long-press rename, and per-pet equipment rendering through room-wide
  `_equippedSkusByPetId`. The equipment panel shows a persistent pet selector
  when 2+ pets.
- New room pets are added through a v2.0.0-gated pet ticket flow. New purchases
  use `purchase_and_use_pet_ticket`; owned tickets use `use_pet_ticket`. Same
  pet types are intentionally allowed.
- Pet equipment is room-scoped end to end: purchase, inventory, equip state, and
  preview rendering key off `room_id`.
- Equipment ownership is a shared closet with quantity; one owned copy can only
  be equipped on one pet at a time.
- Furniture placement uses fixed virtual-canvas coordinates:
  `canvas_position_x/y` are nullable and dual-written by new clients while
  legacy `position_x/y` remains for old clients. Keep legacy 4-arg furniture
  RPCs separate from 6-arg canvas overloads; canvas overloads must not have
  default args or old PostgREST calls become ambiguous.
- Equipment slots are logical groups, not always distinct socket anchors:
  `head` hats, `face` sunglasses via the head anchor, `body` ribbons, `back`.
- Pet rendering prefers bundled PNG frame sequences while keeping GIF paths as
  stable source/fallback ids. Socket placement is authored in Godot and
  translated into `PetSocketCatalog` / `EquipmentCatalog`.
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
  `hunger_tick_dispatch`, `avatar_upload`, `delete_account`,
  `cleanup_abandoned_rooms`.
- `notify_friend` remains `verify_jwt=false` for webhook compatibility and does
  function-level auth checks; `verify_jwt=true` functions expect HS256 Supabase
  Auth JWTs at the gateway. Webhook/scheduler shared-secret checks use
  constant-time compare (`_shared/auth.ts` `timingSafeEqual`).
- Edge Functions share `supabase/functions/_shared/{http,images,auth}.ts`
  (CORS/JSON, base64+R2 helpers, secret compare). `notify_friend` is further
  split into `notify_friend/l10n.ts` (push locale templates + store-item names)
  and `notify_friend/pets.ts` (avatar maps + type resolution); orchestration and
  the FCM auth/send path stay in `index.ts`. Push l10n is intentionally separate
  from in-app `lib/l10n`. `pets.ts` documents that `tiger` falls back to the
  ghost avatar GIF because `tiger_stay.gif` is not published on R2. R2 writes are leak-safe:
  `feed_validate` deletes its uploaded object if `process_feed_event` rolls
  back, and `avatar_upload` deletes the previous avatar on replace (and the new
  object if the profile update fails).
- Firebase Hosting static pages and GEOFlow work live in
  `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- iOS Crashlytics dSYM upload goes through
  `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Workflow notes: `memory-bank/progress.md`, `docs/`
- Historical snapshots: `memory-bank/archive/`
