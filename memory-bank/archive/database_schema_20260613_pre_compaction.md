# Database Schema

Compact map only. Full snapshots live in `memory-bank/archive/`; latest:
`memory-bank/archive/database_schema_20260606_pre_compaction.md`.
Repo target Supabase project: `ilxzpszgirhwxpeocygs`.

Before any DB claim/change, confirm the live target and inspect the latest
applied migration that rewrites the object.

## Core Tables
- Identity/devices: `profiles`, `device_tokens`
- Rooms/pets/chat: `rooms`, `room_invite_codes`, `room_members`, `pets`,
  `room_extra_pets`, `pet_state`, `room_pet_state`,
  `pet_hunger_tick_schedule`, `messages`, `message_reactions`
- Economy/shared room: `items`, room/background/furniture inventories,
  purchases, subscriptions, ledgers, `pet_equipment`
- Config/safety: `app_config`, `reports`, `blocks`,
  `notification_delivery_logs`, `room_debug_overrides`
- R2 cleanup: `room_cleanup_candidates` (review queue), `room_cleanup_review`
  (admin view; not exposed to anon/authenticated)

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- `rooms.invite_code` is legacy; normal sharing reuses
  `get_or_create_room_invite_code(...)`.
- `rooms.main_pet_id` points at the canonical main pet in `pets`; extra pets
  live in `room_extra_pets` and only surface through v2.0.0 room-pet RPCs.
  Keep `pets.room_id` unique for legacy clients.
- `room_pet_state` is the shared room hunger/mood/level/exp source of truth;
  `pet_state` mirrors the main pet for compatibility. Passive decay and legacy
  actions must write both.
- `apply_pet_action(feed)` anchors `last_decay_at` to the successful feed time
  in both `pet_state` and `room_pet_state`; overfed/cooldown feeds do not reset
  passive decay.
- `room_extra_pets` mirrors `pets` without `room_id` uniqueness, is RLS-scoped
  to active room members, and is in Realtime.
- `rooms.name` mirrors the main pet's name. `sync_main_pet_name_to_room` and
  `set_room_main_pet` keep it populated for legacy clients.
- `room_debug_overrides` stores admin-only room debug switches. Current switch:
  `hunger_decay_paused_until`, mutated through
  `set_room_hunger_decay_paused(...)`.
- `pet_equipment.pet_id` can reference either `pets.id` or
  `room_extra_pets.id`; RLS/RPC checks must validate against both. It stores
  one equipped item per `(room_id, pet_id, slot)` for `head`, `face`, `body`,
  and `back`; room equipment quantity is capped by combined room pet count.
- `items.metadata` is the compatibility contract for decor/equipment:
  `visibility_mode`, `min_app_version`, `shop_visibility`, fallback, assets,
  and slots.
- `room_furniture.canvas_position_x/y` are nullable fixed-canvas center
  fractions. New clients dual-write them plus legacy `position_x/y`; live RPC
  compatibility depends on keeping 4-arg legacy furniture RPCs and 6-arg canvas
  overloads without defaulted args.
- `pet_ticket` is a v2.0.0 version-gated 150-diamond consumable. New purchases
  call `purchase_and_use_pet_ticket(...)`; already-owned tickets use
  `use_pet_ticket(...)`.
- `messages.sender_id` can be null for room-wide system events. Sender
  soft-delete supports own `text` or `image_feed`; image-feed recall nulls
  `image_url`/`caption` and does not reverse feed rewards.
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
  `set_room_hunger_decay_paused`, `claim_feed_double_reward`, room-pet RPCs,
  pet-ticket RPCs, equipment equip/get RPCs
- Shop/equipment/furniture: `get_visible_shop_items`, purchase/grant RPCs,
  inventory helpers, furniture transform helpers
- Chat/unread: `edit_message`, `delete_message`, unread-count RPCs
- Home summaries (additive, `SECURITY INVOKER`, `authenticated`-only):
  `get_room_latest_feeds(p_room_ids, p_per_room_limit)` (per-room top-N feeds,
  fixes global-LIMIT starvation), `get_room_member_counts(p_room_ids)`. New
  clients call these; old clients still read `messages`/`room_members` directly.

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
  `rooms.last_activity_at` is trigger-maintained; `rooms.status` is
  `active`/`abandoned`.
- `cleanup_abandoned_rooms` is verify-jwt-off and human-in-the-loop: `scan`
  records stale rooms as pending candidates; Studio approval sets
  `review_status=approved`; `purge` deletes R2 photos only when the approved
  candidate still matches the stale room/R2 scan snapshot. New room activity
  resets approved candidates back to pending. See
  `docs/abandoned_room_cleanup.md`.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Historical snapshots: `memory-bank/archive/`
