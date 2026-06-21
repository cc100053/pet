# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260621_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.2.2+8` after the completed
  `release-notes-sync` flow. ASC version
  `1761de51-ec73-46e4-8b6f-134d9c650e1d` is `PREPARE_FOR_SUBMISSION`; build
  `702c2f8d-770f-40ec-a013-19cab3c1d098` is `VALID`, encryption `exempt`, and
  attached. Exact localization IDs and backend history live in
  `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`; use bare
  `flutter ...` after confirming the default SDK matches the pin.
- Multi-pet v2 remains backward-compatible: `pets` is one-row-per-room for
  legacy clients; extras live in `room_extra_pets`; shared stats live in
  `room_pet_state`; `rooms.name` mirrors the main pet.
- Shared backgrounds, furniture, and pets need version-gated visibility,
  old-client fallback, and the compatibility prompt. Use
  `.codex/skills/shared-item-rollout/SKILL.md`.
- Pet equipment is room-scoped/per-pet with quantity-aware shared ownership;
  furniture placement uses fixed-canvas coordinates while preserving legacy RPC
  overloads.
- Feed upload has a durable queue, presigned direct-to-R2 support behind
  `app_config.feed_presigned_upload_enabled`, base64 fallback, and authoritative
  satiety reconciliation from `feed_validate` v21.
- `feed_validate` reward/message writes stay on the response path; partner push
  dispatch stays in `EdgeRuntime.waitUntil`, and old response field types remain
  stable.
- Abandoned-room photo cleanup is human-in-the-loop and fail-closed; approved
  purges must still match stale room/R2 scan evidence.
- Large Home/Chat/Shop files are decomposed with `part` extensions. See
  `memory-bank/architecture.md` before moving code between parts.
- Chat runs on `ChatRoomViewV2` with bounded visible history, Hive cache,
  local-first realtime buffering, tuned image caching, and soft delete for
  recalled `image_feed` messages.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids;
  Godot remains the socket/equipment authoring path.
- GEOFlow, SEO/Firebase Hosting pages, invite fallbacks, and app/universal-link
  files live in `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- App Store metadata for auto-renewable subscriptions must retain the direct
  Apple Standard EULA footer in every `.asc/version-localizations/*.strings`
  description; `test/app_store_metadata_terms_test.dart` locks this.

## Workflow Notes
- `docs/release_status.md` is the source of truth for release/build/backend
  deployment state. `pubspec.yaml` is only the local candidate version.
- Read `docs/ai_collaboration_workflow.md` before server/API/RPC/migration/
  auth/reward/notification/purchase/local durable-state work.
- Use the repo-local skills for shared items, release notes/ASC metadata,
  Crashlytics triage, and UI/UX work before editing those areas.
- Run `flutter build bundle` after adding nested asset folders or PNG sequence
  directories, then confirm generated bundle contents.
- Read `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, equipment preview metadata, or placement code.
- Use `docs/firebase_crashlytics_mcp_workflow.md` and
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP triage.
- Use `docs/ios_app_store_export.md` and
  `scripts/export_ios_appstore_no_apple_symbols.sh` when uploading an existing
  iOS archive while avoiding Apple's immediate symbol-upload warning.
- If ASC wrappers return App Store Connect `-50` for version/localization work,
  use `scripts/asc_version_localization_sync.py` with bundled Codex Python.
- Edge Function `verify_jwt` settings are not centralized in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Run ASC submission preflight for iOS `2.2.2+8`, then submit for review if
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
