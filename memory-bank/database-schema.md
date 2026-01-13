# Database Schema (Draft)

## Overview
This draft is for Supabase (Postgres) and assumes room-scoped access with strict RLS. Naming follows snake_case and UTC timestamps.

## Core Tables
- `profiles`
  - `user_id` (uuid, pk, references auth.users)
  - `nickname` (text), `avatar_url` (text)
  - `locale` (text), `timezone` (text)
  - `coins` (int, default 0)
  - `created_at`, `updated_at`

- `rooms`
  - `id` (uuid, pk)
  - `name` (text)
  - `invite_code` (text, unique)
  - `invite_expires_at` (timestamptz)
  - `created_by` (uuid, current owner; updated on transfer)
  - `created_at`, `updated_at`, `is_archived` (bool)

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
  - `level` (int), `days_alive` (int), `scale` (numeric)
  - `created_at`, `updated_at`

- `pet_state`
  - `pet_id` (uuid, pk, fk)
  - `hunger` (int), `mood` (text), `hygiene` (int)
  - `poop_at` (timestamptz)
  - `last_decay_at` (timestamptz)
  - `last_feed_at`, `last_touch_at`, `last_clean_at` (timestamptz)

- `messages`
  - `id` (uuid, pk)
  - `room_id` (uuid, fk)
  - `sender_id` (uuid, nullable for system)
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
  - `action_type` (text: feed/touch/clean/ad_reward)
  - `last_reward_at` (timestamptz)
  - unique (`user_id`, `action_type`)

## Economy & Monetization
- `coin_ledger`
  - `id` (uuid, pk)
  - `user_id` (uuid, fk)
  - `room_id` (uuid, fk, nullable)
  - `source` (text: feed/touch/clean/ad_reward/quest)
  - `amount` (int)
  - `metadata` (jsonb)
  - `created_at`

- `items` (cosmetics/consumables)
  - `id` (uuid, pk)
  - `sku` (text, unique)
  - `type` (text: cosmetic/consumable)
  - `name` (text)
  - `price_coins` (int), `price_usd` (numeric)
  - `metadata` (jsonb), `is_active` (bool)

- `inventories`
  - `user_id` (uuid, fk)
  - `item_id` (uuid, fk)
  - `quantity` (int)
  - `updated_at`

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
Apply the same pattern to `purchases`, `subscriptions`, `action_cooldowns`, and `coin_ledger`.

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
- `create_room(name text)` -> creates room, owner membership, and invite code.
- `join_room_by_code(code text)` -> validates invite, inserts into `room_members`.
- `leave_room(room_id uuid)` -> sets membership inactive and triggers owner transfer if needed.
- `regenerate_invite_code(room_id uuid)` -> owner-only refresh for invite code + expiry.
- `apply_pet_action(pet_id uuid, action_type text)` -> updates pet_state, mood cooldowns, system messages.
- `claim_action_reward(action_type text, room_id uuid)` -> checks `action_cooldowns`, updates coins + ledger.
- `tick_pet_state(pet_id uuid, now_ts timestamptz)` -> applies decay with night mode using member timezone.

## Ownership Transfer
- Trigger `ensure_room_owner` promotes the oldest active member if no active owner exists.

## Edge Functions
- `feed_validate`: accept image + labels, map labels, validate quest, upload to R2, write message + rewards.
- `notify_friend`: on feed event, push notification to room partner.

## Seed Data
See `memory-bank/label-mapping.md` for initial `label_mappings` and `quests` entries.
