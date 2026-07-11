# Database Schema

Compact current-state map only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/database_schema_20260621_pre_compaction.md`.
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
- R2 cleanup: `room_cleanup_candidates`; admin-only review view
  `room_cleanup_review`

## Current Contracts
- `profiles.avatar_url` is either `preset:<id>` or an R2 URL.
- Normal room sharing uses invite-code RPCs; `rooms.invite_code` is legacy.
- `pets.room_id` stays unique for legacy clients. Extra pets live in
  `room_extra_pets` and surface through v2+ RPCs.
- `rooms.main_pet_id` points at the canonical pet in `pets`; `rooms.name`
  mirrors that pet's name.
- `room_pet_state` is the room-shared hunger/mood/level/exp source of truth;
  `pet_state` mirrors the main pet for compatibility.
- `apply_pet_action(feed)` anchors successful feed decay at feed time in both
  state tables; overfed/cooldown feeds do not reset passive decay.
- `room_debug_overrides.hunger_decay_paused_until` is admin-only and mutated
  through `set_room_hunger_decay_paused(...)`.
- `pet_equipment.pet_id` may reference `pets.id` or `room_extra_pets.id`; RLS
  and RPC checks must validate both.
- `items.metadata` is the decor/equipment compatibility contract:
  `visibility_mode`, `min_app_version`, `shop_visibility`, fallback/assets, and
  slots.
- `room_furniture.canvas_position_x/y` are nullable fixed-canvas center
  fractions. New clients dual-write them plus legacy `position_x/y`.
- `pet_ticket` is a v2-gated 150-diamond consumable. New purchases call
  `purchase_and_use_pet_ticket(...)`; owned tickets use `use_pet_ticket(...)`.
- `messages.sender_id` can be null for room-wide system events. Image-feed
  recall nulls media fields and does not reverse feed rewards.
- `pet_hunger_tick_schedule.next_check_at` is the server-side hunger due cursor.

## Compatibility Rules
- Public PostgREST objects need explicit Data API grants in migrations; RLS is
  still the boundary.
- Legacy catalog readers only see `items.is_active = true`.
- Version-gated shared decor should stay `is_active = false` and surface
  through `get_visible_shop_items(p_app_version)`.
- Hidden rollout-only decor uses `metadata.shop_visibility = 'hidden'`; keep
  catalog RPCs, purchase predicates, and RLS write policies aligned.
- Prefer additive/optional RPC changes over parameter/signature changes that
  can break old app versions.
- Keep 4-arg legacy furniture RPCs and 6-arg canvas-coordinate overloads
  unambiguous; canvas overloads must not have defaulted args.

## RPC Watchlist
- Room lifecycle: `create_room`, `join_room_by_code`, invite-code RPCs,
  `leave_room`, `regenerate_invite_code`
- Pet/gameplay: `apply_pet_action`, `claim_action_reward`, tick/schedule RPCs,
  room-pet RPCs, pet-ticket RPCs, and equipment equip/get RPCs
- Shop/equipment/furniture: `get_visible_shop_items`, purchase/grant RPCs,
  inventory helpers, furniture transform helpers
- Chat/unread: `edit_message`, `delete_message`, unread-count RPCs
- Home summaries: `get_room_latest_feeds(...)` and
  `get_room_member_counts(...)` are additive `SECURITY INVOKER` RPCs; old
  clients still read tables directly.

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use `(select auth.uid())`,
  `TO authenticated`, and matching indexes in RLS.
- `feed_validate` and `avatar_upload` enforce image size/MIME checks before R2
  writes.
- `notify_friend` canonicalizes payloads from DB and constrains recipients to
  active room members.
- `hunger_tick_dispatch` reads due rows, runs service-role tick RPCs, and sends
  alert notifications.
- Room-photo cleanup is human-in-the-loop and fail-closed; see
  `docs/abandoned_room_cleanup.md`.

## Read More
- Source of truth: Supabase MCP plus `supabase/migrations/`
- Release/backend deployment state: `docs/release_status.md`
- Historical snapshots: `memory-bank/archive/`
