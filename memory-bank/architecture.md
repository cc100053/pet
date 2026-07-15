# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260711_pre_compaction.md`.

## Source Of Truth
- App/runtime: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows/runbooks: `docs/`, `.codex/skills/`
- History: `memory-bank/archive/`

## App Shape
- `features/home`: signed-in shell, rooms, shared rendering, pet HUD, decor,
  invites, compatibility prompts, debug controls, and equipment UI.
- `features/chat`: `ChatRoomViewV2` owns bounded history, realtime, Hive cache,
  replies/reactions, edit/delete, media recall, and keyboard behavior.
- `features/feed`: capture plus durable upload queue and presigned/base64
  upload client paths.
- `features/shop`: decor, consumables, room equipment, RevenueCat, purchase
  feedback, and economy state adapters.
- `features/profile`, `gallery`, `pet`, `ads`: avatar/profile, memory photos,
  pet selection/animation, and ATT-aware AdMob.
- `services` and `shared`: Supabase/FCM/IAP/config/crash services, force
  update, What's New, shared widgets, and debug tools.

## View Layer Structure
- Large views are split into core files plus `part` files using
  `extension _Xxx on _<View>State`: `home_view.dart`,
  `chat_room_view_v2.dart`, and `shop_view.dart`.
- Part extensions must call the owning State wrapper instead of protected
  `setState`, qualify static members on the State class, and use
  `part of '../<core>.dart';` from subdirectories.
- Moving symbols between parts can require updating source-introspection tests.
- Shared helpers belong in `lib/shared/utils/` only when behavior is identical.

## Current Decisions
- `ProfileBootstrapService` owns profile bootstrap.
- Shared room content is mixed-version safe: new backgrounds, furniture, and
  pets need version gates, fallback rendering, and the compatibility prompt.
- Multi-pet v2 keeps `pets` one-row-per-room for legacy clients; extra pets
  live in `room_extra_pets`, and `get_room_pets` is the v2+ surface.
- Room hunger/mood/level/exp source of truth is `room_pet_state`; main-pet
  `pet_state` mirrors it for old clients.
- `rooms.name` mirrors the main pet's name; pets still keep individual names.
- Extra pets are first-class in Home: independent wander/drag/tap-name,
  group feeding, main-pet switcher, long-press rename, and per-pet equipment.
- Pet tickets are v2-gated and additive. Pet equipment is room-scoped, per-pet,
  quantity-aware, and uses `head`, `face`, `body`, `back` slots.
- Furniture placement uses fixed virtual-canvas `canvas_position_x/y` while
  dual-writing legacy `position_x/y`; keep legacy 4-arg furniture RPCs separate
  from 6-arg canvas overloads without default args.
- Pet rendering prefers bundled PNG frame sequences while preserving GIF paths
  as stable source/fallback ids. Godot remains the socket/equipment authoring
  path.
- Chat opens on the latest 20 messages, pages by 20, caps visible history at
  80, and caches newest canonical messages in Hive.
- Feed uploads are queue-owned; Home handles global completion/failure effects
  and Chat reconciles optimistic rows locally.
- Feed satiety is authoritative end-to-end: `feed_validate` returns committed
  `pet_state`/`overfed`, and Home applies it through a `last_decay_at`
  freshness guard.
- Room selection and Pet Home share one cached per-room effective-status
  snapshot. `get_effective_room_pet_statuses(...)` revalidates hunger from one
  server clock without mutating state; the prior client projection remains only
  as an older-backend fallback.
- Room entry warms from cached per-room `pet_state`/`pet_id`, revalidates status
  in the background on entry/resume, and persists status changes with a debounce;
  noncritical decor loads after entry. Force update and What's New remain
  separate gates.
- Invite links use `invite_code`; avoid bare `code` because Supabase Auth can
  treat it as a PKCE callback parameter.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back room-scoped gameplay and chat.
- Active Edge Functions: `notify_friend/feed_validate`, `notify_friend`,
  `hunger_tick_dispatch`, `avatar_upload`, `delete_account`,
  `cleanup_abandoned_rooms`, and `feed_upload_url`.
- Feed upload supports base64 plus opt-in presigned direct R2 upload; see
  `docs/feed_upload_pipeline.md` for response and compatibility contracts.
- `notify_friend` remains `verify_jwt=false` for webhook compatibility;
  gateway-JWT functions still validate callers inside the function.
- Shared Edge helpers live in `supabase/functions/_shared/`; R2 cleanup is
  fail-safe for failed writes and human-in-the-loop for abandoned rooms.
- Firebase Hosting / GEOFlow pages live in `/Users/fatboy/geo-marketing`.
- iOS Crashlytics dSYM upload goes through
  `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- Pet PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- Historical snapshots: `memory-bank/archive/`
