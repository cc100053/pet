# Database Schema

Compact map only. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/database_schema_20260516_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

Before any DB claim/change, confirm the live target and inspect the latest
applied migration that rewrites the object.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms/pets/chat: `rooms`, `room_invite_codes`, `room_members`, `pets`,
  `pet_state`, `room_pet_state`, `pet_hunger_tick_schedule`, `messages`,
  `message_reactions`
- Economy/shared room: `items`, inventories, purchases, subscriptions,
  ledgers, `pet_equipment`, room furniture/background tables
- Config/safety: `app_config`, `reports`, `blocks`,
  `notification_delivery_logs`

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is legacy; normal sharing reuses
  `get_or_create_room_invite_code(...)`.
- `pet_hunger_tick_schedule.next_check_at` is the server-side due cursor.
- `rooms.main_pet_id` is the representative pet for room summaries; `pets` is
  no longer unique by `room_id` for v2.0.0 multi-pet support.
- `room_pet_state` is the v2.0.0 shared room hunger/mood state. Old `pet_state`
  remains available and is mirrored from `room_pet_state` for main-pet
  compatibility paths.
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
  quantity is capped by room pet count, and one item copy cannot be equipped on
  two pets at the same time.
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
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, tick/schedule RPCs,
  `claim_feed_double_reward`, v2 `get_room_pets`, `add_room_pet`,
  `set_room_main_pet`, `apply_room_pet_action`, `use_pet_ticket`,
  `purchase_and_use_pet_ticket`
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
