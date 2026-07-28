# Database Schema

Compact current-state watchlist. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/database_schema_20260724_pre_compaction.md`.
Target Supabase project: `ilxzpszgirhwxpeocygs`.

Before a DB claim/change, verify the target and inspect the latest applied
migration that rewrites the object.

## Core Areas
- Identity/devices: `profiles`, `device_tokens`
- Rooms/pets/chat: membership/invites, `pets`, `room_extra_pets`,
  `pet_state`, `room_pet_state`, hunger schedule, messages/reactions
- Economy/shared room: items, decor/equipment inventories, purchases,
  subscriptions, ledgers, `pet_equipment`
- Config/safety: `app_config`, reports/blocks, notification logs, debug
  overrides, room cleanup review

## Current Contracts
- Normal sharing uses invite-code RPCs; `rooms.invite_code` is legacy.
- `pets.room_id` remains unique for old clients. Extras use
  `room_extra_pets`; `rooms.main_pet_id` identifies the canonical pet and
  `rooms.name` mirrors its name.
- `room_pet_state` is shared hunger/mood/level/exp truth; `pet_state` mirrors
  the main pet. Successful feed actions anchor decay at feed time; rejected
  overfed/cooldown actions do not.
- `pet_equipment.pet_id` may reference either pet table; RLS/RPC validation
  must cover both.
- `items.metadata` carries item compatibility: visibility, minimum version,
  shop visibility, fallback/assets, and slots.
- Furniture uses nullable fixed-canvas center fractions and dual-writes legacy
  positions.
- Pet tickets are v2-gated additive consumables. New purchases use
  `purchase_and_use_pet_ticket(...)`; owned tickets use `use_pet_ticket(...)`.
- Message senders may be null for system events. Image-feed recall clears media
  without reversing rewards.
- `pet_hunger_tick_schedule.next_check_at` is the server due cursor;
  admin-only hunger pause lives in `room_debug_overrides`.

## Compatibility Rules
- Public PostgREST objects need explicit Data API grants; RLS remains the
  boundary.
- Legacy catalogs see active items only. Version-gated decor stays inactive and
  uses `get_visible_shop_items(p_app_version)`.
- Hidden rollout decor uses `metadata.shop_visibility = 'hidden'`; catalog
  RPCs, purchase predicates, and RLS write policies must agree.
- Prefer additive fields/RPCs/optional params. Keep legacy 4-arg furniture RPCs
  separate from non-defaulted 6-arg canvas overloads.

## RPC Watchlist
- Room lifecycle: create/join/invite/leave/regenerate RPCs
- Pet/gameplay: `apply_pet_action`, reward/tick/schedule, room-pet, pet-ticket,
  and equipment RPCs
- Shop/decor: visible catalog, purchase/grant, inventory, and furniture helpers
- Chat/unread: edit/delete message and unread-count RPCs
- Home summaries: `get_room_latest_feeds(...)` and
  `get_room_member_counts(...)` are additive invoker RPCs; old clients read
  tables directly.
- Status: `get_effective_room_pet_statuses(uuid[])` is authenticated-only,
  read-only, and `SECURITY INVOKER`; it projects requested active-member rooms
  from one server timestamp without changing old tick/state contracts.

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use
  `(select auth.uid())`, `TO authenticated`, and matching indexes.
- `feed_validate`/`avatar_upload` validate image size and MIME before R2.
- `notify_friend` canonicalizes DB payloads and limits recipients to active
  room members.
- `hunger_tick_dispatch` processes due schedules and dispatches alerts.
- Room-photo cleanup is human-reviewed and fail-closed; see
  `docs/abandoned_room_cleanup.md`.

## Read More
- Schema truth: Supabase MCP plus `supabase/migrations/`
- Release/deployments: `docs/release_status.md`
- History: `memory-bank/archive/`
