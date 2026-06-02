-- Harden the server-side hunger tick scheduler (no notification-policy change).
--
-- Background: hunger alerts are one-shot per threshold crossing (50/30/10) and
-- pets at hunger <= 10 correctly drop out of pet_hunger_tick_schedule
-- (compute_pet_hunger_next_check_at returns NULL). That is intended.
--
-- The reliability risk is drift: a pet that *should* still be scheduled
-- (active, non-archived room, hunger > 10) can end up with a stale or NULL
-- next_check_at and then be invisible to the every-20m cron, which only selects
-- next_check_at <= now(). There is currently no server-side recovery for that
-- (it only self-heals when a client updates pet_state). Pause windows
-- (room_debug_overrides.hunger_decay_paused_until) also don't refresh the
-- schedule when changed, so lifting a pause isn't reflected until a client tick.
--
-- This migration adds:
--   1) a periodic safety-net resweep that recomputes schedules for all eligible
--      pets (idempotent; terminal pets still resolve to NULL),
--   2) an event-driven refresh when a room's pause window changes.

-- 1) Safety-net resweep ------------------------------------------------------
create or replace function public.resweep_pet_hunger_schedules(p_limit integer default 5000)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  r record;
begin
  for r in
    select p.id as pet_id
    from public.pets p
    join public.rooms rm on rm.id = p.room_id
    where not rm.is_archived
      and exists (
        select 1 from public.room_members m
        where m.room_id = p.room_id and m.is_active = true
      )
    limit p_limit
  loop
    -- Recompute next_check_at from current state. Idempotent: deterministic from
    -- last_decay_at + hunger, so re-running does not move correctly-scheduled
    -- pets, heals orphans (hunger > 10 but NULL), and refreshes after un-pause.
    perform public.refresh_pet_hunger_tick_schedule(r.pet_id, now());
    v_count := v_count + 1;
  end loop;
  return v_count;
end
$$;

revoke all on function public.resweep_pet_hunger_schedules(integer)
  from public, anon, authenticated;
grant execute on function public.resweep_pet_hunger_schedules(integer) to service_role;

-- 2) Refresh schedule when a room's pause window changes ---------------------
create or replace function public.handle_room_pause_schedule_refresh()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.refresh_pet_hunger_tick_schedule(p.id, now())
  from public.pets p
  where p.room_id = coalesce(new.room_id, old.room_id);
  return coalesce(new, old);
end
$$;

drop trigger if exists trg_room_pause_refresh_hunger_schedule on room_debug_overrides;
create trigger trg_room_pause_refresh_hunger_schedule
after insert or update of hunger_decay_paused_until on room_debug_overrides
for each row execute function public.handle_room_pause_schedule_refresh();

-- 3) Hourly safety-net cron --------------------------------------------------
do $$
declare
  v_jobname text := 'resweep_pet_hunger_schedules_hourly';
begin
  perform cron.unschedule(jobid) from cron.job where jobname = v_jobname;
  perform cron.schedule(
    v_jobname,
    '5 * * * *',
    $cmd$ select public.resweep_pet_hunger_schedules(); $cmd$
  );
end
$$;

-- 4) Run one immediate sweep to heal any current drift ----------------------
select public.resweep_pet_hunger_schedules();
