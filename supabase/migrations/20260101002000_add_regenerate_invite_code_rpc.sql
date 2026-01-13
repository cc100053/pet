-- Add regenerate_invite_code RPC

create or replace function public.regenerate_invite_code(p_room_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1 from room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.role = 'owner'
      and rm.is_active
  ) then
    raise exception 'not_owner';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from rooms where invite_code = v_code);
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  update rooms
  set invite_code = v_code,
      invite_expires_at = now() + interval '60 minutes'
  where id = p_room_id;

  return v_code;
end;
$$;

grant execute on function public.regenerate_invite_code(uuid) to authenticated;
