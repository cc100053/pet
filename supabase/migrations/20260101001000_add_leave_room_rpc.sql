-- Add leave_room RPC

create or replace function public.leave_room(p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1 from room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  ) then
    raise exception 'not_member';
  end if;

  update room_members
  set is_active = false,
      left_at = now(),
      role = case when role = 'owner' then 'member' else role end
  where room_id = p_room_id
    and user_id = auth.uid();
end;
$$;

grant execute on function public.leave_room(uuid) to authenticated;
