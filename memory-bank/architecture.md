# Architecture

Compact current-state map for mandatory reads. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260818_pre_compaction.md`.

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
  require source-introspection test updates. Those tests can be formatting
  sensitive; format only touched files and follow the final check order in
  `AGENTS.md` / `docs/testing.md`.
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
- The chat timeline keeps a deliberately small 600px off-screen build cache, so
  a bubble outside the viewport has no registered surface context. Anything
  that scrolls to a message by `BuildContext` (reply-jump) must first drive
  `ListObserverController` to the item's index via
  `chatListRawIndexForMessageId`, which accounts for interleaved date
  separators; waiting for frames alone can never build an off-screen item.
  A target that is already built is at most a cache away and the whole move is
  animated. An unbuilt one needs that search, which must not be shown: the
  timeline is wrapped in a `SnapshotWidget` that freezes it on the pre-jump
  frame while the observer pages toward the target. It thaws three quarters of
  a screen short of the target with the highlight already applied, and only
  that last stretch animates, so the jump arrives as a scroll without dragging
  the whole history past the user. A faint scrim covers the freeze, armed only
  after 120ms so a fast search never flashes a loading state. A jump that fails
  or times out rewinds to its starting offset before thawing. The glide
  direction comes from where the user was, not from the post-search offset.
- Chat/Home paint cached state first and revalidate. Failed room, pet-state, or
  room-decor refreshes keep the last successful visible snapshot and report
  silently; they surface an error only when nothing is on screen to fall back
  to, and a good load clears any banner a previous failure left.
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
