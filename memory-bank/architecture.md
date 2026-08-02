# Architecture

Compact current-state map for mandatory reads. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260728_pre_compaction.md`.

## Sources Of Truth
- Runtime/tests: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows/release state: `docs/`, `.codex/skills/`

## App Shape
- Home owns the signed-in shell, shared-room/pet rendering, status, invites,
  decor, equipment, and compatibility UI.
- Chat owns bounded realtime history, Hive cache, and message/media behaviors;
  Feed owns capture plus its durable presigned/base64 upload queue.
- Shop owns items, equipment, purchases, and subscriptions. Profile, gallery,
  pet, ads, `services`, and `shared` cover the remaining feature/platform work.

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
- Feed uploads are queue-owned. `feed_validate` returns authoritative satiety,
  while Home applies it through a `last_decay_at` freshness guard and Chat
  reconciles optimistic rows locally.
- Chat room entry paints the Hive message cache first; the block list is
  hydrated from disk before it (it filters visible messages) and the
  block/mention refresh runs concurrently with the message fetch.
- Room selection/Home share cached status snapshots, revalidate through
  `get_effective_room_pet_statuses(...)`, and debounce persistence.
- Retryable network/auth failures stay non-fatal; only genuine fatal errors
  activate `CrashUpdateGuard`.
- Invite links use `invite_code`; bare `code` can collide with Auth PKCE.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back room gameplay and chat.
- Active function source lives in `supabase/functions/`.
- Feed upload supports base64 plus opt-in presigned R2 upload. Keep reward
  writes on the response path, partner push in `EdgeRuntime.waitUntil(...)`,
  and legacy response field types stable; see `docs/feed_upload_pipeline.md`.
- `notify_friend` keeps `verify_jwt=false` for webhook compatibility; gateway
  JWT functions still validate users inside the function.
- Room-photo cleanup is human-reviewed and fail-closed; see
  `docs/abandoned_room_cleanup.md`.
- Firebase Hosting/GEOFlow lives in `/Users/fatboy/geo-marketing`; iOS
  Crashlytics dSYMs use `ios/scripts/upload_crashlytics_symbols.sh`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- History: `memory-bank/archive/`
