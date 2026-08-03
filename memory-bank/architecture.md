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
- Chat room entry paints the Hive message cache first. Blocked ids (they filter
  visible messages) and mention candidates (they highlight mentions in rendered
  bubbles, so they cannot be deferred to the first `@`) hydrate from Hive ahead
  of it; both refresh concurrently with the message fetch.
- Home persists the last resolved background key per room. Painting the real
  background needs `room_background_state` plus the owned-background list, and
  the latter is deferred past first paint; unsupported keys are dropped on
  restore. `_currentBackgroundDefinition` distinguishes "not loaded" from
  "explicitly none" by key presence.
- The room-entry overlay is revealed on a delay and only then held to a
  minimum; a fast cold entry shows the room scaffold with a pet-sized spinner
  instead of blanking the screen.
- The room list must survive a failed fetch: `_fetchRooms` retries with
  backoff, an arriving session and app resume both re-run it, room summaries
  degrade to stale badges instead of aborting the list, and the bootstrap
  snapshot is never written before a fetch has succeeded.
- Room selection/Home share cached status snapshots, revalidate through
  `get_effective_room_pet_statuses(...)`, and debounce persistence.
- Retryable network/auth failures stay non-fatal; only genuine fatal errors
  activate `CrashUpdateGuard`.
- `userFacingError(...)` in `lib/shared/errors/user_facing_error.dart` is the
  single choke point for handled errors: it classifies the error, returns the
  localized message, and reports it to Crashlytics as a non-fatal. Previously it
  only `debugPrint`ed, so every error the user saw was invisible in release.
  - Any new user-visible failure must route through it. If a screen renders its
    own copy, call `reportUserVisibleError(...)`; for best-effort work that
    stays silent in the UI, use `reportSwallowedError(...)` instead of a bare
    `catch (_) {}`.
  - Reports carry a `category` (see `UserFacingErrorCategory`); `unexpected`
    marks errors we failed to classify and is the actionable triage bucket.
  - Identical error/source pairs are throttled to one report per 2 minutes so a
    retry loop cannot flood Crashlytics.
  - Never interpolate a raw `error.toString()` into UI copy; it leaks internals
    and bypasses reporting.
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
