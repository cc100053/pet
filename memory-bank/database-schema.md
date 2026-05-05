# Database Schema

Compact map only. Full snapshot:
`memory-bank/archive/database_schema_20260502_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

Before any DB claim or change, confirm the live target and inspect the latest
applied migration that rewrites the object.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms/invites: `rooms`, `room_invite_codes`, `room_members`
- Pets/state: `pets`, `pet_state`, `pet_hunger_tick_schedule`
- Chat: `messages`, `message_reactions`
- Economy/items: `items`, `inventories`, `pet_equipment`,
  `room_item_inventories`, `room_item_inventory_revisions`, `room_furniture`,
  `room_backgrounds`, `room_background_state`, `coin_ledger`, `diamond_ledger`,
  `purchases`, `subscriptions`, `iap_transactions`
- Config/safety/diagnostics: `app_config`, `reports`, `blocks`,
  `notification_delivery_logs`

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is the legacy primary code; `room_invite_codes` is the
  current multi-code system. Normal sharing should reuse
  `get_or_create_room_invite_code(...)`.
- `pet_hunger_tick_schedule.next_check_at` is the server-side due cursor for
  hunger scheduling.
- `messages.sender_id` can be null for room-wide system events. Reply/edit/delete
  state lives on the message row via additive fields.
- `items.metadata` is the compatibility contract for decor/equipment:
  `visibility_mode`, `min_app_version`, `shop_visibility`,
  fallback metadata, and asset/slot fields.
- `pet_equipment` stores one equipped item per `(room_id, pet_id, slot)`;
  supported slots are `head`, `body`, `back`.
- Shared furniture counts and shared equipment ownership are room-scoped even
  though some legacy inventory rows remain buyer-attributed for compatibility.
- `room_furniture` keeps normalized positions, clamped scale, and `flip_x`.

## Compatibility Rules
- Legacy catalog readers only see `items.is_active = true`.
- Version-gated shared decor should stay `is_active = false` and surface
  through `get_visible_shop_items(p_app_version)`.
- Hidden rollout-only decor uses `metadata.shop_visibility = 'hidden'`.
- When rollout rules change, keep catalog visibility, purchase RPC predicates,
  and RLS write policies aligned in the same pass.
- Prefer additive or optional RPC changes over parameter changes that can break
  old app versions.

## RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`,
  `get_or_create_room_invite_code`, `create_room_invite_code`,
  `list_room_invite_codes`, `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, `tick_pet_state`,
  `tick_pet_state_as_system`, `refresh_pet_hunger_tick_schedule`,
  `claim_feed_double_reward`
- Shop/economy: `get_visible_shop_items`, coin/diamond purchase RPCs,
  `grant_iap_coins`, `grant_iap_diamonds`
- Pet equipment: `equip_pet_item`, `unequip_pet_item`, `get_pet_equipment`,
  `get_room_equipment_inventory`, room equipment purchase RPCs
- Furniture/chat/unread: `get_room_furniture_inventory`,
  `place_room_furniture`, transform/flip helpers, `edit_message`,
  `delete_message`, unread count RPCs

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use `(select auth.uid())`,
  `TO authenticated`, and indexes that match policy predicates.
- `feed_validate` and `avatar_upload` enforce the 10MB decoded-image cap and
  MIME allow-list before R2 upload.
- `notify_friend` canonicalizes payload content from DB and constrains
  recipients to active room members.
- `hunger_tick_dispatch` reads due rows from `pet_hunger_tick_schedule`, runs
  service-role tick RPCs, and dispatches alert notifications.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Historical snapshot:
  `memory-bank/archive/database_schema_20260502_pre_compaction.md`
