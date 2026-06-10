# Database Schema

Compact map only. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/database_schema_20260530_pre_compaction.md`.
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
  `notification_delivery_logs`, `room_debug_overrides`
- R2 cleanup: `room_cleanup_candidates` (review queue), `room_cleanup_review`
  (admin view; not exposed to anon/authenticated)

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is legacy; normal sharing reuses
  `get_or_create_room_invite_code(...)`.
- `rooms.main_pet_id` points at the canonical main pet in `pets`; additional
  pets live in `room_extra_pets` and only surface through v2.0.0 room-pet RPCs.
  Keep `pets.room_id` unique for legacy clients.
- `room_pet_state` is the shared room hunger/mood/level/exp source of truth.
  `pet_state` mirrors the main pet for compatibility. Passive decay and legacy
  actions must write both.
- `room_extra_pets` mirrors the `pets` shape without `room_id` uniqueness, is
  RLS-scoped to active room members, and is in the Realtime publication.
- `rooms.name` mirrors the main pet's name. `sync_main_pet_name_to_room` and
  `set_room_main_pet` keep it populated for legacy clients.
- `room_debug_overrides` stores admin-only room debug switches. Current switch:
  `hunger_decay_paused_until`, mutated through
  `set_room_hunger_decay_paused(...)`.
- `pet_equipment.pet_id` can reference either `pets.id` or
  `room_extra_pets.id`; cleanup is trigger-based and RLS/RPC pet checks must
  validate against both tables.
- `pet_equipment` stores one equipped item per `(room_id, pet_id, slot)`.
  Supported slots: `head`, `face`, `body`, `back`. Room equipment inventory
  quantity is capped by combined room pet count.
- `items.metadata` is the compatibility contract for decor/equipment:
  `visibility_mode`, `min_app_version`, `shop_visibility`, fallback, assets,
  and slots.
- `room_furniture.canvas_position_x/y` are nullable fixed-canvas center
  fractions for new furniture placement. New clients dual-write these plus
  legacy `position_x/y`; live RPC compatibility depends on keeping the 4-arg
  legacy furniture RPCs and 6-arg canvas overloads without defaulted args.
- `pet_ticket` is a v2.0.0 version-gated 150-diamond consumable. New purchases
  call `purchase_and_use_pet_ticket(...)`; already-owned tickets use
  `use_pet_ticket(...)`.
- `messages.sender_id` can be null for room-wide system events. `delete_message`
  supports sender soft-delete of own `text` or `image_feed`; image-feed recall
  nulls `image_url`/`caption` and does not reverse feed rewards.
- `pet_hunger_tick_schedule.next_check_at` is the server-side hunger due cursor.

## Compatibility Rules
- Public tables exposed through PostgREST need explicit Data API grants in
  migrations; RLS/policies remain the real boundary.
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
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, tick/schedule RPCs,
  `set_room_hunger_decay_paused`, `claim_feed_double_reward`,
  `get_room_pets`, `add_room_pet`, `set_room_main_pet`,
  `apply_room_pet_action`, `use_pet_ticket`, `purchase_and_use_pet_ticket`,
  `equip_pet_item`, `unequip_pet_item`, `get_pet_equipment`
- Shop/equipment/furniture: `get_visible_shop_items`, purchase/grant RPCs,
  inventory/equip helpers, furniture transform helpers
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
- Room photos live in R2 under `rooms/<room_id>/...` (set by `feed_validate`).
  `rooms.last_activity_at` is kept fresh by triggers on `messages` insert and
  `room_members` join/activation; `rooms.status` is `active`/`abandoned`.
- `cleanup_abandoned_rooms` (verify_jwt off; cron-auth via `cleanup_rooms_secret`
  vault secret + `get_cleanup_rooms_secret()`) is human-in-the-loop:
  `mode=scan` records stale rooms into `room_cleanup_candidates` as `pending`
  (no delete); you set `review_status=approved` in Studio; `mode=purge` deletes
  R2 photos for approved rooms only, then marks them `abandoned`/`purged`.
  Crons: `cleanup_abandoned_rooms_scan_daily`, `..._purge_daily`.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Historical snapshots: `memory-bank/archive/`
