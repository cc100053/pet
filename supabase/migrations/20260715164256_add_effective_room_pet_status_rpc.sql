-- Additive, read-only effective pet-status API for the room picker and Home.
--
-- Old clients continue reading/ticking pet_state exactly as before. New clients
-- can render the room-shared hunger as of one server timestamp without first
-- mutating state. SECURITY INVOKER plus the explicit active-membership check
-- keeps the existing rooms/pets/room_pet_state RLS boundary intact.

create or replace function public.get_effective_room_pet_statuses(
  p_room_ids uuid[]
)
returns table (
  room_id uuid,
  pet_id uuid,
  effective_hunger integer,
  computed_at timestamptz,
  pet_state jsonb
)
language sql
security invoker
set search_path = public
stable
as $$
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
    select coalesce(
      (
        select ptn.name
        from pg_timezone_names ptn
        where ptn.name = coalesce(r.timezone, 'UTC')
        limit 1
      ),
      'UTC'
    ) as room_timezone
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
$$;

revoke all on function public.get_effective_room_pet_statuses(uuid[])
  from public, anon;
grant execute on function public.get_effective_room_pet_statuses(uuid[])
  to authenticated;
