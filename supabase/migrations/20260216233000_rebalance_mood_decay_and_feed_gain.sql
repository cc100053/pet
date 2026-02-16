-- Rebalance pet hunger/mood rules:
-- 1) Remove "low" mood state from runtime + constraint.
-- 2) Hunger decay rates: mid=3/h, sad=4/h.
-- 3) Feed gives +20 hunger, at most once per 10-minute burst.

begin;

update public.pet_state
set mood = 'mid'
where mood = 'low';

alter table public.pet_state
  drop constraint if exists pet_state_mood;

alter table public.pet_state
  add constraint pet_state_mood check (mood in ('mid', 'high', 'sad'));

create or replace function public.compute_pet_mood(
  p_hunger int,
  p_poop_at timestamptz,
  p_now timestamptz,
  p_is_night boolean,
  p_mood_boost int
)
returns text
language plpgsql
as $$
declare
  v_base int;
  v_penalty int := 0;
  v_elapsed numeric;
  v_boost int;
  v_effective int;
begin
  -- Only 3 moods remain: sad, mid, high.
  if p_hunger <= 0 then
    v_base := 0; -- sad
  else
    v_base := 1; -- mid
  end if;

  if p_poop_at is not null and not p_is_night then
    v_elapsed := extract(epoch from (p_now - p_poop_at)) / 3600.0;
    if v_elapsed >= 2 then
      v_penalty := floor((v_elapsed - 2) / 2) + 1;
    end if;
  end if;

  v_base := greatest(0, v_base - v_penalty);
  -- Mood boost can only raise mid->high in this 3-state model.
  v_boost := least(1, greatest(0, p_mood_boost));
  v_effective := least(2, v_base + v_boost);

  return case v_effective
    when 0 then 'sad'
    when 1 then 'mid'
    else 'high'
  end;
end;
$$;

create or replace function public.tick_pet_state(p_pet_id uuid, p_now timestamptz)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last timestamptz;
  v_timezone text;
  v_local_hour int;
  v_is_night boolean := false;
  v_hours numeric;
  v_decay_rate numeric := 3;
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
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select ps.last_decay_at,
         ps.hunger,
         ps.poop_at,
         ps.mood_boost,
         ps.mood_boost_expires_at,
         ps.poop_count,
         ps.poop_positions,
         ps.last_poop_spawn_at,
         p.created_at,
         coalesce(r.timezone, 'UTC')
  into v_last,
       v_hunger,
       v_poop_at,
       v_mood_boost,
       v_mood_boost_expires_at,
       v_poop_count,
       v_poop_positions,
       v_last_poop_spawn_at,
       v_pet_created_at,
       v_timezone
  from public.pet_state ps
  join public.pets p on p.id = ps.pet_id
  join public.rooms r on r.id = p.room_id
  join public.room_members rm on rm.room_id = p.room_id
  where ps.pet_id = p_pet_id
    and rm.user_id = auth.uid()
    and rm.is_active;

  if v_last is null then
    update public.pet_state
    set last_decay_at = p_now
    where pet_id = p_pet_id;
    return;
  end if;

  if p_now < v_last then
    return;
  end if;

  if v_mood_boost_expires_at is not null and v_mood_boost_expires_at <= p_now then
    v_mood_boost := 0;
    v_mood_boost_expires_at := null;
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
        || jsonb_build_array(
          jsonb_build_object('x', v_spawn_x, 'y', v_spawn_y)
        );
      v_poop_count := v_poop_count + 1;
      v_last_poop_spawn_at := p_now;
      if v_poop_count = 1 then
        v_poop_at := p_now;
      end if;
    end if;
  end if;

  v_effective_mood := public.compute_pet_mood(
    v_hunger,
    v_poop_at,
    p_now,
    v_is_night,
    v_mood_boost
  );

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

  update public.pet_state
  set hunger = greatest(0, v_hunger - v_decay),
      last_decay_at = case when v_decay > 0 then p_now else v_last end,
      mood = v_effective_mood,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      poop_count = v_poop_count,
      poop_positions = v_poop_positions,
      last_poop_spawn_at = v_last_poop_spawn_at,
      poop_at = v_poop_at
  where pet_id = p_pet_id;
end;
$$;

