# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260516_pre_compaction.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; avatar uploads
  use the deployed `avatar_upload` Edge Function and shared framing editor.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets must ship with version-gated visibility, old-client fallback, and the
  existing compatibility prompt. Use `.codex/skills/shared-item-rollout/SKILL.md`.
- Multi-pet v2.0.0 backend foundation is live: `rooms.main_pet_id`,
  multi-row `pets` per room, shared `room_pet_state`, and room-pet RPCs are in
  place. Pet tickets are live as a v2.0.0-gated 150-diamond consumable; new
  purchases use one atomic buy-and-add RPC, while owned tickets can still be
  consumed through a recovery RPC (`use_pet_ticket`, `set_room_main_pet`, and
  `add_room_pet` are now SECURITY DEFINER so non-owner room members can
  correctly mutate `main_pet_id`; `rooms_update` RLS only allows the owner).
  Home's active-pet fallback resolves through `rooms.main_pet_id` so multi-pet
  rooms do not trigger object-query 406s. Home loads `get_room_pets` and
  renders non-main room pets as independently wandering, tappable, and
  draggable companions (own AnimatedPositioned per pet, shared wander timer,
  per-pet drag state). Tap on any pet briefly shows its name tag (2.5s).
  Top-left status-bar avatar tap opens a main-pet switcher sheet when the
  room has 2+ pets and calls `set_room_main_pet`. First 1->2 pet transition
  prompts an atomic rename via `apply_multi_pet_room_naming` (new room name
  + first pet name auto-inherited from old room name). Home subscribes to
  `pets`/`rooms` realtime for the active room so all the above sync across
  members without a manual room switch. Per-pet equipment target selection
  and feed-all/light-collision are still pending.
- Pet dress-up is live with room-scoped ownership/equip state. V1.4.0 slots are
  live-backed as `head` hats, `face` sunglasses, and `body` ribbon; `face`
  shares the app-side head socket anchor while staying independently equip-able.
- Equipment is now quantity-aware for multi-pet: Shop can buy more copies up to
  room pet count, and the live equip RPC prevents one copy from being worn by
  multiple pets simultaneously.
- Shop pet-ticket flow is Return Letter-style: rooms at 5 pets cannot buy/use;
  otherwise Buy opens pet selection and atomically deducts diamonds plus adds
  the selected pet. Same pet types are allowed. A follow-up migration fixed the
  `pet_id` PL/pgSQL output-column ambiguity in the ticket RPCs.
- V1.4.0 equipment live prices are crown 260, sunglasses 240, and ribbon 170
  coins, still hidden from pre-1.4.0 catalog readers.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids.
- Godot is the socket/equipment authoring path.
- Room invite sharing reuses active codes and joins through `join_room_by_code`
  after bootstrap.
- Shop purchases and IAP grants flow through `EconomyPurchaseAdapter` and
  `ShopEconomyState`; store purchase messages use best-effort `notify_friend`.
- Furniture editing supports selection, drag, scale, horizontal flip, and
  realtime shared-count refresh.
- Chat is on `ChatRoomViewV2`; feed uploads run through the durable queue.
- GEOFlow, multilingual SEO/GEO guides, Firebase Hosting static pages, invite
  fallbacks, app/universal-link files, and related automation live in
  `/Users/fatboy/geo-marketing`, not this Flutter app repo.

## Workflow Notes
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
- Edge Function `verify_jwt` settings are not in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Ensure Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
