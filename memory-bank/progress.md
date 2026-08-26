# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260818_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `3.0.1+21` (bug-fix release for the room-decor
  error-banner fix, `840773d`). Build 21 is `VALID`, attached, and
  intentionally not submitted for App Review. Exact ASC, dSYM, localization,
  and backend deployment state lives in `docs/release_status.md`.
- Flutter is pinned to `3.44.0` / Dart `3.12.0`. There is no CI gate; follow
  the local final-check order in `AGENTS.md` and `docs/testing.md`.
- Chat reply-jump scrolls to the target's list index before centering it, so
  tapping a reply preview works even when the target bubble (typically a photo,
  or history just loaded by the jump itself) was never built. A jump that still
  cannot land now reports instead of failing silently.
- Room invite creation/regeneration uses reusable 24-hour codes.
- Internal hunger-schedule and abandoned-room review tables use RLS as
  defense-in-depth while remaining service-only.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; reviewed Level 2 tracks preserve intentional movement.
- Handled UI/media errors report classified non-fatals. `UncleanExitService`
  detects likely OOM/process kills on next launch; known image listeners dispose
  their `ImageInfo` clones and iOS pressure releases cache/live images.
- Every iOS release path must run
  `ios/scripts/upload_archive_dsyms.sh build/ios/archive/Runner.xcarchive`
  immediately after the IPA build. It uploads all dSYMs and preserves the
  archive; see `docs/ios_app_store_export.md`.
- Timezone-aware RPCs use `public.normalize_timezone(text)`; no public
  function scans `pg_timezone_names`.
- Failed pet-state and room-background refreshes keep the last successful
  visible snapshot; both decor loaders are re-run by realtime callbacks, so
  they report through `reportSwallowedError` unless the room has no loaded
  decor to show.
- Room-photo cleanup remains human-reviewed/fail-closed; GEOFlow/hosting lives
  in `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.
- Room-frame casings ship in `3.0.0` and are dark below that version. The
  pre-redesign `original` casing remains the default, and the equipped style
  is currently per-device Hive state.
- Frame unlocks are room-level based: `original` and `polaroidClassic` Lv1,
  `corkboard` Lv3, `goldLeaf` Lv5, `nightGlow` Lv8. Equipped casings are
  grandfathered; unknown room level reads as Lv1. Source and calibration
  queries live in `RoomFrameSkins`.
- Pet names cap at 12 through shared client/server validation; first-time naming
  uses `set_initial_pet_name`.

## Open Items
- Decide whether any room-frame casing belongs in Shop. This needs a product
  decision, a price from `docs/shop_pricing.md`, and a migration.
- Sharing an equipped casing across room members needs server-backed state and
  old-client compatibility approval.
- Submit iOS `3.0.0+20` for App Review only after an explicit request, and
  confirm build 20's UUIDs are absent from Crashlytics Missing dSYMs
  `[USER ACTION REQUIRED]`.
- The room-decor transient-failure fix is on `main` but unreleased; it is
  client-only, so it needs a build. Crashlytics issue
  `0183b64515477452f62329d7d3a83a4f` stays OPEN until that ships.
- Convert remaining source-text app tests to behavioral tests where practical;
  SQL migration text tests remain legitimate.
- Live-verify feed satiety, visible hunger movement, and presigned-upload logs.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm organic post-deploy timing for timezone-normalized pet RPCs.
- Add a leak regression test for `CachedNetworkImageView` if its cache-manager
  harness can be stabilized.
- Instrument remaining best-effort bare catches with
  `reportSwallowedError(...)` opportunistically.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- Room-frame design rules: `memory-bank/ui-ux-guidelines.md`
- History: `memory-bank/archive/`
