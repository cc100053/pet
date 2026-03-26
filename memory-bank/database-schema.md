# Database Schema (Draft)

## Overview
This draft is for Supabase (Postgres) and assumes room-scoped access with strict RLS. Naming follows snake_case and UTC timestamps.

## Core Tables
- `profiles`
  - `user_id` (uuid, pk, references auth.users)
  - `nickname` (text), `avatar_url` (text; either `preset:<id>` or a remote URL)
  - `locale` (text), `timezone` (text)
  - `coins` (int, default 0)
  - `diamonds` (int, default 0)
  - `created_at`, `updated_at`

- `device_tokens`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk; non-unique for multi-device support)
  - `token` (text, unique)
  - `platform` (text)
  - `last_seen_at`, `created_at`, `updated_at`

- `rooms`
  - `id` (uuid, pk)
  - `name` (text)
  - `timezone` (text; room-scoped timezone for shared pet night-mode logic)
  - `invite_code` (text, unique; legacy/current primary code for backward compatibility)
  - `invite_expires_at` (timestamptz)
  - `created_by` (uuid, current owner; updated on transfer)
  - `created_at`, `updated_at`, `is_archived` (bool)

- `room_invite_codes`
  - `id` (uuid, pk)
  - `room_id` (uuid, fk -> rooms.id)
  - `code` (text, unique, 6-digit format)
  - `created_by` (uuid, nullable fk -> auth.users; legacy backfill compatible)
  - `created_at` (timestamptz)
  - `expires_at` (timestamptz)
  - `revoked_at` (timestamptz, nullable)
  - `revoked_by` (uuid, nullable fk -> auth.users)
  - Notes:
    - Keep up to 3 active codes per room.
    - `rooms.invite_code` remains as current primary code for old client compatibility.

- `room_members`
  - `room_id` (uuid, fk)
  - `user_id` (uuid, fk)
  - `role` (text: owner/member)
  - `joined_at`, `left_at`, `is_active` (bool)
  - unique (`room_id`, `user_id`)
  - constraint: only one active owner per room (partial unique index)

- `pets`
  - `id` (uuid, pk)
  - `room_id` (uuid, unique)
  - `name` (text), `color_dna` (jsonb)
  - `stage` (text: egg/hatched)
  - `level` (int), `exp` (int; remainder toward next level), `days_alive` (int), `scale` (numeric)
  - `created_at`, `updated_at`

- `pet_state`
  - `pet_id` (uuid, pk, fk)
  - `hunger` (int), `mood` (text: `mid`/`high`/`sad`), `hygiene` (int)
  - `poop_at` (timestamptz)
  - `poop_count` (int, 0-3), `poop_positions` (jsonb, array of {x, y})
  - `last_poop_spawn_at` (timestamptz; reset on clean to now; next spawn after 8 hours)
  - `mood_boost` (int), `mood_boost_expires_at` (timestamptz)
  - `feed_burst_count` (int; successful feed count in the current 10-minute window, capped to 1 by rule)
  - `feed_burst_started_at` (timestamptz; start of burst window)
  - `last_overfed_at` (timestamptz; last time overfed message triggered)
  - `feed_count_since_poop` (int)
  - `last_decay_at` (timestamptz)
  - `last_feed_at`, `last_touch_at`, `last_clean_at` (timestamptz)
  - `last_feed_boost_at`, `last_touch_boost_at`, `last_clean_boost_at` (timestamptz)
  - `hunger_alert_50_sent_at`, `hunger_alert_30_sent_at`, `hunger_alert_10_sent_at` (timestamptz; one-time reminder markers)
  - `hunger_alert_50_message_id`, `hunger_alert_30_message_id`, `hunger_alert_10_message_id` (uuid, fk -> `messages.id`)
  - `hunger_alert_50_triggered_by`, `hunger_alert_30_triggered_by`, `hunger_alert_10_triggered_by` (uuid, fk -> `auth.users`)

