# Database Schema

Compact current-state watchlist. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/database_schema_20260818_pre_compaction.md`.
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
- `room_frame_state(room_id, style, updated_at)` is additive shared casing
  state: member-only RLS, explicit SELECT/INSERT/UPDATE grants, no client delete
  or timestamp writes. Invoker trigger enforces levels 1/1/3/5/8, immutable
  room ids, and grandfathered shared casings (including upserts); server owns
  timestamps. Published to Realtime; existing RPCs/catalogs are unchanged.
- Invite-code RPCs are reusable and default first-party creation/regeneration
  to 24 hours; successful joins do not consume codes or impose a user cap.
- `pets.room_id` stays unique for old clients. Extras use
  `room_extra_pets`; `rooms.main_pet_id` identifies the canonical pet and
  `rooms.name` mirrors its name.
- `room_pet_state` is shared stat truth; `pet_state` mirrors the main pet.
  Every feed adds +25 hunger (capped at 100) and anchors decay at feed time;
  there is no 10-minute burst/overfed gate since `20260924120000`, so
  `last_overfed_at` is no longer stamped. The feed coin/exp reward keeps its
  separate 10-minute cooldown in `claim_action_reward`.
- `pet_equipment.pet_id` may reference either pet table; RLS/RPC validation
  must cover both.
- `items.metadata` carries compatibility, visibility, asset/fallback, and slot
  rules. Furniture uses nullable canvas center fractions and dual-writes legacy
  positions.
- Pet tickets are additive and v2-gated. New purchases use
  `purchase_and_use_pet_ticket(...)`; owned tickets use `use_pet_ticket(...)`.
- Message senders may be null for system events. Image-feed recall clears media
  without reversing rewards. `edit_message` covers `text` and `image_feed`: the
  edited text writes to `body` for text and to `caption` for a photo, and
  stamps `edited_at` either way.
- `pet_hunger_tick_schedule.next_check_at` is the due cursor; hunger pause
  state lives in `room_debug_overrides`.
- Internal schedule/cleanup tables have RLS enabled with no client policies;
  client grants remain denied while service roles retain access.
- Timezone-aware functions use `public.normalize_timezone(text)`; do not
  reintroduce executable `pg_timezone_names` scans.
- `support_messages` (since `20260926120000`) is one support thread per user.
  Clients may only SELECT their own rows and INSERT `(body, meta)`;
  `user_id`/`sender` come from defaults, so a client cannot fake an admin reply.
  A rate-limit trigger allows 20 user messages/hour. Admin replies are inserted
  from the dashboard with `sender = 'admin'`. An AFTER INSERT trigger sends
  `{id}` through pg_net to `support_notify` (verify_jwt off, bearer is vault
  `support_notify_secret` = env `SUPPORT_NOTIFY_SECRET`). User rows are emailed
  via Resend (`RESEND_API_KEY`, `SUPPORT_EMAIL`), and admin rows go out as FCM
  push with `type = support_reply` and no `room_id`.

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
  `set_initial_pet_name(...)` call it; do not re-spell the rule in callers.
  Initial naming avoids the rename system event and same-name retries are
  no-ops. The app uses these RPCs, but the existing `pets` UPDATE policy is not
  a hard DB boundary; a CHECK remains blocked by one legacy over-limit row.
  Older clients may surface `name_too_long`.

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
