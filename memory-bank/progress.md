# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260804_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.3.3+16`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`.
- Flutter is pinned to `3.44.0` / Dart `3.12.0`.
- Room invite creation/regeneration uses reusable 24-hour codes.
- Internal hunger-schedule and abandoned-room review tables use RLS as
  defense-in-depth while remaining service-only.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; reviewed Level 2 tracks preserve intentional non-zero
  motion and compatible equipment fits.
- FCM permission/token-sync failures and handled UI errors report non-fatals to
  Crashlytics. `UncleanExitService` detects likely OOM/process kills on the
  next launch.
- No function in `public` probes `pg_timezone_names` any more (a ~792 ms
  system-view scan per call, the source of `57014` statement timeouts).
  `public.normalize_timezone(text)` is the shared UTC fallback.
- A failed `_refreshPetState` no longer replaces pet state the user can already
  see; it reports through `reportSwallowedError` instead.
- `image_picker` refusals are classified by `PlatformException.code`:
  camera/photo access codes map to `mediaPermissionDenied`, `multiple_request`
  is a silent no-op, and picks are serialized and request no full metadata.
- Room-photo cleanup is human-reviewed/fail-closed; GEOFlow/hosting lives in
  `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.

## Open Items
- Monitor ASC/store outcome for iOS `2.3.3+16`; App Review submission requires
  an explicit request.
- Live-verify feed satiety plus presigned-upload logs.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm Crashlytics receives Firebase Apple SPM dSYMs and real
  `unclean_exit` non-fatals; then triage the remaining handled-error
  `unexpected` categories (`image_picker` refusals are now classified).
- Instrument remaining best-effort bare catches opportunistically with
  `reportSwallowedError(...)`.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- History: `memory-bank/archive/`