- `pet_hunger_tick_schedule`
  - `pet_id` (uuid, pk, fk -> `pets.id`)
  - `room_id` (uuid, fk -> `rooms.id`)
  - `next_check_at` (timestamptz, nullable; due-time cursor for server hunger dispatch)
  - `created_at`, `updated_at`
  - indexes: partial btree on `next_check_at` where not null, btree on `room_id`

- `messages`
  - `id` (uuid, pk)
  - `room_id` (uuid, fk)
  - `sender_id` (uuid, nullable for system)
  - Notes:
    - Hunger/store and other room-wide system events may still use `null`.
    - New `clean_poop` system messages now store the acting user id so unread calculations can exclude the actor.
  - `reply_to_message_id` (uuid, nullable fk -> `messages.id`; `on delete set null`)
  - `type` (text: text/image_feed/system)
  - `body` (text)
  - `image_url` (text), `caption` (text)
  - `labels` (jsonb)
  - `coins_awarded` (int), `mood_delta` (int)
  - `created_at`, `client_created_at`

## Gameplay Support Tables
- `label_mappings`
  - `id` (uuid, pk)
  - `label_en` (text)
  - `canonical_tag` (text)
  - `locale` (text)
  - `label_local` (text)
  - `synonyms` (text[])
  - `priority` (int)

- `quests`
  - `id` (uuid, pk)
  - `code` (text, unique)
  - `name` (text)
  - `name_zh` (text), `name_ja` (text)
  - `canonical_tags` (text[])
  - `reward_coins` (int)
  - `is_active` (bool)

- `daily_quests`
  - `id` (uuid, pk)
  - `room_id` (uuid, fk)
  - `quest_id` (uuid, fk)
  - `quest_date` (date)
  - `status` (text: active/claimed/expired)
  - `reward_multiplier` (numeric)

- `action_cooldowns`
  - `user_id` (uuid, fk)
  - `room_id` (uuid, fk)
  - `action_type` (text: feed/touch/clean/ad_reward)
  - `last_reward_at` (timestamptz)
  - unique (`user_id`, `action_type`, `room_id`)

## Economy & Monetization
- `coin_ledger`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk)
  - `room_id` (uuid, fk, nullable)
  - `source` (text: feed/touch/clean/ad_reward/quest/store_purchase/iap_purchase/diamond_exchange)
  - `amount` (int)
  - `metadata` (jsonb)
  - `created_at`

- `diamond_ledger`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk)
  - `room_id` (uuid, fk, nullable)
  - `source` (text: iap_purchase/store_purchase/exchange/admin_adjust)
  - `amount` (int)
  - `metadata` (jsonb)
  - `created_at`

- `items` (cosmetics/consumables)
  - `id` (uuid, pk)
  - `sku` (text, unique)
  - `type` (text: cosmetic/consumable/subscription)
  - `name` (text)
  - `price_coins` (int), `price_diamonds` (int), `price_usd` (numeric)
  - `metadata` (jsonb; optional IAP fields like `iap_product_id`, `iap_type`, `rc_entitlement_id`; background items include `category: background` + `background_key`), `is_active` (bool)

- `inventories`
  - `user_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `quantity` (int)
  - `updated_at`

- `room_item_inventories`
  - `room_id` (uuid, fk)
  - `user_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `quantity` (int)
  - `updated_at`
  - primary key (`room_id`, `user_id`, `item_id`)
  - Notes:
    - Rows remain purchase-attributed per buyer for backward compatibility.
    - New shared room inventory reads should use RPC aggregation (`get_room_furniture_inventory`) instead of direct per-user filtering.

- `room_furniture`
  - `id` (uuid, pk)
  - `room_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `owner_user_id` (uuid, fk)
  - `position_x` (numeric, 0-1 normalized)
  - `position_y` (numeric, 0-1 normalized)
  - `scale` (numeric, 0.8-2.0, default 1.0)
  - `created_at`, `updated_at`

- `room_backgrounds`
  - `room_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `acquired_by` (uuid, fk)
  - `created_at`
  - unique (`room_id`, `item_id`)

- `room_background_state`
  - `room_id` (uuid, pk, fk)
  - `active_item_id` (uuid, fk)
  - `updated_by` (uuid, fk)
  - `updated_at`

