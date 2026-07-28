# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260724_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.3.0+13`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`.
- Multi-pet v2 remains backward-compatible through canonical `pets`,
  `room_extra_pets`, shared `room_pet_state`, and legacy mirrors.
- Shared room content needs version gates, old-client fallback, and the
  compatibility prompt; use the shared-item rollout skill.
- Feed upload has a durable queue, opt-in presigned R2 path, base64 fallback,
  and authoritative satiety reconciliation. Rewards stay on the response path;
  partner push stays in `EdgeRuntime.waitUntil(...)`.
- Room selection/Home share cached status snapshots. The additive
  `get_effective_room_pet_statuses(...)` RPC revalidates from one server clock;
  clients persist refreshed state with a debounce.
- Large Home/Chat/Shop views use `part` extensions. Chat has bounded history,
  Hive cache, local-first realtime buffering, and image-feed recall.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  available from `2.3.0`; all `2.2.x` clients keep it hidden and fall back to
  the default pet for unsupported remote state. Its reviewed Level 2
  sockets—including sub-threshold idle motion—and crown/straw-hat/ribbon fits
  are synced. Sunglasses are incompatible with Chicken and blocked in
  inventory, equip, and render paths.
- The external Godot socket-authoring dock rehydrates the active equipment
  controls/preview after socket, editor, or plugin reloads while preserving
  default → per-pet → per-animation override precedence.
- FCM permission failures are contained inside `FCMService`; unsupported Apple
  environments skip notification initialization without changing successful
  registration behavior.
- Retryable network/auth failures reported through `FlutterError` are recorded
  as non-fatal and cannot replace the app with the crash recovery screen.
- Room-photo cleanup is human-reviewed/fail-closed. GEOFlow/hosting assets live
  in `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.

## Open Items
- Run ASC submission preflight for iOS `2.3.0+13`, then submit ASC version
  `5a4313f5-29c6-4fc6-9ecf-0a5f9806670c` with attached build
  `cab2d2f1-e325-4c66-bab5-ea974a6f5ab6` if approved.
- Live-verify feed satiety plus presigned-upload logs on the current build.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm Crashlytics receives Firebase Apple SPM dSYMs.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- History: `memory-bank/archive/`
