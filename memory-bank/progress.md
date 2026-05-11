# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260509_pre_compaction.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; avatar uploads
  use the deployed `avatar_upload` Edge Function and shared framing editor.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets must ship with version-gated visibility, old-client fallback, and the
  existing compatibility prompt. Use `.codex/skills/shared-item-rollout/SKILL.md`.
- Pet dress-up is live with room-scoped equipment ownership/equip state and room
  selection previews that render equipped items from room data.
- V1.4.0 equipment is app-side wired with separate logical slots: hats use
  `head`, sunglasses use `face` while resolving through the head socket anchor,
  and ribbon uses `body`, so all three categories can coexist.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids as
  stable source/fallback references during migration.
- Godot is the socket/equipment authoring path. Exported JSON feeds
  `PetSocketCatalog` and `EquipmentCatalog`; the old Flutter fit tool is
  legacy/debug-only.
- Room invite sharing reuses the active code, stores pending signed-out opens,
  and joins through `join_room_by_code` after bootstrap.
- Shop purchases and IAP grants flow through `EconomyPurchaseAdapter` and
  `ShopEconomyState`; store purchase messages use best-effort `notify_friend`.
- Furniture editing supports selection, drag, scale, horizontal flip, and
  realtime shared-count refresh.
- Chat is on `ChatRoomViewV2` with bounded history, replies/reactions,
  edit/delete, and local queue reconciliation for feed uploads.
- Feed uploads run through the durable queue; Home owns global refresh and Chat
  only handles local optimistic replacement.
- Force update, What's New, crash fallback, and ATT-aware AdMob remain separate
  flows.
- GEOFlow, multilingual SEO/GEO guides, Firebase Hosting static pages, invite
  fallbacks, app/universal-link files, and related automation live in
  `/Users/fatboy/geo-marketing`, not this Flutter app repo.

## Current Workflow Notes
- Run `flutter build bundle` after adding nested asset folders or new PNG
  sequence directories, then confirm the bundle contains the assets.
- Read `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, or equipment preview metadata.
- Use `docs/firebase_crashlytics_mcp_workflow.md` plus
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP setup/triage;
  prefer ADC via `.firebase-mcp.env`, not `firebase login`.
- If Crashlytics stacks are unsymbolicated, inspect
  `ios/scripts/upload_crashlytics_symbols.sh` before app-side debugging.
- For GEOFlow/SEO/Firebase Hosting work, use `/Users/fatboy/geo-marketing`;
  PetTomo-specific publishing lives under `projects/pettomo`.

## Open Items
- Ensure Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