create or replace function public.apply_pet_action(p_pet_id uuid, p_action_type text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_now timestamptz := now();
  v_hunger int;
  v_hygiene int;
  v_poop_at timestamptz;
  v_feed_count int;
  v_feed_burst_count int;
  v_feed_burst_started_at timestamptz;
  v_last_overfed_at timestamptz;
  v_mood_boost int;
  v_mood_boost_expires_at timestamptz;
  v_last_feed_at timestamptz;
  v_last_touch_at timestamptz;
  v_last_clean_at timestamptz;
  v_last_feed_boost_at timestamptz;
  v_last_touch_boost_at timestamptz;
  v_last_clean_boost_at timestamptz;
  v_timezone text;
  v_local_hour int;
  v_is_night boolean := false;
  v_effective_mood text;
  v_can_boost boolean := false;
  v_new_last_feed_at timestamptz;
  v_new_last_touch_at timestamptz;
  v_new_last_clean_at timestamptz;
  v_new_last_feed_boost_at timestamptz;
  v_new_last_touch_boost_at timestamptz;
  v_new_last_clean_boost_at timestamptz;
  v_overfed boolean := false;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id into v_room_id from public.pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not exists (
    select 1 from public.room_members rm
    where rm.room_id = v_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  ) then
    raise exception 'not_authorized';
  end if;

  perform public.tick_pet_state(p_pet_id, v_now);

  select ps.hunger,
         ps.hygiene,
         ps.poop_at,
         ps.feed_count_since_poop,
         ps.feed_burst_count,
         ps.feed_burst_started_at,
         ps.last_overfed_at,
         ps.mood_boost,
         ps.mood_boost_expires_at,
         ps.last_feed_at,
         ps.last_touch_at,
         ps.last_clean_at,
         ps.last_feed_boost_at,
         ps.last_touch_boost_at,
         ps.last_clean_boost_at,
         coalesce(r.timezone, 'UTC')
  into v_hunger,
       v_hygiene,
       v_poop_at,
       v_feed_count,
       v_feed_burst_count,
       v_feed_burst_started_at,
       v_last_overfed_at,
       v_mood_boost,
       v_mood_boost_expires_at,
       v_last_feed_at,
       v_last_touch_at,
       v_last_clean_at,
       v_last_feed_boost_at,
       v_last_touch_boost_at,
       v_last_clean_boost_at,
       v_timezone
  from public.pet_state ps
  join public.pets p on p.id = ps.pet_id
  join public.rooms r on r.id = p.room_id
  join public.room_members rm on rm.room_id = p.room_id
  where ps.pet_id = p_pet_id
    and rm.user_id = auth.uid()
    and rm.is_active;

  if v_mood_boost_expires_at is not null and v_mood_boost_expires_at <= v_now then
    v_mood_boost := 0;
    v_mood_boost_expires_at := null;
  end if;

  v_new_last_feed_at := v_last_feed_at;
  v_new_last_touch_at := v_last_touch_at;
  v_new_last_clean_at := v_last_clean_at;
  v_new_last_feed_boost_at := v_last_feed_boost_at;
  v_new_last_touch_boost_at := v_last_touch_boost_at;
  v_new_last_clean_boost_at := v_last_clean_boost_at;

  if p_action_type = 'feed' then
    if v_feed_burst_started_at is null
      or v_feed_burst_started_at <= v_now - interval '10 minutes' then
      v_feed_burst_started_at := v_now;
      v_feed_burst_count := 0;
    end if;

    -- One successful feed per 10-minute burst.
    if v_feed_burst_count >= 1 then
      v_overfed := true;
    end if;

    if not v_overfed then
      v_hunger := least(100, v_hunger + 20);
      v_feed_burst_count := v_feed_burst_count + 1;
    else
      v_last_overfed_at := v_now;
    end if;

    if v_poop_at is null then
      v_feed_count := v_feed_count + 1;
      if v_feed_count >= 3 then
        v_poop_at := v_now;
        v_feed_count := 0;
      end if;
    end if;

    v_new_last_feed_at := v_now;
    v_can_boost := v_last_feed_boost_at is null
      or v_last_feed_boost_at <= v_now - interval '2 hours';
    if v_can_boost then
      v_mood_boost := least(2, v_mood_boost + 1);
      v_mood_boost_expires_at := v_now + interval '1 hour';
      v_new_last_feed_boost_at := v_now;
    end if;
  elsif p_action_type = 'clean' then
    v_hygiene := least(100, v_hygiene + 10);
    v_poop_at := null;
    v_feed_count := 0;
    v_new_last_clean_at := v_now;
    v_can_boost := v_last_clean_boost_at is null
      or v_last_clean_boost_at <= v_now - interval '2 hours';
    if v_can_boost then
      v_mood_boost := least(2, v_mood_boost + 1);
      v_mood_boost_expires_at := v_now + interval '1 hour';
      v_new_last_clean_boost_at := v_now;
    end if;
  elsif p_action_type = 'touch' then
    v_new_last_touch_at := v_now;
    v_can_boost := v_last_touch_boost_at is null
      or v_last_touch_boost_at <= v_now - interval '2 hours';
    if v_can_boost then
      v_mood_boost := least(2, v_mood_boost + 1);
      v_mood_boost_expires_at := v_now + interval '1 hour';
      v_new_last_touch_boost_at := v_now;
    end if;
  else
    raise exception 'invalid_action';
  end if;

  select ptn.name
  into v_timezone
  from pg_timezone_names ptn
  where ptn.name = coalesce(v_timezone, 'UTC')
  limit 1;

  if v_timezone is null then
    v_timezone := 'UTC';
  end if;

  v_local_hour := extract(hour from (v_now at time zone v_timezone));
  if v_local_hour between 0 and 7 then
    v_is_night := true;
  end if;

  v_effective_mood := public.compute_pet_mood(
    v_hunger,
    v_poop_at,
    v_now,
    v_is_night,
    v_mood_boost
  );

  update public.pet_state
  set hunger = v_hunger,
      hygiene = v_hygiene,
      poop_at = v_poop_at,
      feed_count_since_poop = v_feed_count,
      feed_burst_count = v_feed_burst_count,
      feed_burst_started_at = v_feed_burst_started_at,
      last_overfed_at = v_last_overfed_at,
      last_feed_at = v_new_last_feed_at,
      last_touch_at = v_new_last_touch_at,
      last_clean_at = v_new_last_clean_at,
      last_feed_boost_at = v_new_last_feed_boost_at,
      last_touch_boost_at = v_new_last_touch_boost_at,
      last_clean_boost_at = v_new_last_clean_boost_at,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      mood = v_effective_mood
  where pet_id = p_pet_id;
end;
$$;

commit;
