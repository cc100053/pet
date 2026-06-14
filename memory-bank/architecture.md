# Architecture

Active memory files stay compact because agents must read them before
non-trivial work. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260613_pre_compaction.md`.

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
  pet visuals/selection, PNG sequence playback, and ATT-aware AdMob.
- `services` and `shared`: Supabase/FCM/IAP/config/crash services, force
  update, What's New, shared widgets, and debug tools.

## View Layer Structure
- Large views are split into core files plus `part` files using
  `extension _Xxx on _<View>State`: `home_view.dart`,
  `chat_room_view_v2.dart`, and `shop_view.dart`.
- Part extensions must call the owning State wrapper instead of protected
  `setState`, qualify static members on the State class, and use
  `part of '../<core>.dart';` from subdirectories.
- Moving symbols between parts can require updating source-introspection tests
  that read specific files with `readAsStringSync()`.
- Shared helpers live in `lib/shared/utils/` only when behavior is actually
  identical. Similar-but-different helpers stay local.

## Current Decisions
- `ProfileBootstrapService` owns profile bootstrap.
- Shared room content is mixed-version safe: new backgrounds, furniture, and
  pets need version gates, fallback rendering, and the compatibility prompt.
- Multi-pet compatibility keeps `pets` one-row-per-room for legacy clients;
  extra pets live in `room_extra_pets`, and `get_room_pets` is the v2+ surface.
- Room hunger/mood/level/exp source of truth is `room_pet_state`; main-pet
  `pet_state` mirrors it for old clients.
- `rooms.name` mirrors the main pet's name. Pets still keep individual names.
- Extra pets are first-class in Home: independent wander/drag/tap-name,
  group feeding, main-pet switcher, long-press rename, and per-pet equipment.
- Pet tickets are v2-gated and additive: `purchase_and_use_pet_ticket` for new
  purchases, `use_pet_ticket` for owned tickets.
- Pet equipment is room-scoped, per-pet, and quantity-aware; one owned copy can
  only be equipped on one pet at a time. Slots are `head`, `face`, `body`,
  and `back`; `face` currently uses the head anchor.
- Furniture placement uses fixed virtual-canvas `canvas_position_x/y` while
  dual-writing legacy `position_x/y`; keep legacy 4-arg furniture RPCs separate
  from 6-arg canvas overloads without default args.
- Pet rendering prefers bundled PNG frame sequences while preserving GIF paths
  as stable source/fallback ids. Godot remains the socket/equipment authoring
  path.
- Chat opens on the latest 20 messages, pages by 20, caps visible history at
  80, and caches newest canonical messages in Hive.
- Feed uploads are queue-owned. Home owns global completion/failure effects and
  refreshes the original room; Chat reconciles optimistic rows locally.
- Force update and What's New remain separate gates.
- Invite links use `invite_code`; avoid bare `code` because Supabase Auth can
  treat it as a PKCE callback parameter.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back room-scoped gameplay and chat.
- Active Edge Functions: `notify_friend/feed_validate`, `notify_friend`,
  `hunger_tick_dispatch`, `avatar_upload`, `delete_account`,
  `cleanup_abandoned_rooms`, and `feed_upload_url`.
- Feed upload supports base64-through-`feed_validate` plus presigned direct R2
  upload through `feed_upload_url`, controlled by
  `app_config.feed_presigned_upload_enabled` with base64 fallback.
- `feed_validate` accepts presigned `image_url` only under the room's R2 prefix.
- `notify_friend` remains `verify_jwt=false` for webhook compatibility and uses
  function-level auth; `verify_jwt=true` functions expect Supabase Auth JWTs at
  the gateway.
- Shared Edge helpers: `_shared/http.ts`, `_shared/images.ts`,
  `_shared/auth.ts`. `notify_friend/l10n.ts` and `notify_friend/pets.ts` hold
  push copy and pet/avatar mapping; FCM auth/send stays in `index.ts`.
- R2 cleanup is fail-safe: `feed_validate` deletes uploaded objects on
  `process_feed_event` rollback, and `avatar_upload` deletes replaced/failed
  avatar objects.
- Firebase Hosting / GEOFlow pages live in `/Users/fatboy/geo-marketing`, not
  this Flutter app repo.
- iOS Crashlytics dSYM upload goes through
  `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- Pet PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- Historical snapshots: `memory-bank/archive/`
