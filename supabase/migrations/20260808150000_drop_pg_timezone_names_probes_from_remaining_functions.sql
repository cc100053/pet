-- Remove the remaining `pg_timezone_names` probes.
--
-- Follow-up to `20260808130000`, which fixed `tick_pet_state`. The same probe
-- lived in six more functions, and they are the next-largest consumers of DB
-- time on this project:
--
--   get_effective_room_pet_statuses   3,575 calls  1,652 ms mean  max 7,957 ms
--   apply_pet_action / _room_          3,884 calls    588 ms mean  max 7,934 ms
--   create_room                          284 calls    967 ms mean  max 4,827 ms
--   compute_pet_hunger_next_check_at     (hunger scheduler / cron path)
--   ensure_room_owner                    (room_members trigger)
--
-- `pg_timezone_names` re-reads the whole IANA tz database per scan (~792 ms
-- measured here). The 7,9xx ms maxima are calls dying on the `authenticated`
-- role's 8 s statement_timeout. `get_effective_room_pet_statuses` is the worst
-- of these because its probe sits in a lateral join and therefore runs once
-- per requested room.
--
-- `get_effective_room_pet_statuses` deliberately carries no inline comment at
-- its rewritten lateral: it is a `LANGUAGE sql` body, so anything written there
-- lands in `prosrc` and would make the checked-in text diverge from the
-- deployed function.
--
-- All six only ever used the probe to fall back to UTC for an unknown zone,
-- which `at time zone` already does by raising 22023. Every signature,
-- parameter, return type, volatility, security mode, and side effect is
-- unchanged, and `create or replace` preserves the existing grants (notably
-- the tightened `apply_pet_action` ACL from `20260607005904`), so installed
-- app versions are unaffected.

-- A `LANGUAGE sql` function cannot carry an exception handler, and
-- `get_effective_room_pet_statuses` is one, so the fallback lives here rather
-- than being inlined six times.
create or replace function public.normalize_timezone(p_timezone text)
returns text
language plpgsql
stable
parallel safe
set search_path = public
as $function$
declare
  v_timezone text := nullif(trim(coalesce(p_timezone, '')), '');
begin
  if v_timezone is null then
    return 'UTC';
  end if;

  -- Validation only. A fixed instant keeps this free of `now()`, and the cast
  -- raises 22023 for a zone Postgres does not know.
  perform timestamptz '2000-01-01 00:00:00+00' at time zone v_timezone;
  return v_timezone;
exception
  when others then
    return 'UTC';
end;
$function$;

revoke all on function public.normalize_timezone(text) from public, anon;
grant execute on function public.normalize_timezone(text) to authenticated, service_role;