## Furniture RPC Notes
- `get_room_furniture_inventory(p_room_id uuid)`
  - Returns room-member-authorized aggregated furniture totals as `{ item_id, total_quantity }`.
- `purchase_room_furniture_with_coins(p_room_id uuid, p_item_id uuid)`
- `purchase_room_furniture_with_diamonds(p_room_id uuid, p_item_id uuid)`
  - Still increment the buyer-attributed `room_item_inventories` row, and now also return `room_total_quantity` for new clients.
- `place_room_furniture(p_room_id uuid, p_item_id uuid, p_position_x numeric, p_position_y numeric)`
  - Placement validation is room-wide: compare summed room inventory vs total placed copies in that room.
- `update_room_furniture_scale(p_id uuid, p_scale numeric)`
  - Room-member-authorized scale update with server-side clamp to `0.8..2.0`.

- `purchases`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `platform` (text)
  - `receipt` (text)
  - `created_at`

- `subscriptions`
  - `user_id` (uuid, pk)
  - `status` (text)
  - `provider` (text)
  - `started_at`, `expires_at`

- `iap_transactions`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk)
  - `product_id` (text)
  - `transaction_id` (text, unique)
  - `created_at`

## Moderation & Config
- `reports`
  - `id` (uuid, pk)
  - `reporter_id` (uuid, fk)
  - `message_id` (uuid, fk)
  - `reason` (text)
  - `created_at`

- `blocks`
  - `blocker_id` (uuid, fk)
  - `blocked_user_id` (uuid, fk)
  - `created_at`

- `app_config`
  - `key` (text, pk)
  - `value` (jsonb)
  - `updated_at`

- `notification_delivery_logs`
  - `id` (uuid, pk)
  - `created_at` (timestamptz)
  - `room_id`, `message_id`, `sender_id`, `recipient_user_id` (text)
  - `token_prefix`, `token_suffix` (text; masked token diagnostics)
  - `platform`, `locale` (text)
  - `payload_type`, `message_kind` (text)
  - `success` (bool), `http_status` (int), `error_text` (text)
  - `provider_response` (jsonb)

## RLS Policy Drafts
Enable RLS on all tables. Use `auth.uid()` and room scoping.

### Rooms
```sql
create policy rooms_select on rooms
for select using (
  exists (select 1 from room_members rm
          where rm.room_id = rooms.id
            and rm.user_id = auth.uid()
            and rm.is_active)
);

create policy rooms_insert on rooms
for insert with check (created_by = auth.uid());
```

### Room Members
Client inserts should be blocked; use RPC to validate invite codes.
```sql
create policy room_members_select on room_members
for select using (
  exists (select 1 from room_members rm
          where rm.room_id = room_members.room_id
            and rm.user_id = auth.uid()
            and rm.is_active)
);
```

### Messages
```sql
create policy messages_select on messages
for select using (
  exists (select 1 from room_members rm
          where rm.room_id = messages.room_id
            and rm.user_id = auth.uid()
            and rm.is_active)
);

create policy messages_insert on messages
for insert with check (
  exists (select 1 from room_members rm
          where rm.room_id = messages.room_id
            and rm.user_id = auth.uid()
            and rm.is_active)
  and (sender_id = auth.uid() or sender_id is null)
);
```

### Pets + Pet State
```sql
create policy pets_select on pets
for select using (
  exists (select 1 from room_members rm
          where rm.room_id = pets.room_id
            and rm.user_id = auth.uid()
            and rm.is_active)
);
```
Updates should go through RPCs to enforce server-side logic.

### Profiles
```sql
create policy profiles_select on profiles
for select using (
  user_id = auth.uid() or
  exists (
    select 1
    from room_members rm1
    join room_members rm2 on rm1.room_id = rm2.room_id
    where rm1.user_id = auth.uid()
      and rm2.user_id = profiles.user_id
      and rm1.is_active
      and rm2.is_active
  )
);

create policy profiles_update on profiles
for update using (user_id = auth.uid());
```

