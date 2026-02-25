begin;

create table if not exists public.pet_hunger_tick_schedule (
  pet_id uuid primary key references public.pets(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  next_check_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists pet_hunger_tick_schedule_next_check_idx
  on public.pet_hunger_tick_schedule (next_check_at)
  where next_check_at is not null;

revoke all on table public.pet_hunger_tick_schedule from public, anon, authenticated;
grant select, insert, update, delete on table public.pet_hunger_tick_schedule to service_role;

create or replace function public.compute_pet_hunger_next_check_at(
  p_pet_id uuid,
  p_now timestamptz default now()
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hunger int;
  v_last_decay_at timestamptz;
  v_poop_at timestamptz;
  v_mood_boost int;
  v_mood_boost_expires_at timestamptz;
  v_timezone text;
  v_local_hour int;
  v_is_night boolean := false;
  v_effective_mood text;
  v_decay_rate numeric := 3;
  v_target_hunger int;
  v_points_to_target int;
  v_threshold_at timestamptz;
begin
  select ps.hunger,
         ps.last_decay_at,
         ps.poop_at,
         ps.mood_boost,
         ps.mood_boost_expires_at,
         coalesce(r.timezone, 'UTC')
  into v_hunger,
       v_last_decay_at,
       v_poop_at,
       v_mood_boost,
       v_mood_boost_expires_at,
       v_timezone
  from public.pet_state ps
  join public.pets p on p.id = ps.pet_id
  join public.rooms r on r.id = p.room_id
  where ps.pet_id = p_pet_id
    and not r.is_archived
    and exists (
      select 1
      from public.room_members rm
      where rm.room_id = p.room_id
        and rm.is_active = true
    );

  if not found then
    return null;
  end if;

  if v_hunger is null or v_hunger <= 10 then
    return null;
  end if;

  if v_last_decay_at is null then
    return p_now;
  end if;

  if v_mood_boost_expires_at is not null and v_mood_boost_expires_at <= p_now then
    v_mood_boost := 0;
  end if;

  select ptn.name
  into v_timezone
  from pg_timezone_names ptn
  where ptn.name = coalesce(v_timezone, 'UTC')
  limit 1;

  if v_timezone is null then
    v_timezone := 'UTC';
  end if;

  v_local_hour := extract(hour from (p_now at time zone v_timezone));
  if v_local_hour between 0 and 7 then
    v_is_night := true;
  end if;

  v_effective_mood := public.compute_pet_mood(
    v_hunger,
    v_poop_at,
    p_now,
    v_is_night,
    coalesce(v_mood_boost, 0)
  );

  v_decay_rate := case v_effective_mood
    when 'high' then 2
    when 'sad' then 4
    else 3
  end;

  if v_is_night then
    v_decay_rate := v_decay_rate * 0.5;
  end if;

  if v_decay_rate <= 0 then
    return p_now + interval '20 minutes';
  end if;

  v_target_hunger := case
    when v_hunger > 50 then 50
    when v_hunger > 30 then 30
    when v_hunger > 10 then 10
    else null
  end;

  if v_target_hunger is null then
    return null;
  end if;

  v_points_to_target := greatest(1, v_hunger - v_target_hunger);
  v_threshold_at := v_last_decay_at
    + make_interval(secs => ceil((v_points_to_target / v_decay_rate) * 3600.0)::int);

  if v_threshold_at < p_now then
    v_threshold_at := p_now;
  end if;

  return greatest(v_threshold_at, p_now + interval '20 minutes');
end;
$$;

revoke all on function public.compute_pet_hunger_next_check_at(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.compute_pet_hunger_next_check_at(uuid, timestamptz)
  to service_role;

create or replace function public.refresh_pet_hunger_tick_schedule(
  p_pet_id uuid,
  p_now timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_next_check_at timestamptz;
begin
  select p.room_id
  into v_room_id
  from public.pets p
  where p.id = p_pet_id;

  if v_room_id is null then
    delete from public.pet_hunger_tick_schedule where pet_id = p_pet_id;
    return;
  end if;

  v_next_check_at := public.compute_pet_hunger_next_check_at(p_pet_id, p_now);

  insert into public.pet_hunger_tick_schedule (
    pet_id,
    room_id,
    next_check_at,
    created_at,
    updated_at
  ) values (
    p_pet_id,
    v_room_id,
    v_next_check_at,
    p_now,
    p_now
  )
  on conflict (pet_id) do update
  set room_id = excluded.room_id,
      next_check_at = excluded.next_check_at,
      updated_at = p_now;
end;
$$;

revoke all on function public.refresh_pet_hunger_tick_schedule(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.refresh_pet_hunger_tick_schedule(uuid, timestamptz)
  to service_role;

create or replace function public.handle_pet_hunger_tick_schedule()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.refresh_pet_hunger_tick_schedule(new.pet_id, now());
  return new;
end;
$$;

drop trigger if exists after_pet_state_hunger_tick_schedule on public.pet_state;
create trigger after_pet_state_hunger_tick_schedule
after insert or update of hunger, last_decay_at, poop_at, mood_boost, mood_boost_expires_at
on public.pet_state
for each row
execute function public.handle_pet_hunger_tick_schedule();

create or replace function public.handle_pet_hunger_tick_schedule_from_pets()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.refresh_pet_hunger_tick_schedule(new.id, now());
  return new;
end;
$$;

drop trigger if exists after_pets_hunger_tick_schedule on public.pets;
create trigger after_pets_hunger_tick_schedule
after insert or update of room_id
on public.pets
for each row
execute function public.handle_pet_hunger_tick_schedule_from_pets();

create or replace function public.tick_pet_state_as_system(
  p_pet_id uuid,
  p_now timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
begin
  select rm.user_id
  into v_actor_id
  from public.pets p
  join public.room_members rm
    on rm.room_id = p.room_id
   and rm.is_active = true
  where p.id = p_pet_id
  order by case when rm.role = 'owner' then 0 else 1 end,
           rm.joined_at asc
  limit 1;

  if v_actor_id is null then
    perform public.refresh_pet_hunger_tick_schedule(p_pet_id, p_now);
    return;
  end if;

  perform set_config('request.jwt.claim.sub', v_actor_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform public.tick_pet_state(p_pet_id, p_now);
  perform public.refresh_pet_hunger_tick_schedule(p_pet_id, p_now);
end;
$$;

revoke all on function public.tick_pet_state_as_system(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.tick_pet_state_as_system(uuid, timestamptz)
  to service_role;

insert into public.pet_hunger_tick_schedule (
  pet_id,
  room_id,
  next_check_at,
  created_at,
  updated_at
)
select p.id,
       p.room_id,
       public.compute_pet_hunger_next_check_at(p.id, now()),
       now(),
       now()
from public.pets p
join public.pet_state ps on ps.pet_id = p.id
on conflict (pet_id) do update
set room_id = excluded.room_id,
    next_check_at = excluded.next_check_at,
    updated_at = now();

do $$
declare
  v_jobname text := 'hunger_tick_dispatch_every_20m';
begin
  perform cron.unschedule(jobid)
  from cron.job
  where jobname in ('hunger_tick_dispatch_every_10m', 'hunger_tick_dispatch_every_20m');

  perform cron.schedule(
    v_jobname,
    '*/20 * * * *',
    $cmd$
    select net.http_post(
      url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/hunger_tick_dispatch',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          select decrypted_secret
          from vault.decrypted_secrets
          where name = 'hunger_tick_secret'
          limit 1
        )
      ),
      body := '{"source":"pg_cron"}'::jsonb
    );
    $cmd$
  );
end
$$;

commit;
