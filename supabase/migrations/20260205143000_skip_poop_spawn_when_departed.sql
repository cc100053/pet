-- Skip poop spawning when the pet has departed (hunger <= 0).
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
    when 'mid' then 4
    when 'low' then 3
    when 'sad' then case when v_poop_at is not null then 5 else 4 end
    else 4
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
