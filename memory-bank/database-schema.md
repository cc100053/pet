# Database Schema

Compact map only. Full snapshots: `memory-bank/archive/database_schema_20260418_pre_compaction.md`
and older `memory-bank/archive/database_schema_20260411_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

For schema/RPC work, confirm the live target and inspect the latest applied
migration that rewrites the object before proposing or applying changes.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms: `rooms`, `room_invite_codes`, `room_members`
- Pets: `pets`, `pet_state`, `pet_hunger_tick_schedule`
- Chat: `messages`, `message_reactions`
- Gameplay/economy: `label_mappings`, `quests`, `daily_quests`,
  `action_cooldowns`, `coin_ledger`, `diamond_ledger`, `items`, `inventories`,
  `room_item_inventories`, `room_furniture`, `room_backgrounds`,
  `room_background_state`, `purchases`, `subscriptions`, `iap_transactions`
- Safety/config/diagnostics: `reports`, `blocks`, `app_config`,
  `notification_delivery_logs`

## Current Field Contracts
- `profiles.avatar_url` supports `preset:<id>` or remote R2 URL; timezone is
  synced through `ProfileBootstrapService`.
- `rooms.timezone` drives room night mode; `rooms.invite_code` remains the
  legacy primary invite code while `room_invite_codes` supports up to 3 active
  codes per room.
- `pet_state` stores hunger/mood/hygiene, poop state, action timestamps, feed
  burst tracking, and one-time hunger alert markers/message IDs.
- `pet_hunger_tick_schedule.next_check_at` is the server-side hunger due cursor.
- `messages.sender_id` may be null for room-wide system events; newer
  `clean_poop` messages store the actor so unread logic can exclude self-actions.
- `messages.reply_to_message_id` backs chat/photo replies. Text-message
  edit/delete state is additive: `edited_at`, `deleted_at`, and `deleted_by`.
  Soft delete clears `messages.body` and leaves the timeline placeholder.
- `message_reactions` allows one reaction per `(message_id, user_id)`.
- `items.metadata` carries catalog contracts: IAP fields, background metadata,
  furniture `asset_path`, `visibility_mode`, `min_app_version`,
  `shop_visibility`, and fallback metadata.
- `room_item_inventories` is still buyer-attributed; shared furniture totals use
  `get_room_furniture_inventory`.
- `room_item_inventory_revisions` is the room-level realtime signal for shared
  furniture count changes.
- `room_furniture.scale` is clamped to `0.8..2.0`, positions are normalized
  `0..1`, and `flip_x` stores per-instance horizontal flip for newer clients.

## Compatibility Rules
- Legacy/public catalog rows can use `items.is_active = true`.
- Version-gated shared decor should remain `is_active = false` and become visible
  through `get_visible_shop_items(p_app_version)` once `app_version_compare(...)`
  passes.
- Rollout-only decor hidden from Shop uses `metadata.shop_visibility = 'hidden'`.
- For shop-backed decor, align catalog visibility, purchase RPC validation, and
  table RLS write policy in the same change.
- Bathroom furniture and the 500-candy exchange pack are gated at app `1.1.2`;
  live rows stay inactive for legacy catalog reads.
- Prefer additive/backward-compatible RPCs over changing parameters used by old
  app versions.

## RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`, invite-code RPCs,
  `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, `tick_pet_state`,
  `tick_pet_state_as_system`, `refresh_pet_hunger_tick_schedule`,
  `claim_feed_double_reward`
- Shop/economy: `get_visible_shop_items`, coin/diamond purchase RPCs for items,
  furniture, backgrounds, plus `grant_iap_coins`, `grant_iap_diamonds`
- Furniture: `get_room_furniture_inventory`, `place_room_furniture`,
  `update_room_furniture_transform`, `update_room_furniture_flip`, and legacy
  scale/position helpers
- Chat: `edit_message(p_room_id, p_message_id, p_body)` and
  `delete_message(p_room_id, p_message_id)` only update authenticated active
  room members' own non-deleted text messages; delete clears `body`.
- Unread badges: `get_unread_message_total_for_user`,
  `get_unread_message_counts_for_user`

## RLS And Index Rules
- Enable RLS on user/room data; scope access through active `room_members`.
- Use `(select auth.uid())`, include `TO authenticated`, and index columns used
  in `WHERE`, `JOIN`, and RLS predicates.
- Room-scoped policy shape:
  `exists (select 1 from room_members rm where rm.room_id = <table>.room_id and rm.user_id = (select auth.uid()) and rm.is_active)`.

## Edge Data Notes
- `feed_validate` and `avatar_upload` enforce a 10MB decoded-image cap and image
  MIME allow-list before R2 upload.
- `claim_feed_double_reward(p_room_id, p_message_id)` locks the caller-owned feed
  message, dedupes through `coin_ledger` metadata, and updates
  `messages.coins_awarded` to the doubled total.
- `notify_friend` canonicalizes payload content from DB and constrains recipients
  to active room members.
- `hunger_tick_dispatch` reads due rows from `pet_hunger_tick_schedule`, calls
  service-role tick RPCs, and dispatches hunger alert notifications.

## Read More
- Exact schema/policy/function body: Supabase MCP plus `supabase/migrations/`.
- Historical schema notes: `memory-bank/archive/database_schema_20260418_pre_compaction.md`.
