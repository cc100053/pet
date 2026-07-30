-- Standardize every first-party room invite flow on a 24-hour lifetime while
-- preserving reusable codes, existing RPC signatures, and unlimited joins.

create or replace function public.create_room_invite_code(
  p_room_id uuid,
  p_expires_in_minutes int default 1440
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_attempts int := 0;
  v_expires_at timestamptz;
  v_active_count int := 0;
  v_is_member boolean := false;
  v_revoke_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select exists (
    select 1
    from public.room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
  into v_is_member;

  if not v_is_member then
    raise exception 'not_member';
  end if;

  v_expires_at := now() + make_interval(
    mins => greatest(5, least(coalesce(p_expires_in_minutes, 1440), 60 * 24 * 7))
  );

  select count(*)
  into v_active_count
  from public.room_invite_codes ric
  where ric.room_id = p_room_id
    and ric.revoked_at is null
    and ric.expires_at > now();

  if v_active_count >= 3 then
    select ric.id
    into v_revoke_id
    from public.room_invite_codes ric
    where ric.room_id = p_room_id
      and ric.revoked_at is null
      and ric.expires_at > now()
    order by ric.created_at asc
    limit 1;

    if v_revoke_id is null then
      raise exception 'invite_code_limit_reached';
    end if;

    update public.room_invite_codes
    set revoked_at = now(),
        revoked_by = auth.uid()
    where id = v_revoke_id;
  end if;

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

    if v_attempts >= 40 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into public.room_invite_codes (
    room_id,
    code,
    created_by,
    expires_at
  ) values (
    p_room_id,
    v_code,
    auth.uid(),
    v_expires_at
  );

  update public.rooms
  set invite_code = v_code,
      invite_expires_at = v_expires_at
  where id = p_room_id;

  return v_code;
end;
$$;

grant execute on function public.create_room_invite_code(uuid, int)
to authenticated;

create or replace function public.get_or_create_room_invite_code(
  p_room_id uuid,
  p_expires_in_minutes int default 1440
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_attempts int := 0;
  v_expires_at timestamptz;
  v_existing_code text;
  v_existing_expires_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1
    from public.room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  ) then
    raise exception 'not_member';
  end if;

  select ric.code, ric.expires_at
  into v_existing_code, v_existing_expires_at
  from public.room_invite_codes ric
  join public.rooms r on r.id = ric.room_id
  where ric.room_id = p_room_id
    and ric.revoked_at is null
    and ric.expires_at > now()
    and r.is_archived = false
  order by ric.created_at desc
  limit 1;

  if v_existing_code is not null then
    update public.rooms
    set invite_code = v_existing_code,
        invite_expires_at = v_existing_expires_at
    where id = p_room_id
      and (
        invite_code is distinct from v_existing_code
        or invite_expires_at is distinct from v_existing_expires_at
      );

    return v_existing_code;
  end if;

  v_expires_at := now() + make_interval(
    mins => greatest(5, least(coalesce(p_expires_in_minutes, 1440), 60 * 24 * 365))
  );

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

    if v_attempts >= 40 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into public.room_invite_codes (
    room_id,
    code,
    created_by,
    expires_at
  ) values (
    p_room_id,
    v_code,
    auth.uid(),
    v_expires_at
  );

  update public.rooms
  set invite_code = v_code,
      invite_expires_at = v_expires_at
  where id = p_room_id;

  return v_code;
end;
$$;

grant execute on function public.get_or_create_room_invite_code(uuid, int)
to authenticated;

create or replace function public.regenerate_invite_code(p_room_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1
    from public.room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.role = 'owner'
      and rm.is_active
  ) then
    raise exception 'not_owner';
  end if;

  return public.create_room_invite_code(p_room_id, 1440);
end;
$$;

grant execute on function public.regenerate_invite_code(uuid)
to authenticated;

create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
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

  select ptn.name
  into v_room_timezone
  from pg_timezone_names ptn
  where ptn.name = coalesce(v_room_timezone, 'UTC')
  limit 1;

  if v_room_timezone is null then
    v_room_timezone := 'UTC';
  end if;

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
$$;

grant execute on function public.create_room(text)
to authenticated;

-- Cap currently valid codes at 24 hours from this rollout. This gives shared
-- links a bounded transition window instead of expiring every older code
-- immediately based on its original creation time.
with active_codes as (
  update public.room_invite_codes
  set expires_at = least(expires_at, now() + interval '24 hours')
  where revoked_at is null
    and expires_at > now()
  returning room_id, code, expires_at
)
update public.rooms r
set invite_expires_at = active_codes.expires_at
from active_codes
where r.id = active_codes.room_id
  and r.invite_code = active_codes.code;

-- Keep legacy room-only invite rows bounded too.
update public.rooms
set invite_expires_at = least(
  coalesce(invite_expires_at, now() + interval '24 hours'),
  now() + interval '24 hours'
)
where invite_expires_at is null
   or invite_expires_at > now() + interval '24 hours';
