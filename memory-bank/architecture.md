# Architecture

Compact current-state map for mandatory reads. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/architecture_20260804_pre_compaction.md`.

## Sources Of Truth
- Runtime/tests: `lib/`, `test/`
- DB/RPC/RLS/functions: `supabase/migrations/`, `supabase/functions/`
- Workflows/release state: `docs/`, `.codex/skills/`

## App Shape
- Home owns the signed-in shell, shared room/pet state, status, invites, decor,
  and equipment. Chat owns realtime/history/cache/media; Feed owns capture and
  its durable presigned/base64 upload queue.
- Shop owns catalog, purchases, equipment, and subscriptions. Profile, gallery,
  pet, ads, `services`, and `shared` cover the remaining feature/platform work.

## Structural And Compatibility Contracts
- Large Home/Chat/Shop views use core files plus `part` extensions. Extensions
  call State wrappers instead of protected `setState`, qualify static members,
  and use `part of '../<core>.dart';` from subdirectories. Moving symbols can
  require source-introspection test updates.
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
- Chat paints cached messages first and hydrates cached blocked ids/mention
  candidates before network refresh. Home and room selection share cached
  status snapshots and revalidate through `get_effective_room_pet_statuses`.
- Room fetch failures retry/degrade to stale summaries without replacing a
  successful bootstrap snapshot. Pet-state refreshes follow the same rule: a
  failed refresh keeps the visible pet and reports silently.
- Never probe `pg_timezone_names` in an RPC. It rescans the whole tz database
  (~792 ms/call here); `at time zone` validates the zone for free by raising
  `22023`. Use `public.normalize_timezone(text)` — required in `LANGUAGE sql`
  bodies, which cannot carry an exception handler. Retryable network/auth failures remain
  non-fatal; only genuine fatal errors activate `CrashUpdateGuard`.
- `userFacingError(...)` is the handled-error choke point: it localizes,
  classifies, deduplicates, and reports non-fatals. Bespoke visible copy uses
  `reportUserVisibleError(...)`; silent best-effort work uses
  `reportSwallowedError(...)`.
- OOM/SIGKILL cannot be caught in-process. `UncleanExitService` reports likely
  resumed-state kills on the next launch using a Hive sentinel, memory-warning
  context, and Android exit reasons. Keep Hive initialization before sentinel
  startup. Lifecycle transitions flush the sentinel box, and the report carries
  `last_resumed_at` alongside `session_started_at` so a long-suspended session
  that died on resume is distinguishable from one that grew until it was killed.
- Image-cache trim thresholds are fractions of the *configured* caps
  (`MemoryDiagnosticsService.imageCacheSoftTrimFraction` / `...HardTrimFraction`),
  never absolute bytes: absolute thresholds silently outran the 64 MB cap in
  `main.dart` and disabled trimming entirely. Trim decisions also weigh
  `liveImageCount` against `maximumSize`, because live images are pinned by
  mounted widgets and are not counted against the byte budget.
- Flutter already clears the image cache on an iOS memory warning but never the
  live set; `SystemMemoryPressureService` answers each warning through
  `MemoryDiagnosticsService.releaseUnderMemoryPressure(...)` so pressure frees
  memory instead of only recording telemetry.
- Invite links use `invite_code`; bare `code` can collide with Auth PKCE.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back shared gameplay and chat; active Edge
  Function source lives in `supabase/functions/`.
- Feed/R2 contracts live in `docs/feed_upload_pipeline.md`: preserve response
  field types, keep reward writes on-path, and keep partner push in
  `EdgeRuntime.waitUntil(...)`.
- `notify_friend` keeps `verify_jwt=false` for webhook compatibility; gateway
  JWT functions still validate users internally.
- Room-photo cleanup is human-reviewed/fail-closed. Firebase Hosting/GEOFlow
  lives in `/Users/fatboy/geo-marketing`; iOS dSYM upload support lives under
  `ios/scripts/`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- History: `memory-bank/archive/`
