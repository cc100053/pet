# Database Schema

Compact map only. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/database_schema_20260509_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

Before any DB claim/change, confirm the live target and inspect the latest
applied migration that rewrites the object.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms/invites: `rooms`, `room_invite_codes`, `room_members`
- Pets/state: `pets`, `pet_state`, `pet_hunger_tick_schedule`
- Chat: `messages`, `message_reactions`
- Economy/items: `items`, `inventories`, `pet_equipment`,
  `room_item_inventories`, `room_item_inventory_revisions`, `room_furniture`,
  `room_backgrounds`, `room_background_state`, ledgers, purchases,
  subscriptions, and IAP transactions
- Config/safety/diagnostics: `app_config`, `reports`, `blocks`,
  `notification_delivery_logs`

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is legacy; normal sharing reuses
  `get_or_create_room_invite_code(...)`.
- `pet_hunger_tick_schedule.next_check_at` is the server-side due cursor.
- `messages.sender_id` can be null for room-wide system events; reply/edit/delete
  state lives on additive row fields.
- `items.metadata` is the compatibility contract for decor/equipment:
  `visibility_mode`, `min_app_version`, `shop_visibility`, fallback metadata,
  and asset/slot fields.
- `pet_equipment` stores one equipped item per `(room_id, pet_id, slot)`;
  supported slots are `head`, `face`, `body`, `back`. The `face` slot is for
  sunglasses and shares the app-side head socket anchor while staying a separate
  mutual-exclusion group from hats.
- Shared furniture counts and equipment ownership are room-scoped, though some
  legacy inventory rows remain buyer-attributed for compatibility.
- `room_furniture` keeps normalized positions, clamped scale, and `flip_x`.

## Compatibility Rules
- Legacy catalog readers only see `items.is_active = true`.
- Version-gated shared decor should stay `is_active = false` and surface through
  `get_visible_shop_items(p_app_version)`.
- Hidden rollout-only decor uses `metadata.shop_visibility = 'hidden'`.
- Keep catalog visibility, purchase RPC predicates, and RLS write policies
  aligned in the same pass.
- Prefer additive/optional RPC changes over parameter changes that can break old
  app versions.

## RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`, invite-code RPCs,
  `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, tick/schedule RPCs,
  `claim_feed_double_reward`
- Shop/economy: `get_visible_shop_items`, purchase/grant RPCs
- Pet equipment: equip/unequip/get inventory RPCs and room equipment purchase
  RPCs
- Furniture/chat/unread: room furniture inventory/place/transform/flip helpers,
  `edit_message`, `delete_message`, unread-count RPCs

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use `(select auth.uid())`,
  `TO authenticated`, and indexes that match policy predicates.
- `feed_validate` and `avatar_upload` enforce image size/MIME checks before R2
  upload.
- `notify_friend` canonicalizes payloads from DB and constrains recipients to
  active room members.
- `hunger_tick_dispatch` reads due rows from `pet_hunger_tick_schedule`, runs
  service-role tick RPCs, and dispatches alert notifications.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Historical snapshots: `memory-bank/archive/`
