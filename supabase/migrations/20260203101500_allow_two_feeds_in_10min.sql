-- Allow two feed actions within 10 minutes before overfed triggers.

alter table pet_state
  add column if not exists feed_burst_count int not null default 0,
  add column if not exists feed_burst_started_at timestamptz,
  add column if not exists last_overfed_at timestamptz;

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

  select room_id into v_room_id from pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not exists (
    select 1 from room_members rm
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
         coalesce(pf.timezone, 'UTC')
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
  from pet_state ps
  join pets p on p.id = ps.pet_id
  join room_members rm on rm.room_id = p.room_id
  join profiles pf on pf.user_id = rm.user_id
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

    if v_feed_burst_count >= 2 then
      v_overfed := true;
    end if;

    if not v_overfed then
      v_hunger := least(100, v_hunger + 10);
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

  update pet_state
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
