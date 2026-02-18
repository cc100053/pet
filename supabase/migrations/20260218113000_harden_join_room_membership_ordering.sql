-- Prevent invite rejoin from mutating historical room ordering.
-- Reactivation should preserve the original joined_at timestamp.

create or replace function public.join_room_by_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select id into v_room_id
  from rooms
  where invite_code = code
    and (invite_expires_at is null or invite_expires_at > now())
    and is_archived = false
  limit 1;

  if v_room_id is null then
    raise exception 'invalid_invite';
  end if;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'member', now(), true)
  on conflict (room_id, user_id)
  do update
  set is_active = true,
      left_at = null;

  return v_room_id;
end;
$$;
