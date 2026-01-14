-- Expand pet state machine logic (mood boosts, poop penalties, night mode).

alter table pet_state
  add column if not exists mood_boost int not null default 0,
  add column if not exists mood_boost_expires_at timestamptz,
  add column if not exists last_feed_boost_at timestamptz,
  add column if not exists last_touch_boost_at timestamptz,
  add column if not exists last_clean_boost_at timestamptz,
  add column if not exists feed_count_since_poop int not null default 0;

alter table pet_state
  add constraint pet_state_mood_boost check (mood_boost between 0 and 2);

alter table pet_state
  add constraint pet_state_feed_count check (feed_count_since_poop >= 0);

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
  if p_hunger <= 0 then
    v_base := 0; -- sad
  elsif p_hunger < 30 then
    v_base := 1; -- low
  else
    v_base := 2; -- mid
  end if;

  if p_poop_at is not null and not p_is_night then
    v_elapsed := extract(epoch from (p_now - p_poop_at)) / 3600.0;
    if v_elapsed >= 2 then
      v_penalty := floor((v_elapsed - 2) / 2) + 1;
    end if;
  end if;

  v_base := greatest(0, v_base - v_penalty);
  v_boost := least(2, greatest(0, p_mood_boost));
  v_effective := least(3, v_base + v_boost);

  return case v_effective
    when 0 then 'sad'
    when 1 then 'low'
    when 2 then 'mid'
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
  v_decay_rate numeric := 5;
  v_decay int := 0;
  v_hunger int;
  v_poop_at timestamptz;
  v_mood_boost int;
  v_mood_boost_expires_at timestamptz;
  v_effective_mood text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select ps.last_decay_at,
         ps.hunger,
         ps.poop_at,
         ps.mood_boost,
         ps.mood_boost_expires_at,
         coalesce(pf.timezone, 'UTC')
  into v_last,
       v_hunger,
       v_poop_at,
       v_mood_boost,
       v_mood_boost_expires_at,
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
      mood_boost_expires_at = v_mood_boost_expires_at
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
    if v_last_feed_at is not null and v_last_feed_at > v_now - interval '10 minutes' then
      v_overfed := true;
    end if;

    if not v_overfed then
      v_hunger := least(100, v_hunger + 10);
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

create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_room_id uuid;
  v_pet_id uuid;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (
      select 1 from rooms r where r.invite_code = v_code
    );
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into rooms (name, invite_code, invite_expires_at, created_by)
  values (p_name, v_code, now() + interval '60 minutes', auth.uid())
  returning id into v_room_id;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  insert into pets (room_id, name, stage, level, days_alive, scale)
  values (v_room_id, null, 'egg', 1, 0, 1.0)
  returning id into v_pet_id;

  insert into pet_state (pet_id) values (v_pet_id);

  return query select v_room_id, v_code;
end;
$$;

insert into pets (room_id, name, stage, level, days_alive, scale)
select r.id, null, 'egg', 1, 0, 1.0
from rooms r
left join pets p on p.room_id = r.id
where p.id is null;

insert into pet_state (pet_id)
select p.id
from pets p
left join pet_state ps on ps.pet_id = p.id
where ps.pet_id is null;
