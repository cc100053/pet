# Progress

Active progress stays current-state focused. Full snapshot:
`memory-bank/archive/progress_20260502_pre_compaction.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; Home and
  Profile share missing-profile creation and timezone sync.
- Avatar uploads use the deployed `avatar_upload` Edge Function and shared
  framing editor flow in both Profile and onboarding.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets must ship with version-gated visibility, old-client fallback, and the
  existing compatibility prompt. Use
  `.codex/skills/shared-item-rollout/SKILL.md`.
- Pet dress-up is live with room-scoped equipment ownership/equip state and
  room selection previews that render equipped items from room data.
- Pet rendering now prefers bundled PNG sequences while preserving GIF asset
  ids as stable source/fallback references during migration.
- Godot is the current socket/equipment authoring path. The exported JSON feeds
  `PetSocketCatalog` and `EquipmentCatalog`; the old Flutter fit tool is
  legacy/debug-only.
- Room invite sharing reuses the current active code by default, stores pending
  signed-out opens, and joins through `join_room_by_code` after bootstrap.
- Shop purchases and IAP grants flow through `EconomyPurchaseAdapter` and
  `ShopEconomyState`; `ShopPurchaseNotifier` owns best-effort `notify_friend`
  delivery for store purchase messages.
- Furniture editing supports selection, drag, scale, horizontal flip, and
  realtime shared-count refresh through `room_item_inventory_revisions`.
- Chat is fully on `ChatRoomViewV2` with bounded history, replies/reactions,
  edit/delete, and local queue reconciliation for feed uploads.
- Feed uploads run through the durable queue; Home owns global refresh and Chat
  only handles local optimistic replacement. Home replays unacknowledged terminal
  feed jobs after lifecycle resume and refreshes the original feed room's pet
  state even when the user has switched rooms.
- Force update, What's New, crash fallback, and ATT-aware AdMob remain separate
  flows.

## Current Workflow Notes
- Run `flutter build bundle` after adding nested asset folders or new PNG
  sequence directories, then confirm the bundle contains the assets.
- Use `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, or equipment preview metadata.
- Use `docs/firebase_crashlytics_mcp_workflow.md` plus
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP setup/triage.
  Prefer ADC via `.firebase-mcp.env`, not `firebase login`.
- If Crashlytics stacks are unsymbolicated, inspect
  `ios/scripts/upload_crashlytics_symbols.sh` before app-side debugging.

## Open Items
- Ensure Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.

## Read More
- Historical snapshot: `memory-bank/archive/progress_20260502_pre_compaction.md`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
