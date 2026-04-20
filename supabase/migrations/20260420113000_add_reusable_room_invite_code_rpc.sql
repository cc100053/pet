create or replace function public.get_or_create_room_invite_code(
  p_room_id uuid,
  p_expires_in_minutes int default 43200
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
    mins => greatest(5, least(coalesce(p_expires_in_minutes, 43200), 60 * 24 * 365))
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
