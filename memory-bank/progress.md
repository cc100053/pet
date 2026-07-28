# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260728_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.3.0+13`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`.
- Current compatibility/architecture contracts live in
  `memory-bank/architecture.md` and `memory-bank/database-schema.md`.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; `2.2.x` clients hide/fallback unsupported state.
- Chicken's reviewed Level 2 sockets and compatible equipment fits are synced;
  sunglasses are blocked for Chicken. Godot reload preserves
  default → per-pet → per-animation precedence.
- FCM permission failures are contained in `FCMService`; retryable network/auth
  failures remain non-fatal.
- Room-photo cleanup is human-reviewed/fail-closed; GEOFlow/hosting lives in
  `/Users/fatboy/geo-marketing`.
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
