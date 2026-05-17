begin;

create or replace function public.apply_room_pet_action(
  p_room_id uuid,
  p_action_type text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
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

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  insert into public.room_pet_state (room_id)
  values (p_room_id)
  on conflict (room_id) do nothing;

  select rps.hunger,
         rps.hygiene,
         rps.poop_at,
         rps.feed_count_since_poop,
         rps.feed_burst_count,
         rps.feed_burst_started_at,
         rps.last_overfed_at,
         rps.mood_boost,
         rps.mood_boost_expires_at,
         rps.last_feed_at,
         rps.last_touch_at,
         rps.last_clean_at,
         rps.last_feed_boost_at,
         rps.last_touch_boost_at,
         rps.last_clean_boost_at,
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
  from public.room_pet_state rps
  join public.rooms r on r.id = rps.room_id
  where rps.room_id = p_room_id
  for update;

  if not found then
    raise exception 'room_pet_state_not_found';
  end if;

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

    if v_feed_burst_count >= 1 then
      v_overfed := true;
    end if;

    if not v_overfed then
      v_hunger := least(100, v_hunger + 25);
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

  update public.room_pet_state
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
      mood = v_effective_mood,
      updated_at = v_now
  where room_id = p_room_id;

  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);
end;
$$;

grant execute on function public.apply_room_pet_action(uuid, text)
  to authenticated;

commit;
