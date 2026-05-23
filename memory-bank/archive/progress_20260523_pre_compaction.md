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
  `room_extra_pets` table, shared `room_pet_state`, and room-pet RPCs are in
  place. `pets` table remains 1-row-per-room (unique constraint restored)
  so legacy clients' `from('pets').eq('room_id', X).maybeSingle()` keeps
  working; extras live in `room_extra_pets` and surface only through the
  v2.0.0 `get_room_pets` RPC. Level/exp also moved to `room_pet_state` as
  source of truth — triggers cascade changes to every pet row in the room,
  and new pets inherit the room's current level on insert. Pet tickets are live as a v2.0.0-gated 150-diamond consumable; new
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
  room has 2+ pets and calls `set_room_main_pet`. Naming model B:
  `rooms.name` mirrors the main pet's name (trigger syncs main pet rename →
  room name; `set_room_main_pet` copies the promoted pet's name into the
  room). Each pet keeps its own name for identity; there is no separate
  room-rename dialog. Home subscribes to
  `pets`/`rooms` realtime for the active room so all the above sync across
  members without a manual room switch. Feeding triggers all extras to
  converge on the food in a tight ring around the main pet. Pets may overlap
  freely while wandering (no repulsion/collision system). Extras run the same
  walk/sleep/stay animation state
  machine and full avatar size as the main pet (extra avatars render at
  `normalizedTarget` so facing always matches travel direction). The equipment
  panel shows a persistent pet selector row (when the room has 2+ pets) so the
  user picks the dress-up target up front; the preview, equipped state, and
  equip/unequip all act on `_selectedEquipPetId` (defaults to the main pet).
  The selected pet's gear loads into `_panelEquippedItemsBySlot` for non-main
  targets so the on-screen main pet avatar is untouched. Every room pet now
  renders its own gear: `_loadAllPetEquipment` populates `_equippedSkusByPetId`
  (whole-room `pet_equipment` query) which feeds extras on screen, the selector
  chips, the main-pet switcher avatars, and the on-screen MAIN pet too — it
  reads `_equippedSkusByPetId[_petId]` first (falling back to the slower
  per-pet `get_pet_equipment` map `_equippedSkusBySlot`) so its gear appears
  together with the extras instead of popping on a 1-2s delay after room entry. Long-pressing an on-screen extra
  pet opens the rename dialog (`_openPetNameEditor(targetPet:)` reuses one
  prompt for main + extras; extra rename just reloads room pets). Equipment
  inventory dims items whose copies are all worn by other pets: home_view
  tracks per-item room quantity (`_ownedEquipmentQtyById`, from
  `get_room_equipment_inventory.total_quantity`) and computes
  `_availableEquipmentCopies` (quantity minus copies worn across
  `_equippedSkusByPetId`), passed to the panel so a fully-used item shows a
  lock + "in use" label and can't be previewed/equipped; if a copy is grabbed
  concurrently, `equip_pet_item`'s `equipment_copy_unavailable` is caught and
  surfaced as a friendly snackbar instead of a raw error.
- Room-selection preview gear is scoped to each room's `main_pet_id`:
  `_fetchRoomEquippedSkus` first reads `rooms.id/main_pet_id` for the requested
  rooms and keeps only `pet_equipment` rows whose `pet_id` matches the main pet
  (it previously took all pets' rows, last-per-slot wins, so the preview showed
  a mix and went stale after a main-pet switch). `set_room_main_pet` updates
  `rooms.main_pet_id`, so a later `_fetchRooms` reflects the new main pet; the
  active room is also corrected immediately via `_loadPetEquipment` writing the
  new main pet's gear into `_roomEquippedSkusBySlot`.
- Extra-pet equipment parity: `pet_equipment` INSERT/UPDATE RLS `WITH CHECK`
  (migration `20260521120000_pet_equipment_policies_allow_extra_pets`) and the
  `equip_pet_item` / `unequip_pet_item` / two-arg `get_pet_equipment` RPCs
  (migration `20260521130000_equipment_rpcs_allow_extra_pets`) all validate the
  pet against BOTH `pets` and `room_extra_pets`. Earlier versions only checked
  `pets`, so equipping onto an extra pet hit RLS 42501, and reading/removing an
  extra pet's gear raised `pet_not_found` (swallowed by
  `_loadPanelEquipmentForSelectedPet`, leaving the panel preview blank and the
  item locked/un-removable).