create or replace function public.apply_pet_action(p_pet_id uuid, p_action_type text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
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
  v_anchor_decay_after_feed boolean := false;
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
      v_hunger := least(100, v_hunger + 25);
      v_feed_burst_count := v_feed_burst_count + 1;
      v_anchor_decay_after_feed := true;
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

  -- Was: a `pg_timezone_names` probe.
  v_timezone := public.normalize_timezone(v_timezone);

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
      last_decay_at = case
        when v_anchor_decay_after_feed then v_now
        else last_decay_at
      end,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      mood = v_effective_mood
  where pet_id = p_pet_id;

  -- Hunger/mood are room-shared: mirror the result into room_pet_state so a
  -- later main-pet swap (which syncs FROM room_pet_state) keeps the fed value.
  insert into public.room_pet_state (room_id)
  values (v_room_id)
  on conflict (room_id) do nothing;

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
      last_decay_at = case
        when v_anchor_decay_after_feed then v_now
        else last_decay_at
      end,
      mood_boost = v_mood_boost,
      mood_boost_expires_at = v_mood_boost_expires_at,
      mood = v_effective_mood,
      updated_at = v_now
  where room_id = v_room_id;
end;
$function$;


create or replace function public.apply_room_pet_action(p_room_id uuid, p_action_type text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  -- Was: a `pg_timezone_names` probe.
  v_timezone := public.normalize_timezone(v_timezone);

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
$function$;


create or replace function public.compute_pet_hunger_next_check_at(
  p_pet_id uuid,
  p_now timestamp with time zone default now()
)
returns timestamp with time zone
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  -- Was: a `pg_timezone_names` probe.
  v_timezone := public.normalize_timezone(v_timezone);

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
$function$;


create or replace function public.create_room(p_name text)
returns table(room_id uuid, invite_code text)
language plpgsql
security definer
set search_path to 'public'
as $function$
#variable_conflict use_column
declare
  v_code text;
  v_room_id uuid;
  v_pet_id uuid;
  v_background_id uuid;
  v_attempts int := 0;
  v_room_timezone text := 'UTC';
  v_expires_at timestamptz := now() + interval '24 hours';
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select coalesce(nullif(trim(pf.timezone), ''), 'UTC')
  into v_room_timezone
  from public.profiles pf
  where pf.user_id = auth.uid();

  -- Was: a `pg_timezone_names` probe. `normalize_timezone` also maps a missing
  -- profile row (which leaves the variable null) to 'UTC', as the probe did.
  v_room_timezone := public.normalize_timezone(v_room_timezone);

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (
      select 1
      from public.rooms r
      where r.invite_code = v_code
    )
    and not exists (
      select 1
      from public.room_invite_codes ric
      where ric.code = v_code
    );

    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into public.rooms (
    name,
    invite_code,
    invite_expires_at,
    created_by,
    timezone
  )
  values (
    p_name,
    v_code,
    v_expires_at,
    auth.uid(),
    v_room_timezone
  )
  returning id into v_room_id;

  insert into public.room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  insert into public.room_invite_codes (
    room_id,
    code,
    created_by,
    expires_at
  ) values (
    v_room_id,
    v_code,
    auth.uid(),
    v_expires_at
  );

  insert into public.pets (room_id, name, stage, level, days_alive, scale)
  values (v_room_id, null, 'egg', 1, 0, 1.0)
  returning id into v_pet_id;

  update public.rooms
  set main_pet_id = v_pet_id
  where id = v_room_id;

  insert into public.pet_state (pet_id) values (v_pet_id);
  insert into public.room_pet_state (room_id) values (v_room_id);

  select id into v_background_id
  from public.items
  where sku = 'background_default'
  limit 1;

  if v_background_id is not null then
    insert into public.room_backgrounds (room_id, item_id, acquired_by)
    select
      v_room_id,
      i.id,
      auth.uid()
    from public.items i
    where i.sku = 'background_default'
       or (
         (i.metadata->>'category') = 'background'
         and coalesce(i.metadata->>'shop_visibility', '') = 'hidden'
       )
    on conflict (room_id, item_id) do nothing;

    insert into public.room_background_state (
      room_id,
      active_item_id,
      updated_by
    ) values (
      v_room_id,
      v_background_id,
      auth.uid()
    )
    on conflict (room_id) do update
    set active_item_id = excluded.active_item_id,
        updated_by = excluded.updated_by;
  end if;

  return query select v_room_id as room_id, v_code as invite_code;
end;
$function$;


create or replace function public.ensure_room_owner()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_room_id uuid;
  v_owner uuid;
  v_owner_timezone text;
begin
  v_room_id := coalesce(new.room_id, old.room_id);
  if v_room_id is null then
    return null;
  end if;

  select user_id into v_owner
  from room_members
  where room_id = v_room_id
    and role = 'owner'
    and is_active
  limit 1;

  if v_owner is null then
    select user_id into v_owner
    from room_members
    where room_id = v_room_id
      and is_active
    order by joined_at asc
    limit 1;

    if v_owner is not null then
      update room_members
      set role = 'owner'
      where room_id = v_room_id
        and user_id = v_owner;

      -- Was: a left join against `pg_timezone_names` to validate the owner's
      -- profile zone. A missing profile row still leaves this null so the
      -- `coalesce` below keeps writing 'UTC'.
      select public.normalize_timezone(pf.timezone)
      into v_owner_timezone
      from public.profiles pf
      where pf.user_id = v_owner
      limit 1;

      update rooms
      set created_by = v_owner,
          timezone = coalesce(v_owner_timezone, 'UTC')
      where id = v_room_id;
    end if;
  end if;

  return null;
end;
$function$;


create or replace function public.get_effective_room_pet_statuses(p_room_ids uuid[])
returns table(
  room_id uuid,
  pet_id uuid,
  effective_hunger integer,
  computed_at timestamp with time zone,
  pet_state jsonb
)
language sql
stable
set search_path to 'public'
as $function$
  with requested_rooms as (
    select distinct requested.room_id
    from unnest(coalesce(p_room_ids, array[]::uuid[])) as requested(room_id)
  ),
  request_clock as (
    select statement_timestamp() as computed_at
  )
  select
    r.id as room_id,
    p.id as pet_id,
    effective.effective_hunger,
    clock.computed_at,
    to_jsonb(rps)
      || jsonb_build_object(
        'pet_id', p.id,
        'hunger', effective.effective_hunger,
        'mood', mood.effective_mood,
        'mood_boost', boost.effective_mood_boost,
        'mood_boost_expires_at', boost.effective_mood_boost_expires_at,
        '_effective_hunger', effective.effective_hunger,
        '_status_computed_at', clock.computed_at
      ) as pet_state
  from requested_rooms requested
  join public.rooms r on r.id = requested.room_id
  join public.pets p on p.room_id = r.id
  join public.room_pet_state rps on rps.room_id = r.id
  cross join request_clock clock
  cross join lateral (
    select public.normalize_timezone(r.timezone) as room_timezone
  ) timezone
  cross join lateral (
    select extract(
      hour from (clock.computed_at at time zone timezone.room_timezone)
    )::integer between 0 and 7 as is_night
  ) night
  cross join lateral (
    select
      case
        when rps.mood_boost_expires_at is not null
          and rps.mood_boost_expires_at <= clock.computed_at
          then 0
        else coalesce(rps.mood_boost, 0)
      end as effective_mood_boost,
      case
        when rps.mood_boost_expires_at is not null
          and rps.mood_boost_expires_at <= clock.computed_at
          then null
        else rps.mood_boost_expires_at
      end as effective_mood_boost_expires_at
  ) boost
  cross join lateral (
    select public.compute_pet_mood(
      rps.hunger,
      rps.poop_at,
      clock.computed_at,
      night.is_night,
      boost.effective_mood_boost
    ) as effective_mood
  ) mood
  cross join lateral (
    select (
      case mood.effective_mood
        when 'high' then 2.0
        when 'sad' then 4.0
        else 3.0
      end
      * case when night.is_night then 0.5 else 1.0 end
    ) as decay_rate
  ) rate
  cross join lateral (
    select case
      when rps.hunger <= 0
        or rps.last_decay_at is null
        or clock.computed_at <= rps.last_decay_at
        then 0
      else floor(
        extract(epoch from (clock.computed_at - rps.last_decay_at))
        / 3600.0
        * rate.decay_rate
      )::integer
    end as decay
  ) decay
  cross join lateral (
    select greatest(0, rps.hunger - decay.decay)::integer as effective_hunger
  ) effective
  where exists (
    select 1
    from public.room_members rm
    where rm.room_id = r.id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  );
$function$;
