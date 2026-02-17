alter table public.room_members
  add column if not exists last_read_at timestamptz;

update public.room_members
set last_read_at = coalesce(last_read_at, now())
where is_active = true;

create index if not exists room_members_user_room_active_last_read_idx
  on public.room_members (user_id, room_id, is_active, last_read_at);

create or replace function public.mark_room_read(p_room_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_latest_message_at timestamptz;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select max(created_at)
  into v_latest_message_at
  from public.messages
  where room_id = p_room_id;

  update public.room_members rm
  set last_read_at = coalesce(v_latest_message_at, now())
  where rm.room_id = p_room_id
    and rm.user_id = v_uid
    and rm.is_active = true;

  if not found then
    raise exception 'ROOM_MEMBER_NOT_FOUND';
  end if;
end;
$$;

grant execute on function public.mark_room_read(uuid) to authenticated;

create or replace function public.get_unread_message_total_for_user(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.room_members rm
  join public.messages m on m.room_id = rm.room_id
  where rm.user_id = p_user_id
    and rm.is_active = true
    and m.created_at > coalesce(rm.last_read_at, 'epoch'::timestamptz)
    and (m.sender_id is null or m.sender_id <> p_user_id);
$$;

grant execute on function public.get_unread_message_total_for_user(uuid) to authenticated;
