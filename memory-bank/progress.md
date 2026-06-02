# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260530_pre_compaction.md`.

## Current State
- App metadata is prepared for `2.0.2+4`. App Store Connect version `2.0.2`
  (`cb96407b-2767-4889-a3de-212be7b9289c`) has build `4`
  (`97147cec-14a9-4890-b50c-abedf93fc61f`) attached; submission
  `5653be07-b377-43f7-b675-06affede8ed0` is `WAITING_FOR_REVIEW`.
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
- Furniture placement uses fixed-canvas coordinates in prod. The original
  canvas migration added nullable `canvas_position_x/y`; live hotfix
  `20260530125134_fix_room_furniture_canvas_rpc_overloads` removes default
  values from the 6-arg canvas RPC overloads so legacy 4-arg clients remain
  unambiguous.
- Debug admins can freeze hunger decay per room through
  `set_room_hunger_decay_paused(...)`; the expiring override advances
  `last_decay_at` while frozen and parks the server schedule until expiry.
- Chat runs on `ChatRoomViewV2` with bounded visible history, Hive cache,
  local-first realtime buffering, tuned image cache/decode sizes, and sender
  soft-delete for recalled `image_feed` messages.
- Feed uploads run through the durable queue; Home owns global completion/
  failure effects and refreshes the original room.
- `ForceUpdateGate` shows What's New at most once per app session even if app
  lifecycle resumes before `markShown` persists.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids;
  Godot remains the socket/equipment authoring path.
- GEOFlow, SEO/Firebase Hosting pages, invite fallbacks, and app/universal-link
  files live in `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- App Store metadata for auto-renewable subscriptions must retain the direct
  Apple Standard EULA footer in every `.asc/version-localizations/*.strings`
  description; `test/app_store_metadata_terms_test.dart` locks this.

## Workflow Notes
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
- Edge Function `verify_jwt` settings are not in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Monitor App Store review for `2.0.2`.
- Confirm Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Before shipping the Firebase Apple SPM changes, create a TestFlight/archive
  build and confirm Crashlytics receives dSYMs.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
