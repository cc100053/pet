# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260811_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.4.0+19`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`. Build 19 is
  `VALID`, attached, and intentionally not submitted for App Review. Adds four
  new furniture pieces (Balloons/Cactus/Rug/Vinyl Records) to the shop,
  version-gated to `2.4.0` and active.
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
- 房間選擇 room cards are equippable frame casings (`RoomFrameStyle` ×5) picked
  in the 換相框 sheet via long-press. `original` is the pre-redesign card and the
  default, so untouched rooms look unchanged. Casings unlock by room level
  (`RoomFrameSkin.unlockLevel`, all `1` today). Equipped casing persists per
  device in Hive.

## Open Items
- Room frames: the unlock ladder is still flat (every casing at level 1), and
  the equipped casing is per device. Sharing one across a room's members needs a
  server-backed state table following the `room_backgrounds` precedent, which
  requires approval.
- Monitor ASC/store outcome for iOS `2.4.0+19`; App Review submission requires
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
