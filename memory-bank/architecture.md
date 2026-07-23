# Architecture

Compact current-state map for mandatory reads. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260724_pre_compaction.md`.

## Sources Of Truth
- Runtime/tests: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows/release state: `docs/`, `.codex/skills/`

## App Shape
- Home owns the signed-in shell, room/shared-pet rendering, status HUD, decor,
  compatibility prompts, invites, and equipment UI.
- Chat owns bounded realtime history, Hive cache, replies/reactions, media
  recall, and deterministic keyboard/scroll behavior.
- Feed owns capture plus the durable upload queue and presigned/base64 clients.
- Shop owns decor, consumables, equipment, RevenueCat, and economy feedback.
- Profile/gallery/pet/ads cover identity, memories, pet animation/selection,
  and ATT-aware AdMob; `services` and `shared` hold cross-feature infrastructure.

## Structural Contracts
- Large Home/Chat/Shop views use core files plus `part` extensions. Extensions
  call State wrappers instead of protected `setState`, qualify static members,
  and use `part of '../<core>.dart';` from subdirectories.
- Moving symbols between parts may require source-introspection test updates.
- `ProfileBootstrapService` owns profile bootstrap.
- Shared backgrounds, furniture, and pets need version-gated visibility,
  old-client render fallback, and the compatibility prompt.
- Multi-pet v2 preserves one canonical `pets` row per room; extras live in
  `room_extra_pets`, shared stats in `room_pet_state`, and the main-pet
  `pet_state`/`rooms.name` mirrors remain for legacy clients.
- Pet equipment is room-scoped and per-pet across `head`, `face`, `body`,
  `back`; pet tickets are additive and v2-gated.
- Furniture dual-writes fixed-canvas `canvas_position_x/y` and legacy
  `position_x/y`; keep legacy 4-arg RPCs separate from 6-arg overloads.
- Pet rendering prefers bundled PNG sequences but preserves GIF paths as
  stable source/fallback ids; Godot remains the socket/equipment authoring path.
- Chat opens/pages by 20, caps visible history at 80, and caches canonical
  messages in Hive.
- Feed uploads are queue-owned. `feed_validate` returns authoritative satiety,
  while Home applies it through a `last_decay_at` freshness guard and Chat
  reconciles optimistic rows locally.
- Room selection and Home share cached per-room status snapshots.
  `get_effective_room_pet_statuses(...)` revalidates from one server clock
  without mutating state; the old client projection is fallback-only.
- Room entry warms from cache, revalidates status on entry/resume, and persists
  status changes with a debounce. Force update and What's New stay separate.
- Invite links use `invite_code`; bare `code` can collide with Auth PKCE.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back room gameplay and chat.
- Active Edge Functions: `notify_friend/feed_validate`, `notify_friend`,
  `hunger_tick_dispatch`, `avatar_upload`, `delete_account`,
  `cleanup_abandoned_rooms`, and `feed_upload_url`.
- Feed upload supports base64 plus opt-in presigned R2 upload. Keep reward
  writes on the response path, partner push in `EdgeRuntime.waitUntil(...)`,
  and legacy response field types stable.
- `notify_friend` keeps `verify_jwt=false` for webhook compatibility; gateway
  JWT functions still validate users inside the function.
- Shared Edge helpers live in `supabase/functions/_shared/`; room-photo cleanup
  is human-reviewed and fail-closed.
- Firebase Hosting/GEOFlow lives in `/Users/fatboy/geo-marketing`; iOS
  Crashlytics dSYMs use `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- History: `memory-bank/archive/`
