# Hunger Tick Schedule Detailed Report

## Document Info
- Date: 2026-02-25
- Scope: Server-side hunger tick scheduling and push dispatch for closed-app scenarios
- Environment: Supabase Postgres + Edge Functions

## Objective
Ensure hunger notifications are pushed even when no client app is open, while scaling efficiently as pet count grows.

## Why This Was Needed
Previous hunger alert dispatch behavior depended on client-side Home tick execution. If all users closed the app, hunger state updates and push dispatch could stop.

## Implemented Solution Summary
We moved to a server-driven, due-time scheduler model:

1. `pg_cron` triggers `hunger_tick_dispatch` every 20 minutes.
2. `hunger_tick_dispatch` no longer scans all pets.
3. It reads only due pets from `public.pet_hunger_tick_schedule` where `next_check_at <= now()`.
4. It runs `tick_pet_state_as_system` for that due set.
5. Hunger threshold messages (`50/30/10`) are dispatched through `notify_friend` (webhook mode).
6. Duplicate push sends are prevented through `notification_delivery_logs` checks.

## Execution Location
Timer execution is fully server-side:
- Scheduler: Postgres `pg_cron` (`cron.job`)
- Worker endpoint: Supabase Edge Function `hunger_tick_dispatch`
- Tick logic: Postgres RPC `tick_pet_state_as_system`

It is not executed by Flutter app lifecycle.

## Current Cron Configuration
- Job name: `hunger_tick_dispatch_every_20m`
- Cron: `*/20 * * * *`
- Effective runs/day: 72

## Data Model Added
### Table: `public.pet_hunger_tick_schedule`
- `pet_id` (PK, FK -> `pets.id`)
- `room_id` (FK -> `rooms.id`)
- `next_check_at` (`timestamptz`, nullable)
- `created_at`, `updated_at`

### Indexes
- `pet_hunger_tick_schedule_next_check_idx` (partial index on `next_check_at is not null`)
- `pet_hunger_tick_schedule_room_id_idx` (room FK/index coverage)

## DB Functions and Triggers
### `compute_pet_hunger_next_check_at(p_pet_id, p_now)`
Computes the next due time based on current hunger/mood/night-mode decay assumptions and next threshold crossing (`50`, `30`, or `10`).

### `refresh_pet_hunger_tick_schedule(p_pet_id, p_now)`
Upserts schedule state for a pet after relevant state changes.

### `tick_pet_state_as_system(p_pet_id, p_now)`
Runs `tick_pet_state` using a valid active room member auth context and then refreshes due schedule.

### Triggers
- On `pet_state` updates: refresh schedule when hunger/decay/mood-related fields change.
- On `pets` insert or room change: refresh schedule.

## Edge Function Behavior
### `hunger_tick_dispatch`
Input behavior:
- Auth: `Authorization: Bearer <hunger_tick_secret>`
- Tunables: `due_limit`, `tick_concurrency`, `dispatch_concurrency`

Processing behavior:
1. Query due rows from `pet_hunger_tick_schedule`
2. Tick each due pet via `tick_pet_state_as_system`
3. Read generated hunger alert message IDs from `pet_state`
4. Remove already-sent candidates using `notification_delivery_logs`
5. Dispatch remaining alerts via `notify_friend`

## Scaling Characteristics
### Old model
- Work per run proportional to all active pets.

### New model
- Work per run proportional to only due pets.
- Better for growth (e.g., 100 users x up to 4 pets = 400 pets) because non-due pets are skipped.

## Cost/Load Notes
- Base scheduler activity is fixed (72 runs/day).
- Main variable cost is per-run workload:
  - DB reads/writes for due rows only
  - RPC calls for due pets only
  - Push sends only for new alert messages
- This reduces unnecessary scanning and compute vs all-pet polling.

## Applied Migrations
- `20260225023510_add_pet_hunger_tick_schedule_and_20m_cron.sql`
- `20260225024022_add_pet_hunger_tick_schedule_room_id_index.sql`

## Deployment State (at implementation time)
- `hunger_tick_dispatch` deployed ACTIVE as version `5`
- Cron job active: `hunger_tick_dispatch_every_20m`

