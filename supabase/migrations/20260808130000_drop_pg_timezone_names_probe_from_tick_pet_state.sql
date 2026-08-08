-- Remove the `pg_timezone_names` probe from `tick_pet_state`.
--
-- `pg_timezone_names` is a set-returning system view that re-reads the whole
-- IANA tz database on every scan. Measured on this project a single
-- `select name from pg_timezone_names where name = 'Asia/Tokyo' limit 1`
-- costs ~792 ms, and `tick_pet_state` ran it on every call: 71.5k calls at a
-- 757 ms mean, 54,165 s of cumulative execution time, and a max of 7,978 ms —
-- i.e. calls dying on the `authenticated` role's 8 s statement_timeout and
-- surfacing in the app as PostgrestException 57014.
--
-- The probe only existed to fall back to UTC for an unknown zone, and
-- `at time zone` already raises 22023 (invalid_parameter_value) in exactly
-- that case, so an exception block gives the same answer for ~2.8 ms.
--
-- Signature, parameters, return type, and all side effects are unchanged, so
-- already-installed app versions are unaffected.

create or replace function public.tick_pet_state(
  p_pet_id uuid,
  p_now timestamp with time zone
)
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

  -- Was: a `pg_timezone_names` lookup to validate the room's zone before use.
  -- `at time zone` performs the same validation as a side effect, without
  -- rescanning the tz database.
  begin
    v_local_hour := extract(
      hour from (p_now at time zone coalesce(v_timezone, 'UTC'))
    );
  exception
    when others then
      v_timezone := 'UTC';
      v_local_hour := extract(hour from (p_now at time zone 'UTC'));
  end;

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
