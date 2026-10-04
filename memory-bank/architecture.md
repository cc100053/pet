# Architecture

Current-state map for architecture and ownership changes. Full snapshots live in
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
- Large Home/Chat/Shop views use core files plus `part` extensions (rules in
  `AGENTS.md`).
- `ProfileBootstrapService` owns profile bootstrap.
- `RoomFrameNotifier` saves explicit confirmations to `room_frame_state`;
  Home refreshes all active rooms on load/resume/realtime reconnect. Hive
  `room_frame_styles` is fallback/cache only, never automatically uploaded.
  Server timestamps reject stale responses; Home/session teardown invalidates
  pending work. Frame sync stays dark below the existing `3.0.0` UI gate.
- Shared backgrounds, furniture, and pets require version-gated visibility,
  old-client render fallback, and the compatibility prompt.
- Multi-pet v2 keeps one canonical `pets` row per room for old clients; extras
  live in `room_extra_pets`, shared stats in `room_pet_state`, and
  `pet_state`/`rooms.name` mirror the main pet.
- Equipment is room-scoped and per-pet across head/face/body/back. Furniture
  positions dual-write (contract in `database-schema.md`).
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
- `userFacingError(...)` localizes, classifies, deduplicates, and reports handled
  failures. Bespoke visible copy uses `reportUserVisibleError(...)`; silent
  best-effort work uses `reportSwallowedError(...)`. Classify on exception type
  or code, never on message keywords: iOS returns OS messages in the device
  locale, so English substring matching mislabels them `unexpected`. `http`'s
  `ClientException` carries the same OS wording for dropped sockets and is
  matched by type for that reason; `http` is a direct dependency only so this
  type is nameable. `userFacingError` trims its own frames off the captured
  trace (`callerStackTrace()`): Crashlytics titles an issue after the first
  app-owned frame, so an untrimmed trace files every call site as one issue.
- Home's 4s `_networkTimeout` budgets reads that fall back to the cached
  snapshot. User-initiated writes pass `timeout: _HomeViewState._writeTimeout`
  (12s, matching Profile): a timed-out write loses the edit with nothing to
  fall back to.
- Crashlytics coverage is iOS-only, matching the shipped platforms: the Android
  app in the Firebase project has never received an event, so its absence from
  reports is expected and not a reporting gap.
- `UncleanExitService` reports likely OOM/SIGKILL on the next launch. On iOS
  pressure, `SystemMemoryPressureService` releases cache and live-image handles.
  Image cache trim thresholds remain fractions of configured caps and include
  live image count.
- Invite links use `invite_code`; bare `code` can collide with Auth PKCE.

## Backend And Platform
- Supabase Auth/Postgres/Realtime back shared gameplay and chat; active Edge
  Function source lives in `supabase/functions/`.
- Feed/R2 contracts (response field types, on-path reward writes, partner
  push in `EdgeRuntime.waitUntil(...)`) live in `docs/feed_upload_pipeline.md`.
- `notify_friend` keeps `verify_jwt=false` for webhook compatibility; gateway
  JWT functions still validate users internally.
- Profile → Send Feedback opens the in-app `SupportView`
  (`lib/features/support/`), which replaces the external support web form.
  The backend contract is `support_messages` in `database-schema.md`;
  the ops runbook is `docs/support_inbox.md`.

## Read More
- Schema/RPC watchlist: `memory-bank/database-schema.md`
- Release/backend ledger: `docs/release_status.md`
- PNG/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- History: `memory-bank/archive/`