### User-Owned Tables
```sql
create policy inventories_rw on inventories
for all using (user_id = auth.uid())
with check (user_id = auth.uid());
```
Apply the same pattern to `purchases`, `subscriptions`, `action_cooldowns`, `coin_ledger`, and `device_tokens`.

### Public Read Tables (Authenticated)
```sql
create policy label_mappings_read on label_mappings
for select using (auth.role() = 'authenticated');

create policy quests_read on quests
for select using (auth.role() = 'authenticated');
```

## Indexes (Suggested)
- `messages(room_id, created_at desc)`
- `room_members(user_id, room_id)`
- `rooms(invite_code)`
- `room_members(room_id)` where `role='owner'` and `is_active`
- `pets(room_id)`
- `daily_quests(room_id, quest_date)`
- `coin_ledger(user_id, created_at desc)`

## RPC Functions (Postgres)
- `create_room(name text)` -> creates room, owner membership, invite code, and initial pet + pet_state.
- `join_room_by_code(code text)` -> validates invite, inserts into `room_members`.
- `create_room_invite_code(p_room_id uuid, p_expires_in_minutes int default 60)` -> member-capable invite code creation with room-level active-code cap (`<= 3`) and primary-code sync to `rooms`.
- `list_room_invite_codes(p_room_id uuid)` -> returns active invite codes for room members (latest first, max 3).
- `revoke_room_invite_code(p_room_id uuid, p_code text)` -> owner can revoke any code; members can revoke own code.
- `leave_room(room_id uuid)` -> sets membership inactive and triggers owner transfer if needed.
- `regenerate_invite_code(room_id uuid)` -> owner-only helper delegating to multi-code creation path (legacy API compatibility).
- `apply_pet_action(pet_id uuid, action_type text)` -> updates pet_state, mood boosts, cooldowns, and poop counters; feed currently grants +25 hunger and only one successful feed is allowed per 10-minute burst (later feeds trigger overfed state).
- `claim_action_reward(action_type text, room_id uuid)` -> checks `action_cooldowns`, updates coins + ledger; when `action_type='feed'` and the reward is granted, grants pet EXP (+10), levels up with carry (`50 * current_level`), and caps at level 999.
- `purchase_item_with_coins(item_id uuid, quantity int)` -> spends coins, updates inventories, and inserts a ledger entry.
- `purchase_item_with_diamonds(item_id uuid, quantity int)` -> spends diamonds; if `metadata.coin_amount` is set, exchanges diamonds for coins.
- `purchase_room_furniture_with_coins(room_id uuid, item_id uuid)` -> spends coins and adds one furniture unit to room-scoped inventory.
- `purchase_room_furniture_with_diamonds(room_id uuid, item_id uuid)` -> spends diamonds and adds one furniture unit to room-scoped inventory.
- `grant_iap_coins(product_id text, amount int, transaction_id text)` -> idempotent coin grant for IAP consumables.
- `grant_iap_diamonds(product_id text, amount int, transaction_id text)` -> idempotent diamond grant for IAP consumables.
- `get_unread_message_total_for_user(p_user_id uuid)` -> returns total unread chat messages across all active rooms (used for iOS app-icon badge), excluding self-sent and block-hidden sender messages.
- `get_unread_message_counts_for_user(p_user_id uuid)` -> returns unread counts grouped by room (used to restore in-app room/chat badges after relaunch), excluding self-sent and block-hidden sender messages.
- `tick_pet_state(pet_id uuid, now_ts timestamptz)` -> applies decay with night mode, poop penalties, and mood updates using `rooms.timezone` (room-scoped); hunger-threshold system alerts are emitted at `<=50`, `<=30`, and `<=10` once per recovery cycle.

## Ownership Transfer
- Trigger `ensure_room_owner` promotes the oldest active member if no active owner exists, updates `rooms.created_by`, and syncs `rooms.timezone` to the promoted owner's valid profile timezone (falls back to `UTC` when missing/invalid).

## Edge Functions
- `feed_validate`: accept image + labels, map labels, validate quest, upload to R2, write message + rewards.
- `notify_friend`: on feed event, push notification to room partner.

## Seed Data
See `memory-bank/label-mapping.md` for initial `label_mappings` and `quests` entries.
