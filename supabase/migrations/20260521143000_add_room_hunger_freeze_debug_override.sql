begin;

create table if not exists public.room_debug_overrides (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  hunger_decay_paused_until timestamptz,
  reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint room_debug_overrides_reason_len
    check (reason is null or char_length(reason) <= 200)
);

alter table public.room_debug_overrides enable row level security;

revoke all on table public.room_debug_overrides from public, anon, authenticated;
grant select, insert, update, delete on table public.room_debug_overrides
  to service_role;

create or replace function public.is_debug_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with claims as (
    select coalesce(auth.jwt(), '{}'::jsonb) as jwt
  )
  select
    lower(coalesce(jwt #>> '{app_metadata,is_admin}', jwt ->> 'is_admin', 'false'))
      in ('true', '1', 'yes')
    or lower(coalesce(jwt #>> '{app_metadata,admin}', jwt ->> 'admin', 'false'))
      in ('true', '1', 'yes')
    or lower(coalesce(jwt #>> '{app_metadata,isAdmin}', jwt ->> 'isAdmin', 'false'))
      in ('true', '1', 'yes')
    or lower(coalesce(jwt #>> '{app_metadata,role}', jwt ->> 'role', '')) = 'admin'
    or lower(coalesce(jwt #>> '{app_metadata,app_role}', jwt ->> 'app_role', '')) = 'admin'
    or lower(coalesce(jwt #>> '{app_metadata,user_role}', jwt ->> 'user_role', '')) = 'admin'
    or exists (
      select 1
      from jsonb_array_elements_text(
        case
          when jsonb_typeof(jwt #> '{app_metadata,roles}') = 'array' then jwt #> '{app_metadata,roles}'
          when jsonb_typeof(jwt -> 'roles') = 'array' then jwt -> 'roles'
          else '[]'::jsonb
        end
      ) as role_entry(value)
      where lower(role_entry.value) = 'admin'
    )
  from claims;
$$;

revoke all on function public.is_debug_admin() from public, anon, authenticated;
grant execute on function public.is_debug_admin() to authenticated;

create or replace function public.set_room_hunger_decay_paused(
  p_room_id uuid,
  p_paused_until timestamptz default null,
  p_reason text default null
)
returns table (
  room_id uuid,
  hunger_decay_paused_until timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  v_main_pet_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_debug_admin() then
    raise exception 'not_debug_admin';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select r.main_pet_id
  into v_main_pet_id
  from public.rooms r
  where r.id = p_room_id
    and not r.is_archived;

  if not found then
    raise exception 'room_not_found';
  end if;

  if p_paused_until is not null and p_paused_until > v_now then
    insert into public.room_debug_overrides (
      room_id,
      hunger_decay_paused_until,
      reason,
      created_by,
      updated_at
    ) values (
      p_room_id,
      p_paused_until,
      nullif(left(coalesce(p_reason, 'debug_hunger_freeze'), 200), ''),
      auth.uid(),
      v_now
    )
    on conflict (room_id) do update
    set hunger_decay_paused_until = excluded.hunger_decay_paused_until,
        reason = excluded.reason,
        updated_at = v_now;

    update public.room_pet_state
    set hunger = 100,
        last_decay_at = v_now,
        updated_at = v_now
    where room_pet_state.room_id = p_room_id;

    update public.pet_state ps
    set hunger = 100,
        last_decay_at = v_now
    from public.pets p
    where p.id = ps.pet_id
      and p.id = v_main_pet_id
      and p.room_id = p_room_id;
  else
    delete from public.room_debug_overrides rdo
    where rdo.room_id = p_room_id;

    update public.room_pet_state
    set last_decay_at = v_now,
        updated_at = v_now
    where room_pet_state.room_id = p_room_id;

    update public.pet_state ps
    set last_decay_at = v_now
    from public.pets p
    where p.id = ps.pet_id
      and p.id = v_main_pet_id
      and p.room_id = p_room_id;
  end if;

  if v_main_pet_id is not null then
    perform public.refresh_pet_hunger_tick_schedule(v_main_pet_id, v_now);
  end if;

  return query
  select p_room_id,
         (
           select rdo.hunger_decay_paused_until
           from public.room_debug_overrides rdo
           where rdo.room_id = p_room_id
             and rdo.hunger_decay_paused_until > v_now
         );
end;
$$;

revoke all on function public.set_room_hunger_decay_paused(uuid, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.set_room_hunger_decay_paused(uuid, timestamptz, text)
  to authenticated;

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
  v_room_id uuid;
  v_hunger_decay_paused_until timestamptz;
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
         coalesce(r.timezone, 'UTC'),
         p.room_id
  into v_hunger,
       v_last_decay_at,
       v_poop_at,
       v_mood_boost,
       v_mood_boost_expires_at,
       v_timezone,
       v_room_id
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

  select rdo.hunger_decay_paused_until
  into v_hunger_decay_paused_until
  from public.room_debug_overrides rdo
  where rdo.room_id = v_room_id
    and rdo.hunger_decay_paused_until > p_now;

  if v_hunger_decay_paused_until is not null then
    return v_hunger_decay_paused_until;
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

create or replace function public.tick_pet_state(p_pet_id uuid, p_now timestamptz)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_last timestamptz;
  v_timezone text;
  v_local_hour int;
  v_is_night boolean := false;
  v_hours numeric;
  v_decay_rate numeric := 4;
  v_decay int := 0;
  v_hunger int;
  v_poop_at timestamptz;
  v_mood_boost int;
  v_mood_boost_expires_at timestamptz;
  v_effective_mood text;
  v_poop_count int;
  v_poop_positions jsonb;
  v_last_poop_spawn_at timestamptz;
  v_pet_created_at timestamptz;
  v_poop_interval interval := interval '8 hours';
  v_max_poop int := 3;
  v_spawn_x numeric;
  v_spawn_y numeric;
  v_new_hunger int;
  v_new_last_decay timestamptz;
  v_room_id uuid;
  v_hunger_decay_paused boolean := false;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select ps.last_decay_at, ps.hunger, ps.poop_at, ps.mood_boost,
         ps.mood_boost_expires_at, ps.poop_count, ps.poop_positions,
         ps.last_poop_spawn_at, p.created_at, coalesce(r.timezone, 'UTC'),
         p.room_id
  into v_last, v_hunger, v_poop_at, v_mood_boost, v_mood_boost_expires_at,
       v_poop_count, v_poop_positions, v_last_poop_spawn_at, v_pet_created_at,
       v_timezone, v_room_id
  from public.pet_state ps
  join public.pets p on p.id = ps.pet_id
  join public.rooms r on r.id = p.room_id
  join public.room_members rm on rm.room_id = p.room_id
  where ps.pet_id = p_pet_id
    and rm.user_id = auth.uid()
    and rm.is_active;

  if v_last is null then
    update public.pet_state set last_decay_at = p_now where pet_id = p_pet_id;
    return;
  end if;

  if p_now < v_last then
    return;
  end if;

  if v_mood_boost_expires_at is not null and v_mood_boost_expires_at <= p_now then
    v_mood_boost := 0;
    v_mood_boost_expires_at := null;
  end if;

  select ptn.name into v_timezone
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

  v_poop_count := coalesce(v_poop_count, 0);
  v_poop_positions := coalesce(v_poop_positions, '[]'::jsonb);

  if v_hunger > 0 and not v_is_night and v_poop_count < v_max_poop then
    if v_last_poop_spawn_at is null then
      v_last_poop_spawn_at := coalesce(v_poop_at, v_pet_created_at, v_last);
    end if;
    if v_last_poop_spawn_at is not null
      and p_now >= v_last_poop_spawn_at + v_poop_interval then
      v_spawn_x := (random() * 0.6) + 0.2;
      v_spawn_y := (random() * 0.4) + 0.55;
      v_poop_positions := v_poop_positions
        || jsonb_build_array(jsonb_build_object('x', v_spawn_x, 'y', v_spawn_y));
      v_poop_count := v_poop_count + 1;
      v_last_poop_spawn_at := p_now;
      if v_poop_count = 1 then
        v_poop_at := p_now;
      end if;
    end if;
  end if;

  v_effective_mood := public.compute_pet_mood(
    v_hunger, v_poop_at, p_now, v_is_night, v_mood_boost
  );

  v_hunger_decay_paused := exists (
    select 1
    from public.room_debug_overrides rdo
    where rdo.room_id = v_room_id
      and rdo.hunger_decay_paused_until > p_now
  );

  if v_hunger_decay_paused then
    update public.pet_state
    set hunger = v_hunger,
        last_decay_at = p_now,
        mood = v_effective_mood,
        mood_boost = v_mood_boost,
        mood_boost_expires_at = v_mood_boost_expires_at,
        poop_count = v_poop_count,
        poop_positions = v_poop_positions,
        last_poop_spawn_at = v_last_poop_spawn_at,
        poop_at = v_poop_at
    where pet_id = p_pet_id;

    update public.room_pet_state
    set hunger = v_hunger,
        last_decay_at = p_now,
        mood = v_effective_mood,
        mood_boost = v_mood_boost,
        mood_boost_expires_at = v_mood_boost_expires_at,
        poop_count = v_poop_count,
        poop_positions = v_poop_positions,
        last_poop_spawn_at = v_last_poop_spawn_at,
        poop_at = v_poop_at,
        updated_at = now()
    where room_id = v_room_id;

    return;
  end if;

  v_decay_rate := case v_effective_mood
    when 'high' then 2
    when 'mid' then 3
    when 'sad' then 4
    else 3
  end;
  if v_is_night then
    v_decay_rate := v_decay_rate * 0.5;
  end if;

  v_hours := extract(epoch from (p_now - v_last)) / 3600.0;
  if v_hours > 0 then
    v_decay := floor(v_hours * v_decay_rate);
  end if;

  v_new_hunger := greatest(0, v_hunger - v_decay);
  v_new_last_decay := case when v_decay > 0 then p_now else v_last end;

  update public.pet_state
  set hunger = v_new_hunger,
      last_decay_at = v_new_last_decay,
      mood = v_effective_mood,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      poop_count = v_poop_count,
      poop_positions = v_poop_positions,
      last_poop_spawn_at = v_last_poop_spawn_at,
      poop_at = v_poop_at
  where pet_id = p_pet_id;

  update public.room_pet_state
  set hunger = v_new_hunger,
      last_decay_at = v_new_last_decay,
      mood = v_effective_mood,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      poop_count = v_poop_count,
      poop_positions = v_poop_positions,
      last_poop_spawn_at = v_last_poop_spawn_at,
      poop_at = v_poop_at,
      updated_at = now()
  where room_id = v_room_id;
end;
$function$;

commit;
