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
- `claim_onboarding_reward(p_room_id, p_task)` (since `20261008065402`;
  new-accounts-only since `20261008074506`) is a definer RPC for the
  onboarding checklist. It pays only accounts whose `auth.users.created_at`
  is on/after 2026-10-08 UTC, requires active membership, checks eligibility
  from server data, and returns the coins granted (0 if the account is
  older, the task is not done, or it was already claimed). Amounts are fixed in the function:
  `first_feed` 20, `co_keeper_joined` 50 (someone joined after the caller),
  `first_furniture` 10, `first_chat` 10. Rows land in `coin_ledger` with
  `source = 'onboarding'`, and a partial unique index on
  `(user_id, metadata->>'task')` limits each task to one grant per account.
  `authenticated` only.
- Currency columns are server-only (since `20261008150000` and
  `20261008151000`, run by the owner in the SQL Editor on 2026-10-08, so not
  in `schema_migrations`). Clients cannot write `coin_ledger` at all (no
  INSERT policy, no write grants; SELECT own rows only) and may only INSERT
  `profiles (user_id, nickname, avatar_url, locale, timezone)` and UPDATE
  `profiles (nickname, avatar_url, locale, timezone)`. `coins`/`diamonds`
  change only inside SECURITY DEFINER functions;
  `purchase_room_background_with_coins` became definer for this. A new
  client-writable `profiles` column needs its own column grant.
- `leave_room` is idempotent: leaving without an active membership is a silent
  no-op, and an already-inactive membership keeps its original `left_at`.
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
- `items.metadata.new_until` (ISO 8601, optional) marks a catalog item NEW
  until that instant: gold NEW badge in the shop and the in-room "just arrived"
  popup. Client-only key; set/clear it with a metadata update, no migration.
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
- Timezone-aware functions validate through `public.normalize_timezone(text)`
  or `AT TIME ZONE` with a `22023` fallback; executable `pg_timezone_names`
  scans cost ~0.8s each and are banned from RPCs.
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

## Read More
- Schema truth: Supabase MCP plus `supabase/migrations/`
- Release/deployments: `docs/release_status.md`
- History: `memory-bank/archive/`