- Home loading is latency-tuned. `_fetchRooms` runs its five per-room queries
  (pet summaries, latest feeds, member counts, unread counts, equipped skus)
  concurrently via `Future.wait` instead of serially; equipped skus stay
  best-effort via `.catchError`. `_bootstrapHome` fetches rooms concurrently
  with the profile/coins reads and fires `_refreshProPlanStatus` unawaited
  (RevenueCat never gates first paint). Cold start no longer double-fetches the
  room list: bootstrap calls `_refreshRoomSelectionHealthBars(summariesOnly:
  true)`, which ticks decay then patches only health/level via
  `_patchRoomSelectionPetSummaries` (full `_fetchRooms` is reserved for
  resume/nav-back/periodic refresh). Room entry is warm-aware: `_switchRoom`
  pre-paints `_petId`/`_petState` from the in-session `_petIdByRoom`/
  `_petStateByRoom` caches and skips the loading overlay + 550ms min-duration
  when a room was visited earlier; only cold first entries show the overlay.
  `_refreshPetState` awaits the `tick_pet_state` decay (health read depends on
  it) but dispatches hunger alerts unawaited so they never hold first paint.
- Hunger/level are room-shared. `tick_pet_state` mirrors its decay result back
  into `room_pet_state` (not just the main pet's `pet_state`), and
  `apply_pet_action` (the client feed/clean/touch path) likewise mirrors its
  result into `room_pet_state` (migration
  `20260521150000_apply_pet_action_mirrors_room_pet_state`). Both keep the
  shared state authoritative, so switching the main pet — which syncs FROM
  `room_pet_state` — no longer reverts hunger to a stale pre-feed/pre-decay
  value.
- Debug admins can freeze hunger decay per room through
  `set_room_hunger_decay_paused(...)`. The override is expiring and
  room-scoped, keeps both `pet_state` and `room_pet_state` alive, advances
  `last_decay_at` while frozen so unfreezing does not trigger catch-up decay,
  and parks the server hunger schedule until the freeze expires.
- Main-pet switch: after `set_room_main_pet`, Home repoints `_petId` to the
  promoted pet (clearing the stale subscription) so `_refreshPetState` loads
  the correct pet; a `pet_not_found` from a stale switcher list is recovered
  silently by reloading. `set_room_main_pet` sets a transaction-local flag
  (`app.skip_pet_equipment_cleanup`) while it hops rows between `pets` and
  `room_extra_pets`, so the pet-delete cleanup trigger does not wipe a pet's
  equipment during a swap. The switch also re-materializes the promoted pet's
  `pet_state` (via `sync_room_pet_state_to_main_pet_state`): the new row is
  inserted at the default hunger (100) then dropped to the shared low room
  hunger, which the `handle_pet_hunger_alerts` BEFORE-UPDATE trigger used to
  read as a fresh downward crossing — spawning a bogus `hunger_alert` system
  message (chat entry + toast + `notify_friend` push) on every switch. Migration
  `20260521140000_suppress_hunger_alert_on_main_pet_swap` gates that trigger
  behind a transaction-local `app.skip_hunger_alerts` flag and sets it around
  the swap's sync call, so a swap can't manufacture a false alert; genuine
  `tick_pet_state` decay still alerts normally.
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
- Sent photos are recallable by the sender (un-send). `delete_message` now
  accepts `text` OR `image_feed`; recalling a photo soft-deletes it and nulls
  `image_url`/`caption` while keeping `coins_awarded` and NOT reverting the
  pet's feeding (the feed reward is already 10-min cooldown-gated). The chat
  long-press sheet shows Delete for the user's own photo (edit stays
  text-only); the home full-screen photo viewer shows a recall button only on
  the current user's own photo (`onDeletePhoto` + `currentUserId`). The chat
  adapter renders a deleted `image_feed` as the "deleted" tombstone (deleted
  check now precedes the image branch). Home drops a recalled photo from the
  gallery locally and via a new `messages` UPDATE realtime handler so other
  members refresh too; old clients filter null-image feeds and fall back to a
  grey placeholder card (no crash).
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
