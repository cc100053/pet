# Architecture

Compact current-state map for mandatory reads. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260811_pre_compaction.md`.

## Sources Of Truth
- Runtime/tests: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows/release state: `docs/`, `.codex/skills/`

## App Shape
- Home owns the signed-in shell, shared room/pet state, status, invites, decor,
  and equipment. Chat owns realtime/history/cache/media; Feed owns capture and
  its durable presigned/base64 upload queue.
- Shop owns catalog, purchases, equipment, and subscriptions. Profile, gallery,
  pet, ads, `services`, and `shared` cover remaining feature/platform work.

## Structural And Compatibility Contracts
- Large Home/Chat/Shop views use core files plus `part` extensions. Extensions
  call State wrappers instead of protected `setState`, qualify static members,
  and use `part of '../<core>.dart';` from subdirectories. Moving symbols can
  require source-introspection test updates. Those tests match on source text,
  so reformatting can break them too; `lib/` and `test/` are formatter-canonical
  and CI gates `dart format` before analyze and test to keep it that way.
- `ProfileBootstrapService` owns profile bootstrap.
- Shared backgrounds, furniture, and pets require version-gated visibility,
  old-client render fallback, and the compatibility prompt.
- Multi-pet v2 keeps one canonical `pets` row per room for old clients; extras
  live in `room_extra_pets`, shared stats in `room_pet_state`, and
  `pet_state`/`rooms.name` mirror the main pet.
- Equipment is room-scoped and per-pet across head/face/body/back. Furniture
  dual-writes fixed-canvas and legacy positions; retain separate 4-arg and
  non-defaulted 6-arg RPCs.
- Pet rendering prefers PNG sequences while preserving GIF paths as stable
  source/fallback ids; Godot is the socket/equipment authoring source.
- Feed uploads are queue-owned. `feed_validate` returns authoritative satiety;
  Home applies it through `last_decay_at` freshness and Chat reconciles
  optimistic rows locally.
- Chat/Home paint cached state first and revalidate. Failed room or pet-state
  refreshes keep the last successful visible snapshot and report silently.
- Never scan `pg_timezone_names` in an RPC; validate through
  `public.normalize_timezone(text)` or `at time zone` with `22023` fallback.
- `userFacingError(...)` localizes, classifies, deduplicates, and reports handled
  failures. Bespoke visible copy uses `reportUserVisibleError(...)`; silent
  best-effort work uses `reportSwallowedError(...)`.
- `UncleanExitService` reports likely OOM/SIGKILL on the next launch; keep Hive
  initialization before its sentinel. On iOS pressure,
  `SystemMemoryPressureService` releases cache and live-image handles.
- Every `ImageStreamListener` callback owns its `ImageInfo` clone and must
  dispose it after reading. Aspect-ratio probes use the already-sized provider;
  cache trim thresholds remain fractions of configured caps and include live
  image count.
- Invite links use `invite_code`; bare `code` can collide with Auth PKCE.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back shared gameplay and chat; active Edge
  Function source lives in `supabase/functions/`.
- Feed/R2 contracts live in `docs/feed_upload_pipeline.md`: preserve response
  field types, keep reward writes on-path, and partner push in
  `EdgeRuntime.waitUntil(...)`.
- `notify_friend` keeps `verify_jwt=false` for webhook compatibility; gateway
  JWT functions still validate users internally.
- Room-photo cleanup is human-reviewed/fail-closed. Firebase Hosting/GEOFlow
  lives in `/Users/fatboy/geo-marketing`.
- For iOS releases, the export helper preserves the `.xcarchive` and uploads all
  archive dSYMs to Crashlytics; see `docs/ios_app_store_export.md`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- History: `memory-bank/archive/`
