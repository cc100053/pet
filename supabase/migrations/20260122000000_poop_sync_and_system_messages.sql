-- Sync poop incidents across room members and log clean actions.

alter table pet_state
  add column if not exists poop_count int not null default 0,
  add column if not exists poop_positions jsonb not null default '[]'::jsonb,
  add column if not exists last_poop_spawn_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'pet_state_poop_count'
  ) then
    alter table pet_state
      add constraint pet_state_poop_count check (poop_count >= 0);
  end if;
end;
$$;

update pet_state
set poop_count = 1,
    poop_positions = jsonb_build_array(
      jsonb_build_object('x', 0.62, 'y', 0.72)
    ),
    last_poop_spawn_at = coalesce(last_poop_spawn_at, poop_at)
where poop_at is not null
  and poop_count = 0;

update pet_state
set last_poop_spawn_at = coalesce(last_poop_spawn_at, poop_at)
where poop_count > 0
  and last_poop_spawn_at is null;

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
  v_decay_rate numeric := 5;
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
  v_poop_interval interval := interval '12 hours';
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
         coalesce(pf.timezone, 'UTC')
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
  from pet_state ps
  join pets p on p.id = ps.pet_id
  join room_members rm on rm.room_id = p.room_id
  join profiles pf on pf.user_id = rm.user_id
  where ps.pet_id = p_pet_id
    and rm.user_id = auth.uid()
    and rm.is_active;

  if v_last is null then
    update pet_state set last_decay_at = p_now where pet_id = p_pet_id;
    return;
  end if;

  if p_now < v_last then
    return;
  end if;

  if v_mood_boost_expires_at is not null and v_mood_boost_expires_at <= p_now then
    v_mood_boost := 0;
    v_mood_boost_expires_at := null;
  end if;

  v_local_hour := extract(hour from (p_now at time zone v_timezone));
  if v_local_hour between 0 and 7 then
    v_is_night := true;
  end if;

  v_poop_count := coalesce(v_poop_count, 0);
  v_poop_positions := coalesce(v_poop_positions, '[]'::jsonb);

  if not v_is_night and v_poop_count < v_max_poop then
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
    when 'high' then 3
    when 'mid' then 4
    when 'low' then 5
    when 'sad' then case when v_poop_at is not null then 6 else 5 end
    else 5
  end;

  if v_is_night then
    v_decay_rate := v_decay_rate * 0.5;
  end if;

  v_hours := extract(epoch from (p_now - v_last)) / 3600.0;
  if v_hours > 0 then
    v_decay := floor(v_hours * v_decay_rate);
  end if;

  update pet_state
  set hunger = greatest(0, v_hunger - v_decay),
      last_decay_at = p_now,
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
  v_poop_count int;
  v_poop_positions jsonb;
  v_last_poop_spawn_at timestamptz;
  v_poop_interval interval := interval '12 hours';
  v_max_poop int := 3;
  v_spawn_x numeric;
  v_spawn_y numeric;
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
         ps.mood_boost,
         ps.mood_boost_expires_at,
         ps.last_feed_at,
         ps.last_touch_at,
         ps.last_clean_at,
         ps.last_feed_boost_at,
         ps.last_touch_boost_at,
         ps.last_clean_boost_at,
         ps.poop_count,
         ps.poop_positions,
         ps.last_poop_spawn_at,
         coalesce(pf.timezone, 'UTC')
  into v_hunger,
       v_hygiene,
       v_poop_at,
       v_feed_count,
       v_mood_boost,
       v_mood_boost_expires_at,
       v_last_feed_at,
       v_last_touch_at,
       v_last_clean_at,
       v_last_feed_boost_at,
       v_last_touch_boost_at,
       v_last_clean_boost_at,
       v_poop_count,
       v_poop_positions,
       v_last_poop_spawn_at,
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
  v_poop_count := coalesce(v_poop_count, 0);
  v_poop_positions := coalesce(v_poop_positions, '[]'::jsonb);

  if p_action_type = 'feed' then
    if v_last_feed_at is not null and v_last_feed_at > v_now - interval '10 minutes' then
      v_overfed := true;
    end if;

    if not v_overfed then
      v_hunger := least(100, v_hunger + 10);
    end if;

    v_feed_count := v_feed_count + 1;
    if v_feed_count >= 3 and v_poop_count < v_max_poop then
      v_spawn_x := (random() * 0.6) + 0.2;
      v_spawn_y := (random() * 0.4) + 0.55;
      v_poop_positions := v_poop_positions
        || jsonb_build_array(
          jsonb_build_object('x', v_spawn_x, 'y', v_spawn_y)
        );
      v_poop_count := v_poop_count + 1;
      v_last_poop_spawn_at := v_now;
      if v_poop_count = 1 then
        v_poop_at := v_now;
      end if;
      v_feed_count := 0;
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
    v_poop_count := 0;
    v_poop_positions := '[]'::jsonb;
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
      last_feed_at = v_new_last_feed_at,
      last_touch_at = v_new_last_touch_at,
      last_clean_at = v_new_last_clean_at,
      last_feed_boost_at = v_new_last_feed_boost_at,
      last_touch_boost_at = v_new_last_touch_boost_at,
      last_clean_boost_at = v_new_last_clean_boost_at,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      mood = v_effective_mood,
      poop_count = v_poop_count,
      poop_positions = v_poop_positions,
      last_poop_spawn_at = v_last_poop_spawn_at
  where pet_id = p_pet_id;
end;
$$;

create or replace function public.clean_poop(
  p_pet_id uuid,
  p_poop_index int default null
)
returns table (poop_count int, coins_awarded int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_positions jsonb;
  v_new_positions jsonb;
  v_poop_count int;
  v_poop_at timestamptz;
  v_nickname text;
  v_reward int := 0;
  v_index int;
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

  select ps.poop_positions, ps.poop_count, ps.poop_at
  into v_positions, v_poop_count, v_poop_at
  from pet_state ps
  where ps.pet_id = p_pet_id
  for update;

  v_positions := coalesce(v_positions, '[]'::jsonb);
  v_poop_count := coalesce(v_poop_count, 0);

  if v_poop_count <= 0 then
    return query select 0, 0;
  end if;

  perform public.apply_pet_action(p_pet_id, 'clean');

  if p_poop_index is null or p_poop_index < 0 or p_poop_index >= v_poop_count then
    v_index := 0;
  else
    v_index := p_poop_index;
  end if;

  select coalesce(jsonb_agg(value order by idx), '[]'::jsonb)
  into v_new_positions
  from (
    select value, idx
    from jsonb_array_elements(v_positions) with ordinality as t(value, idx)
    where idx <> v_index + 1
    order by idx
  ) s;

  v_poop_count := greatest(0, v_poop_count - 1);
  if v_poop_count = 0 then
    v_poop_at := null;
  end if;

  update pet_state
  set poop_positions = v_new_positions,
      poop_count = v_poop_count,
      poop_at = v_poop_at
  where pet_id = p_pet_id;

  v_reward := public.claim_action_reward('clean', v_room_id);

  select nickname into v_nickname from profiles where user_id = auth.uid();

  insert into messages (room_id, sender_id, type, body, coins_awarded)
  values (
    v_room_id,
    null,
    'system',
    coalesce(v_nickname, 'Someone') || ' cleaned the poop: +'
      || v_reward::text || ' Coins.',
    v_reward
  );

  return query select v_poop_count, v_reward;
end;
$$;
