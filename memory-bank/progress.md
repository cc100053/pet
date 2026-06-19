# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260613_pre_compaction.md`.

## Current State
- Repo current release baseline is iOS `2.2.2+8` after the completed
  `release-notes-sync` flow. ASC version
  `1761de51-ec73-46e4-8b6f-134d9c650e1d` is `PREPARE_FOR_SUBMISSION`; build
  `702c2f8d-770f-40ec-a013-19cab3c1d098` is `VALID`, encryption `exempt`, and
  attached. Localized release notes were synced via direct App Store Connect
  API fallback; exact IDs and backend deployment history live in
  `docs/release_status.md`.
- Flutter is pinned by `.fvmrc` to `3.44.0` / Dart `3.12.0`; normal local and
  release-sensitive commands use bare `flutter ...` after confirming the
  default SDK matches the pin.
- Multi-pet v2 remains backward-compatible: `pets` is one-row-per-room for
  legacy clients; extra pets live in `room_extra_pets`; shared room stats live
  in `room_pet_state`; `rooms.name` mirrors the main pet.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets need version-gated visibility, old-client fallback, and the existing
  compatibility prompt. Use `.codex/skills/shared-item-rollout/SKILL.md`.
- Pet equipment is room-scoped/per-pet with quantity-aware shared ownership.
- Furniture placement uses fixed-canvas coordinates in production; migration
  `20260530125134` keeps canvas RPC overloads unambiguous for old clients.
- Debug admins can freeze hunger decay per room through
  `set_room_hunger_decay_paused(...)`; server-side scheduling honors the pause.
- Feed reward writes finish before partner push dispatch; `feed_validate` keeps
  old response-field types stable and queues push work with
  `EdgeRuntime.waitUntil`.
- Feed upload has a durable queue. Persisted failed jobs reload as pending so
  old timeout state can silently reconcile instead of replaying stale errors.
- Home refreshes/ticks visible pet state before queueing a feed upload, so the
  hunger bar does not compare a stale pre-decay value with the post-feed value.
- `feed_validate` v21 returns authoritative post-feed `pet_state` + `overfed`
  (additive). The client applies it directly, guards all `pet_state` writes with
  a `last_decay_at` freshness clock (stale snapshots can't regress the satiety
  bar), and predicts +25 optimistically on enqueue. Root fix for the
  intermittent "fed but hunger didn't move" race on slow uploads.
- Presigned direct-to-R2 feed upload is enabled through
  `app_config.feed_presigned_upload_enabled`; new clients fall back to base64
  on failure, and old clients are unaffected.
- Abandoned-room photo cleanup is human-in-the-loop and fail-closed; approved
  purges must still match stale room/R2 scan evidence.
- The large Home/Chat/Shop files are decomposed with `part` extensions. See
  `memory-bank/architecture.md` before moving code between parts.
- Chat runs on `ChatRoomViewV2` with bounded visible history, Hive cache,
  local-first realtime buffering, tuned image cache/decode sizes, and soft
  delete for recalled `image_feed` messages.
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
- Run `flutter build bundle` after adding nested asset folders or PNG sequence
  directories, then confirm generated bundle contents.
- Read `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, equipment preview metadata, or placement code.
- Use `docs/firebase_crashlytics_mcp_workflow.md` and
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP triage.
- Use `docs/ios_app_store_export.md` and
  `scripts/export_ios_appstore_no_apple_symbols.sh` when uploading an existing
  iOS archive while avoiding Apple's immediate symbol-upload warning.
- For ASC release upload flows, build with explicit build name/number, verify
  the exported IPA is not stale, upload with `asc builds upload`, and wait with
  `asc builds wait`.
- If `asc versions create`, `asc versions view`, or
  `asc localizations upload` returns App Store Connect `-50`, use
  `scripts/asc_version_localization_sync.py` with the bundled Codex Python as
  the direct API fallback; it creates/reuses versions, syncs local `.strings`,
  verifies `whatsNew`/`promotionalText`, and checks direct EULA footers.
- Edge Function `verify_jwt` settings are not centralized in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Run ASC submission preflight for iOS `2.2.2+8`, then submit for review if
  approved.
- Monitor App Store/store outcome for iOS `2.2.0+6`.
- End-to-end verify presigned feed upload on a live v2.2.0 build and watch
  `feed_upload_url` / `feed_validate` logs.
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
