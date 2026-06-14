# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260606_pre_compaction.md`.

## Current State
- Repo current release baseline is `2.2.0+6` after the completed
  `release-notes-sync` flow, with bundled What's New and synced ASC
  version-localization metadata.
- App Store Connect version `2.2.0`
  (`ca6b8b89-a99e-4cc7-a23c-886853467b58`) is
  `WAITING_FOR_REVIEW`; repo workflow treats it as current/live for tracking
  purposes. Localized `promotionalText` / `whatsNew` are live for en-US, ja,
  ko, and zh-Hant with EULA descriptions preserved. iOS build `2.2.0+6`
  (`ef250ff1-c94e-45db-9043-dd9f7942ca1b`) is `VALID`, encryption `exempt`,
  and attached to submission `8e1526cd-e1a7-4681-bbba-8490a33d4b53`.
- App Store Connect version `2.1.0`
  (`37897d26-cc47-492c-867f-c7bc3ee4d44b`) is historical/superseded in repo
  workflow; ASC reported `READY_FOR_DISTRIBUTION` on 2026-06-11.
- Flutter is pinned by `.fvmrc` to `3.44.0` (Dart `3.12.0`). The
  default/global `flutter` binary should match that pin, so normal local and
  release-sensitive commands use bare `flutter ...`; if FVM is used, confirm it
  resolves to the same SDK.
- Multi-pet v2.0.0 remains backward compatible: `pets` is one-row-per-room for
  legacy clients, extra pets live in `room_extra_pets`, room-shared hunger/mood/
  level/exp live in `room_pet_state`, and `rooms.name` mirrors the main pet.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets need version-gated visibility, old-client fallback, and the existing
  compatibility prompt. Use `.codex/skills/shared-item-rollout/SKILL.md`.
- Pet equipment is room-scoped and per-pet with quantity-aware shared closet
  ownership. Supported slots are `head`, `face`, `body`, and `back`.
- Furniture placement uses fixed-canvas coordinates in prod. Migration
  `20260530120000` added nullable `canvas_position_x/y`; live hotfix
  `20260530125134` removes default values from 6-arg canvas RPC overloads so
  legacy 4-arg clients remain unambiguous.
- Debug admins can freeze hunger decay per room through
  `set_room_hunger_decay_paused(...)`; the expiring override advances
  `last_decay_at` while frozen and parks the server schedule until expiry.
- Feed rewards no longer get eroded by an immediate follow-up hunger tick:
  migration `20260607005751` anchors successful feed decay at feed time, and
  `20260607005904` keeps `apply_pet_action` execute grants authenticated-only
  on the live Supabase project.
- `feed_validate` v17 returns after feed rewards/messages are written and queues
  partner push delivery with `EdgeRuntime.waitUntil`; this keeps the Home reward
  pending state from waiting on slow `notify_friend` calls. v18 preserves the
  legacy `webhook_skipped: false` response shape for old clients.
- Persisted failed feed-upload jobs reload as pending for silent
  reconcile/retry, so existing users with a locally stored timeout from an older
  feed attempt do not immediately replay a stale upload error.
- Abandoned-room photo cleanup is human-in-the-loop and fail-closed:
  `cleanup_abandoned_rooms` v2 plus migration `20260607135307` only purge
  approved candidates that still match the stale room/R2 scan snapshot; new
  room activity resets approved candidates back to pending.
- The three god-view files were decomposed behavior-preservingly with `part`
  extensions. See `memory-bank/architecture.md` "View Layer Structure" before
  moving code between parts.
- Chat runs on `ChatRoomViewV2` with bounded visible history, Hive cache,
  local-first realtime buffering, tuned image cache/decode sizes, and sender
  soft-delete for recalled `image_feed` messages.
- Feed uploads run through the durable queue; Home owns global completion/
  failure effects and refreshes the original room.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids;
  Godot remains the socket/equipment authoring path.
- `ForceUpdateGate` shows What's New at most once per app session even if app
  lifecycle resumes before `markShown` persists.
- Poop cleaning is optimistic and non-blocking; optimistic state is keyed by
  rounded poop x/y (`_cleaningPoopKeys`) because the server prunes
  `poop_positions` by index.
- GEOFlow, SEO/Firebase Hosting pages, invite fallbacks, and app/universal-link
  files live in `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- App Store metadata for auto-renewable subscriptions must retain the direct
  Apple Standard EULA footer in every `.asc/version-localizations/*.strings`
  description; `test/app_store_metadata_terms_test.dart` locks this.

## Workflow Notes
- Use `docs/release_status.md` as the release/build/backend deployment source
  of truth. `pubspec.yaml` is the local candidate version, ASC/storefront is the
  live store authority, and git commits are evidence rather than release state.
- Run `flutter build bundle` after adding nested asset folders or PNG sequence
  directories, then confirm the assets are in the generated bundle.
- Read `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, equipment preview metadata, or placement code.
- Use `docs/firebase_crashlytics_mcp_workflow.md` plus
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP setup/triage;
  prefer ADC via `.firebase-mcp.env`, not `firebase login`.
- Use `docs/ios_app_store_export.md` and
  `scripts/export_ios_appstore_no_apple_symbols.sh` when uploading an existing
  iOS archive while avoiding Apple's immediate symbol-upload warning.
- For full ASC release upload flows, build with explicit build-name/number,
  verify the IPA Info.plist, upload with `asc builds upload`, then wait with
  `asc builds wait` (see `.codex/skills/release-notes-sync/SKILL.md`).
- After the whole approved `release-notes-sync` flow completes for a target
  version, repo tracking assumes that target is the current live release
  baseline even if ASC still reports a post-submit state such as
  `WAITING_FOR_REVIEW`; record the exact ASC state and IDs as operational notes.
- Edge Function `verify_jwt` settings are not in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Monitor App Store review outcome for version `2.2.0`
  (`ca6b8b89-a99e-4cc7-a23c-886853467b58`), submission
  `8e1526cd-e1a7-4681-bbba-8490a33d4b53`.
- Confirm Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- Smoke-test iOS banner and rewarded ads after the `google_mobile_ads` 8.0.0
  upgrade.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