## Verification Performed
1. Checked cron job exists and is active on `*/20`.
2. Triggered manual `net.http_post` call to `hunger_tick_dispatch`.
3. Confirmed `200` response and due-only processing behavior.
4. Confirmed schedule table has sparse due set (no full scan pattern).
5. Ran project checks:
   - `flutter analyze` (clean)
   - `flutter test` (pass; env-gated integration test skipped as expected)

## Operational Queries
### Check cron job
```sql
select jobname, schedule, active
from cron.job
where jobname like 'hunger_tick_dispatch_every_%';
```

### Check schedule backlog
```sql
select
  count(*) as total_rows,
  count(*) filter (where next_check_at is not null) as scheduled_rows,
  count(*) filter (where next_check_at <= now()) as due_now,
  min(next_check_at) as next_due_at
from public.pet_hunger_tick_schedule;
```

### Trigger one manual run
```sql
select net.http_post(
  url := 'https://<project-ref>.supabase.co/functions/v1/hunger_tick_dispatch',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer ' || (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'hunger_tick_secret'
      limit 1
    )
  ),
  body := '{"source":"manual_verify"}'::jsonb
);
```

## Risks and Considerations
- If the secret in vault is missing or mismatched, scheduler calls fail with `401`.
- If schedule computation assumptions diverge from future tick logic changes, `next_check_at` accuracy may drift and should be reviewed when decay rules change.
- `notify_friend` remains `verify_jwt=false` currently for webhook-mode compatibility; function-level secret/JWT checks are relied on for protection.

## Recommendation for Future Optimization
If pet count grows substantially beyond current target, consider batching due-pet ticking in SQL (set-based RPC) to reduce per-pet RPC overhead further while preserving notification dedupe guarantees.

## Notification Policy (one-shot, by design)
Hunger alerts are **one-shot per threshold crossing**. `handle_pet_hunger_alerts`
(BEFORE UPDATE on `pet_state.hunger`) emits a single `hunger_alert_50/30/10`
system message the moment hunger crosses each threshold downward, then sets
`hunger_alert_<level>_sent_at`; it does not re-send until hunger rises back above
the threshold (which resets the fields). A pet at `hunger <= 10` therefore
correctly drops out of `pet_hunger_tick_schedule`
(`compute_pet_hunger_next_check_at` returns NULL) and stays silent until fed.

Consequence: a pet that is already hungry and left unfed will not be re-notified.
Users only see its hungry state again when they open the app. This is an
intentional product choice (avoid nagging); there is deliberately no recurring
"still hungry" reminder.

## 2026-06 Hardening (safety net, no policy change)
The server-side pipeline was verified healthy (cron dispatches cluster on the
`*/20` minutes 00/20/40). The remaining risk was *schedule drift*: an eligible
pet (active, non-archived room, `hunger > 10`) could end up with a stale/NULL
`next_check_at` and become invisible to the due-only cron, with no server-side
recovery (it self-healed only on a client `pet_state` write). Pause-window
changes (`room_debug_overrides.hunger_decay_paused_until`) also didn't refresh
the schedule.

Migration `20260602130000_harden_hunger_tick_schedule_safety_net.sql` adds:
- `resweep_pet_hunger_schedules()` + hourly cron `resweep_pet_hunger_schedules_hourly`
  (`5 * * * *`): recomputes schedules for all eligible pets. Idempotent
  (deterministic from `last_decay_at`/`hunger`), heals orphans, and refreshes
  after an un-pause. Terminal pets (`hunger <= 10`) still resolve to NULL, so the
  one-shot policy is preserved.
- Trigger `trg_room_pause_refresh_hunger_schedule` on `room_debug_overrides`:
  refreshes a room's pet schedules immediately when its pause window changes.

Note: a far-future `next_check_at` (e.g. 2027) is not a bug when the room has a
matching far-future `hunger_decay_paused_until` — `compute_pet_hunger_next_check_at`
honors the pause. That value is product data and is not altered by this work.

### Verify hardening
```sql
-- orphans should be 0 (eligible but unscheduled)
select count(*) from pets p
join rooms r on r.id=p.room_id
join pet_state ps on ps.pet_id=p.id
left join pet_hunger_tick_schedule s on s.pet_id=p.id
where not r.is_archived and ps.hunger>10
  and exists(select 1 from room_members rm where rm.room_id=p.room_id and rm.is_active)
  and (s.next_check_at is null or s.pet_id is null);

select jobname, schedule, active from cron.job
where jobname='resweep_pet_hunger_schedules_hourly';
```
