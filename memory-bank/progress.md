# Progress

Active progress stays current-state focused. Full snapshots:
`memory-bank/archive/progress_20260425_pre_compaction.md`,
`memory-bank/archive/progress_20260418_pre_compaction.md`,
`memory-bank/archive/progress_20260411_pre_compaction.md`, and older
`memory-bank/archive/progress_archive.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; Home and
  Profile share missing-profile creation plus timezone sync.
- Avatar uploads now go through the deployed `avatar_upload` Edge Function and
  R2 flow. Profile and onboarding both use the same full-screen framing editor,
  and existing remote avatars can be reframed without re-uploading.
- Shared room content is mixed-version aware. Backgrounds, furniture, and pets
  must use version-gated visibility plus old-client fallback behavior. Use
  `.codex/skills/shared-item-rollout/SKILL.md` for future rollouts.
- Pet dress-up is live for app `1.3.0`. The repo Supabase project has the live
  `pet_equipment` table/RPCs and version-gated straw hat catalog row; Home,
  status/avatar surfaces, inventory previews, and Shop all use the shared
  equipment/catalog pipeline.
- Pet rendering now prefers bundled PNG frame sequences across current pet/state
  surfaces. Runtime code resolves old GIF asset ids through
  `PetAnimationFrames`, `PetAnimationFrameBuilder`, and `PetAnimatedImage`, so
  GIF paths remain stable source/fallback ids during the migration window.
- Socket/equipment placement is authored against `PetSocketCatalog`,
  `EquipmentCatalog`, and shared overlay layout math. Straw-hat placement now
  uses Godot-authored head sockets and timed motion tracks for every current
  pet stay/sleep/walk PNG sequence, with per-pet/per-state hat anchor and size
  overrides in `EquipmentCatalog`. The Godot Socket Authoring add-on can scan
  pet/action scenes, open the selected scene, auto-load the matching socket
  JSON, scan Flutter equipment PNGs, and preview a clear/no-item state before
  export. See `docs/godot-png-sequence-socket-workflow.md`.
- Room invite sharing reuses the current active code by default, supports
  share-sheet invite links with `invite_code`, stores pending signed-out opens,
  and joins through live `join_room_by_code` after Home bootstrap.
- Shop-backed decor uses `get_visible_shop_items(p_app_version)` for
  compatibility-aware clients, while hidden rollout-only rows stay out of the
  Shop with `metadata.shop_visibility = 'hidden'`.
- Furniture editing supports tap-select, drag, scale controls, and per-instance
  horizontal flip, with shared owned counts refreshed through
  `room_item_inventory_revisions` realtime signals.
- Chat uses only `ChatRoomViewV2`: latest-20 open, 20-message older pages,
  80-message visible cap, newest-20 Hive cache, edit/delete, replies/reactions,
  mention display, and the focused long-press overlay.
- Feed uploads run through the durable Hive/Riverpod queue. Capture enqueues,
  Home owns global completion/failure refresh, and Chat reconciles optimistic
  rows locally.
- Force-update, What's New, crash fallback, and ATT-aware AdMob flows are all
  separate. iOS debug banner `AdWidget`s remain disabled by default unless
  `ADMOB_ENABLE_DEBUG_BANNER_VIEWS=true` is set for intentional testing.

## Current Workflow Notes
- Run `flutter build bundle` after adding nested asset folders or new PNG
  sequence directories, then confirm the generated bundle contains the assets.
- Use `docs/firebase_crashlytics_mcp_workflow.md` plus
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP setup and
  triage. The doc still references `.firebase-mcp.env.example`, which is absent
  in this checkout.
- Use `docs/godot-png-sequence-socket-workflow.md` before changing pet PNG
  sequences, socket exports, or equipment preview metadata.

## Open Items
- Ensure Edge Function secrets/config are set in Supabase for `delete_account`
  and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Restore or verify `.firebase-mcp.env.example`; Crashlytics MCP docs and
  `README.md` reference it, but the file is missing in this checkout.

## Read More
- Historical detail: `memory-bank/archive/progress_20260425_pre_compaction.md`
- Earlier logs: `memory-bank/archive/progress_archive.md`
- Current architecture and schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
