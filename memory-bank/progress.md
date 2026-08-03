# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260728_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.3.1+14`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`.
- Current compatibility/architecture contracts live in
  `memory-bank/architecture.md` and `memory-bank/database-schema.md`.
- Live room invite creation/regeneration now uses a 24-hour expiry across
  current and legacy app RPCs; codes remain reusable without a join-count cap.
- Internal hunger-schedule and abandoned-room review tables now use RLS as
  defense in depth while remaining service-only.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; `2.2.x` clients hide/fallback unsupported state.
- Chicken's reviewed Level 2 sockets and compatible equipment fits are synced;
  sunglasses are blocked for Chicken. Godot reload preserves
  default → per-pet → per-animation precedence.
- FCM permission failures are contained in `FCMService`; retryable network/auth
  failures remain non-fatal. FCM permission/token-sync failures now report to
  Crashlytics instead of only `debugPrint`ing.
- Handled errors are now reported: `userFacingError(...)` records a classified
  non-fatal for every user-visible error message (see `memory-bank/architecture.md`).
- Room-photo cleanup is human-reviewed/fail-closed; GEOFlow/hosting lives in
  `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.

## Open Items
- Monitor ASC/store outcome for iOS `2.3.1+14`; App Review submission remains
  pending an explicit request.
- Live-verify feed satiety plus presigned-upload logs on the current build.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm Crashlytics receives Firebase Apple SPM dSYMs.
- After the next release, triage Crashlytics non-fatals by `category`; the
  `unexpected` bucket is the backlog of errors we still cannot classify.
- ~185 best-effort `catch (_) {}` sites remain uninstrumented; convert to
  `reportSwallowedError(...)` opportunistically when touching that code.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- History: `memory-bank/archive/`
