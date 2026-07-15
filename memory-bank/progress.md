# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260711_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.2.5+11` after the completed
  `release-notes-sync` flow. ASC state, build IDs, localization IDs, and
  backend deployment history live in `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`; use bare
  `flutter ...` after confirming the default SDK matches the pin.
- Multi-pet v2 remains backward-compatible: `pets` is one-row-per-room for
  legacy clients; extras live in `room_extra_pets`; shared stats live in
  `room_pet_state`; `rooms.name` mirrors the main pet.
- Shared backgrounds/furniture/pets need version gates, old-client fallback,
  and the compatibility prompt; use the shared-item rollout skill.
- Feed upload has a durable queue, opt-in presigned direct-to-R2 support,
  base64 fallback, and authoritative satiety reconciliation from `feed_validate`.
- Feed rewards stay on the response path; partner push stays in
  `EdgeRuntime.waitUntil`; old response field types remain stable.
- Room selection and Pet Home now share cached effective pet-status snapshots;
  the additive live `get_effective_room_pet_statuses(...)` RPC performs fast
  status-only revalidation using the server clock and room timezone.
- Abandoned-room photo cleanup is human-in-the-loop and fail-closed.
- Large Home/Chat/Shop files use `part` extensions; Chat uses bounded visible
  history, Hive cache, local-first realtime buffering, and image-feed recall.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids;
  Godot remains the socket/equipment authoring path.
- Chicken assets remain bundled but are version-gated beyond the bug-fix-only
  `2.2.5` release; `2.2.5` selection/rendering treats chicken as unsupported
  and falls back to the default pet. The provisional Godot-exported Flutter
  motion tracks still require representative equipment-fit review before a
  later rollout.
- GEOFlow, SEO/Firebase Hosting pages, invite fallbacks, and app/universal-link
  files live in `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- ASC subscription metadata must retain the direct Apple Standard EULA footer;
  `test/app_store_metadata_terms_test.dart` locks this.
- FCM notification permission failures are contained inside `FCMService`; an
  unsupported Apple environment skips notification initialization instead of
  escaping into the fatal Crashlytics zone. Successful registration behavior
  and notification contracts are unchanged.

## Workflow Notes
- Follow `AGENTS.md` for compatibility, skills, asset checks, Firebase, ASC,
  and Edge Function deployment workflows.
- `docs/release_status.md` remains the release/build/backend source of truth.

## Open Items
- Run ASC submission preflight for iOS `2.2.5+11`, then submit for review if
  approved.
- Live-verify a real feed on the current build: confirm `feed_validate` returns
  `pet_state`, the satiety bar moves on slow upload, and presigned upload logs
  stay clean.
- Confirm Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- Smoke-test iOS banner and rewarded ads after the `google_mobile_ads` 8.0.0
  upgrade.

## Read More
- Release/backend details: `docs/release_status.md`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- Historical snapshots: `memory-bank/archive/`
