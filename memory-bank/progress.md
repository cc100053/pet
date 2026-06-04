# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260530_pre_compaction.md`.

## Current State
- Local app metadata is prepared for `2.1.0+5` with bundled What's New and
  synced ASC version-localization metadata.
- App Store Connect version `2.1.0`
  (`37897d26-cc47-492c-867f-c7bc3ee4d44b`) is
  `PREPARE_FOR_SUBMISSION`; localized `promotionalText` / `whatsNew` are live
  for en-US, ja, ko, and zh-Hant with EULA descriptions preserved.
- iOS build `2.1.0+5` was built from Flutter and uploaded to App Store Connect.
  Build `67f39308-02eb-4a9a-9d32-64698ea4d99b` is `VALID`, encryption
  `exempt`, uploaded `2026-06-03T08:58:19-07:00`. Attach it to version
  `37897d26-cc47-492c-867f-c7bc3ee4d44b` before submission.
- App Store Connect version `2.0.2`
  (`cb96407b-2767-4889-a3de-212be7b9289c`) is public on the JP storefront, but
  `asc versions list` still labels it `READY_FOR_DISTRIBUTION`.
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
- The three god-view files were decomposed (behavior-preserving) on branch
  `refactor/god-file-decomposition`: `home_view.dart` 5737->~2.1k,
  `chat_room_view_v2.dart` 3657->~2.5k, `shop_view.dart` 2340->1316, via new
  `part` extensions; their giant `build()` methods were broken into helpers
  (chat 442->167, home 249->161, shop notice 239->182). See
  `memory-bank/architecture.md` "View Layer Structure" for the conventions.
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
- Attach ASC build `67f39308-02eb-4a9a-9d32-64698ea4d99b` to version `2.1.0`
  (`37897d26-cc47-492c-867f-c7bc3ee4d44b`) and continue App Store submission
  preflight.
- Confirm Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Before shipping the Firebase Apple SPM changes, create a TestFlight/archive
  build and confirm Crashlytics receives dSYMs.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
