# Database Schema

This active file is a compact map, not canonical DDL. The full pre-compaction
snapshot is in `memory-bank/archive/database_schema_20260411_pre_compaction.md`.

For schema/RPC work, confirm the live target project and inspect the latest
applied migration that rewrites the relevant object before proposing changes.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

## Core Domain Tables
- Identity and devices: `profiles`, `device_tokens`
- Rooms and membership: `rooms`, `room_invite_codes`, `room_members`
- Pets and state: `pets`, `pet_state`, `pet_hunger_tick_schedule`
- Chat: `messages`, `message_reactions`
- Gameplay: `label_mappings`, `quests`, `daily_quests`, `action_cooldowns`
- Economy: `coin_ledger`, `diamond_ledger`, `items`, `inventories`,
  `room_item_inventories`, `room_furniture`, `room_backgrounds`,
  `room_background_state`, `purchases`, `subscriptions`, `iap_transactions`
- Moderation/config/diagnostics: `reports`, `blocks`, `app_config`,
  `notification_delivery_logs`

## Current Important Fields
- `profiles.avatar_url` supports `preset:<id>` or remote R2 URL; `timezone` is
  synced through `ProfileBootstrapService`.
- `rooms.timezone` drives room-scoped pet night-mode behavior; `rooms.invite_code`
  remains the legacy/current primary code for old-client compatibility.
- `room_invite_codes` supports up to 3 active codes per room; primary-code sync
  keeps legacy clients working.
- `room_members` has one active owner per room and owner transfer when needed.
- `pet_state` stores hunger/mood/hygiene, poop state, action timestamps, feed
  burst tracking, and one-time hunger alert markers/message IDs.
- `pet_hunger_tick_schedule.next_check_at` is the due-time cursor used by the
  scheduled hunger dispatcher.
- `messages.sender_id` may be `null` for room-wide system events, but new
  `clean_poop` system messages store the acting user so unread logic excludes
  the actor.
- `messages.reply_to_message_id` backs chat/photo replies.
- `message_reactions` is one reaction per `(message_id, user_id)`; changing emoji
  overwrites the previous row and realtime refreshes summaries/details.
- `items.metadata` carries catalog contracts, including IAP fields, background
  metadata, furniture `asset_path`, `visibility_mode`, `min_app_version`,
  `shop_visibility`, `fallback_behavior`, and `fallback_background_key`.
- `room_item_inventories` remains buyer-attributed; new shared furniture reads
  must use the aggregated RPC.
- `room_furniture.scale` is clamped to `0.8..2.0`; positions are normalized
  `0..1`.
- `notification_delivery_logs` records masked token diagnostics and per-recipient
  push outcomes.

## Compatibility Contracts
- Public catalog items can still use `items.is_active = true`.
- Version-gated decor should remain `is_active = false` and become visible via
  `get_visible_shop_items(p_app_version)` once `app_version_compare(...)` passes.
- Rollout-only decor hidden from Shop uses `metadata.shop_visibility = 'hidden'`.
- For shop-backed decor, keep three layers aligned in the same change:
  catalog visibility, purchase RPC validation, and table RLS write policy.
- Image-backed bathroom furniture and the 500-candy exchange pack are gated at
  app version `1.1.2`; live rows stay `is_active = false` so legacy catalog
  reads do not expose them.
- Additive/backward-compatible RPCs are preferred over changing existing RPC
  parameters used by old app versions.

## Current RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`,
  `create_room_invite_code`, `list_room_invite_codes`,
  `revoke_room_invite_code`, `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, `tick_pet_state`,
  `claim_feed_double_reward`, `tick_pet_state`, `tick_pet_state_as_system`,
  `refresh_pet_hunger_tick_schedule`
- Shop/economy: `get_visible_shop_items`, `purchase_item_with_coins`,
  `purchase_item_with_diamonds`, `purchase_room_furniture_with_coins`,
  `purchase_room_furniture_with_diamonds`,
  `purchase_room_background_with_coins`,
  `purchase_room_background_with_diamonds`, `grant_iap_coins`,
  `grant_iap_diamonds`
- Furniture: `get_room_furniture_inventory`, `place_room_furniture`,
  `update_room_furniture_transform`, legacy `update_room_furniture_scale` and
  per-field transform helpers
- Unread badges: `get_unread_message_total_for_user`,
  `get_unread_message_counts_for_user`

## RLS And Index Rules
- Enable RLS on user/room data and scope access through active `room_members`.
- Use `(select auth.uid())` in policies where possible to avoid per-row
  re-evaluation.
- Include `TO authenticated` in app-user policies.
- Add indexes for columns used in `WHERE`, `JOIN`, and RLS predicates.
- Room-scoped policy shape:
  `exists (select 1 from room_members rm where rm.room_id = <table>.room_id and rm.user_id = (select auth.uid()) and rm.is_active)`.
- Public read dictionaries (`label_mappings`, `quests`) should be authenticated
  reads only.

## Edge Function Data Notes
- `feed_validate` writes feed messages/rewards and enforces a 10MB decoded-image
  cap plus strict image MIME allow-list before R2 upload.
- `claim_feed_double_reward(p_room_id, p_message_id)` is additive for newer
  clients: it locks the caller-owned feed message, grants an `ad_reward` equal
  to the current feed reward, stores the feed message id in `coin_ledger`
  metadata for dedupe, and updates `messages.coins_awarded` to the doubled
  total.
- `notify_friend` canonicalizes webhook payload content from DB, constrains
  recipients to active room members, and supports client-authenticated
  `store_purchase` pushes.
- `hunger_tick_dispatch` reads due rows from `pet_hunger_tick_schedule`, calls
  service-role pet tick RPCs, and dispatches alert notifications.
- `avatar_upload` enforces the same image cap/MIME allow-list before R2/profile
  update.

## When To Read More
- Exact schema, policy, trigger, or function body: use Supabase MCP plus
  `supabase/migrations/`.
- Historical full schema notes:
  `memory-bank/archive/database_schema_20260411_pre_compaction.md`.
