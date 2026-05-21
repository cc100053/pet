# Database Schema

Compact map only. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/database_schema_20260516_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

Before any DB claim/change, confirm the live target and inspect the latest
applied migration that rewrites the object.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms/pets/chat: `rooms`, `room_invite_codes`, `room_members`, `pets`,
  `room_extra_pets`, `pet_state`, `room_pet_state`,
  `pet_hunger_tick_schedule`, `messages`, `message_reactions`
- Economy/shared room: `items`, inventories, purchases, subscriptions,
  ledgers, `pet_equipment`, room furniture/background tables
- Config/safety: `app_config`, `reports`, `blocks`,
  `notification_delivery_logs`

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is legacy; normal sharing reuses
  `get_or_create_room_invite_code(...)`.
- `pet_hunger_tick_schedule.next_check_at` is the server-side due cursor.
- `rooms.main_pet_id` points at the canonical main pet, which always lives in
  `pets` (unique by `room_id` so legacy clients' `.maybeSingle()` works).
  Additional pets live in `room_extra_pets` and only surface via the v2.0.0
  `get_room_pets` RPC. `set_room_main_pet` swaps rows between the two tables
  to promote/demote.
- `room_extra_pets` mirrors the `pets` shape (no `room_id` uniqueness),
  RLS-scoped to room members, and is in the `supabase_realtime` publication.
  It holds every non-main pet. Home subscribes to both `pets` and
  `room_extra_pets` for the active room.
- `room_debug_overrides` stores admin-only, room-scoped debug switches. The
  current switch is `hunger_decay_paused_until`; it is mutated through the
  admin-gated `set_room_hunger_decay_paused(...)` RPC, not exposed directly to
  app roles.
- `room_pet_state` is the v2.0.0 shared room hunger/mood/level/exp state.
  `pet_state` is mirrored from `room_pet_state` for main-pet compatibility
  paths. `tick_pet_state` (passive decay) writes its result into BOTH the
  main pet's `pet_state` and `room_pet_state`, so the shared state never goes
  stale (a stale value previously made a freshly-switched main pet appear to
  starve). `apply_pet_action` (legacy main-pet feed/clean/touch) likewise
  mirrors its result into `room_pet_state`; without it a feed lived only in
  `pet_state` and a later main-pet swap restored the stale shared hunger. pets'/`room_extra_pets`' `level`/`exp` mirror `room_pet_state` via
  triggers (bounded by `pg_trigger_depth`); new pets inherit the room's
  current level on insert, so all pets — and legacy clients reading
  `pets.level` — see the same room level.
- Naming model B: `rooms.name` mirrors the main pet's name.
  `sync_main_pet_name_to_room` updates `rooms.name` when the main pet is
  renamed, and `set_room_main_pet` copies the promoted pet's name into
  `rooms.name`. Each pet keeps its own `name`. `rooms.name` stays populated
  for legacy clients. (`apply_multi_pet_room_naming` exists but is unused by
  the client under model B.)
- `pet_equipment.pet_id` no longer has an FK so it can reference either
  `pets.id` or `room_extra_pets.id`; cleanup is done via AFTER DELETE
  triggers on both source tables. The `pet_equipment_insert`/`_update` RLS
  `WITH CHECK` policies validate the pet against BOTH `pets` and
  `room_extra_pets` (an earlier version only checked `pets`, so equipping
  onto an extra pet failed with 42501).
- `messages.sender_id` can be null for room-wide system events; reply/edit/delete
  state lives on additive row fields.
- `items.metadata` is the compatibility contract for decor/equipment:
  `visibility_mode`, `min_app_version`, `shop_visibility`, fallback, assets,
  and slots.
- `pet_ticket` is a v2.0.0 version-gated consumable item priced at 150 diamonds.
  New purchases call `purchase_and_use_pet_ticket(...)` so pet capacity check,
  diamond debit, ledger write, and pet insert happen in one transaction.
  `use_pet_ticket(...)` remains for any already-owned ticket inventory.
- `pet_equipment` stores one equipped item per `(room_id, pet_id, slot)`;
  supported slots are `head`, `face`, `body`, `back`. Room equipment inventory
  quantity is capped by room pet count (`room_pet_count(p_room_id)` counts both
  `pets` + `room_extra_pets`; `purchase_room_equipment_with_coins/diamonds` use
  it), and one item copy cannot be equipped on two pets at the same time.
- Shared furniture counts and equipment ownership are room-scoped, though some
  legacy inventory rows remain buyer-attributed for compatibility.
- `room_furniture` keeps normalized positions, clamped scale, and `flip_x`.

## Compatibility Rules
- Public tables that the app exposes through supabase-js/PostgREST need explicit
  Data API grants in migrations; keep RLS/policies as the real boundary.
  `pet_hunger_tick_schedule` remains service-role-only.
- Legacy catalog readers only see `items.is_active = true`.
- Version-gated shared decor should stay `is_active = false` and surface through
  `get_visible_shop_items(p_app_version)`.
- Hidden rollout-only decor uses `metadata.shop_visibility = 'hidden'`; keep
  catalog RPCs, purchase predicates, and RLS write policies aligned.
- Prefer additive/optional RPC changes over parameter changes that can break old
  app versions.

## RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`, invite-code RPCs,
  `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, tick/schedule RPCs
  (`tick_pet_state` mirrors decay into `room_pet_state`),
  `set_room_hunger_decay_paused` (debug-admin room hunger freeze),
  `claim_feed_double_reward`, v2 `get_room_pets` (UNIONs `pets` +
  `room_extra_pets`), `add_room_pet`, `set_room_main_pet` (swaps rows across
  the two tables + syncs room name), `apply_room_pet_action`, `use_pet_ticket`,
  `purchase_and_use_pet_ticket`, `equip_pet_item`, `unequip_pet_item`,
  two-arg `get_pet_equipment` (all validate pet in either `pets` OR
  `room_extra_pets`; the one-arg legacy `get_pet_equipment` has no pet check)
- Shop/equipment/furniture: `get_visible_shop_items`, purchase/grant RPCs,
  equip/unequip/get inventory RPCs, furniture transform helpers
- Chat/unread: `edit_message`, `delete_message`, unread-count RPCs

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use `(select auth.uid())`,
  `TO authenticated`, and matching indexes in RLS.
- `feed_validate` and `avatar_upload` enforce image size/MIME checks before R2
  upload.
- `notify_friend` canonicalizes payloads from DB and constrains recipients to
  active room members.
- `hunger_tick_dispatch` reads due rows from `pet_hunger_tick_schedule`, runs
  service-role tick RPCs, and dispatches alert notifications.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Historical snapshots: `memory-bank/archive/`
