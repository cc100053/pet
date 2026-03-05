-- When a room already has 3 active invite codes, rotate the oldest active code
-- regardless of whether the caller is owner or member.

create or replace function public.create_room_invite_code(
  p_room_id uuid,
  p_expires_in_minutes int default 60
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
    mins => greatest(5, least(coalesce(p_expires_in_minutes, 60), 60 * 24 * 7))
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

grant execute on function public.create_room_invite_code(uuid, int) to authenticated;
