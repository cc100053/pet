# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260811_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.3.4+18`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`. Build 18 is
  `VALID`, attached, and intentionally not submitted for App Review.
- Flutter is pinned to `3.44.0` / Dart `3.12.0`.
- Room invite creation/regeneration uses reusable 24-hour codes.
- Internal hunger-schedule and abandoned-room review tables use RLS as
  defense-in-depth while remaining service-only.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; reviewed Level 2 tracks preserve intentional movement.
- Handled UI/media errors report classified non-fatals. `UncleanExitService`
  detects likely OOM/process kills on the next launch.
- The foreground OOM root cause was undisposed `ImageInfo` listener clones.
  All known aspect-ratio listeners now dispose them; iOS memory warnings also
  release cache/live images and trim thresholds track configured caps.
- iOS release exports preserve the archive and upload every archive dSYM to
  Crashlytics; the archive path is authoritative for symbolication.
- No public function scans `pg_timezone_names`; timezone-aware RPCs use
  `public.normalize_timezone(text)`.
- Failed pet-state refreshes keep the last successful visible snapshot.
- Room-photo cleanup remains human-reviewed/fail-closed; GEOFlow/hosting lives
  in `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.

## Open Items
- Monitor ASC/store outcome for iOS `2.3.4+18`; App Review submission requires
  an explicit request.
- Live-verify feed satiety, visible hunger movement, and presigned-upload logs.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm organic post-deploy timing for the timezone-normalized pet RPCs.
- Add a leak regression test for the high-volume
  `CachedNetworkImageView` path if its cache-manager harness can be stabilized.
- Instrument remaining best-effort bare catches opportunistically with
  `reportSwallowedError(...)`.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- History: `memory-bank/archive/`
