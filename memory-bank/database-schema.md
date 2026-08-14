# Database Schema

Compact current-state watchlist. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/database_schema_20260811_pre_compaction.md`.
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
  overrides, cleanup review

## Current Contracts
- Invite-code RPCs are reusable and default first-party creation/regeneration
  to 24 hours; successful joins do not consume codes or impose a user cap.
- `pets.room_id` stays unique for old clients. Extras use
  `room_extra_pets`; `rooms.main_pet_id` identifies the canonical pet and
  `rooms.name` mirrors its name.
- `room_pet_state` is shared stat truth; `pet_state` mirrors the main pet.
  Successful feed actions anchor decay at feed time; rejected feeds do not.
- `pet_equipment.pet_id` may reference either pet table; RLS/RPC validation
  must cover both.
- `items.metadata` carries compatibility, visibility, asset/fallback, and slot
  rules. Furniture uses nullable canvas center fractions and dual-writes legacy
  positions.
- Pet tickets are additive and v2-gated. New purchases use
  `purchase_and_use_pet_ticket(...)`; owned tickets use `use_pet_ticket(...)`.
- Message senders may be null for system events. Image-feed recall clears media
  without reversing rewards.
- `pet_hunger_tick_schedule.next_check_at` is the due cursor; hunger pause
  state lives in `room_debug_overrides`.
- Internal schedule/cleanup tables have RLS enabled with no client policies;
  client grants remain denied while service roles retain access.
- Timezone-aware functions use `public.normalize_timezone(text)`; do not
  reintroduce executable `pg_timezone_names` scans.

## Compatibility And Additive RPCs
- Public PostgREST objects need explicit Data API grants; RLS remains the
  boundary.
- Legacy catalogs see active items only. Version-gated/hidden decor must keep
  catalog RPCs, purchase predicates, and RLS write policies aligned.
- Prefer additive fields/RPCs/optional params. Keep legacy 4-arg furniture RPCs
  separate from non-defaulted 6-arg overloads.
- `get_room_latest_feeds(...)`, `get_room_member_counts(...)`, and
  `get_effective_room_pet_statuses(uuid[])` are additive invoker RPCs.
- `register_device_token(text,text,text)` is the authenticated definer-rights
  reassignment path; old clients retain direct upsert. Rate-limit callers if
  token-knowledge-based reassignment becomes an abuse vector.
- Pet names validate through `public.validate_pet_name(text)`, whose limit comes
  from `public.pet_name_max_length()` (12). Both `update_pet_name(...)` and
  `set_initial_pet_name(...)` call it; do not re-spell the rule in a caller.
  `set_initial_pet_name` exists because `update_pet_name` posts a "renamed"
  system message, and only accepts pets that have no name yet, so it cannot be
  used as a rename that skips that message. Resending the same name is a no-op.
  Caveat: `pets`' UPDATE policy still lets any room member write the column
  directly, so these RPCs are the app's path, not a hard boundary — a CHECK
  constraint would close it but would reject every future update to the one row
  already over the limit. Old clients cap renames at 20 or not at all, so they
  now see `name_too_long`.

## RLS And Edge Notes
- Scope room/user data through active `room_members`; use
  `(select auth.uid())`, `TO authenticated`, and matching indexes.
- Function truth lives in `supabase/functions/`; feed/R2 behavior is in
  `docs/feed_upload_pipeline.md`.
- Room-photo cleanup remains human-reviewed and fail-closed; see
  `docs/abandoned_room_cleanup.md`.

## Read More
- Schema truth: Supabase MCP plus `supabase/migrations/`
- Release/deployments: `docs/release_status.md`
- History: `memory-bank/archive/`
