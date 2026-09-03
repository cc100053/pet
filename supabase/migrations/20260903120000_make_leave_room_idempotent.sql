-- Make leave_room idempotent.
--
-- Crashlytics 3.0.2 (22), event 2026-09-02T14:20:14Z: leave_room raised
-- 'not_member' for a room the user had already left at 12:13:01Z, after the app
-- was background-terminated and relaunched with a stale room list. The client
-- surfaced it as "leave failed / permission denied" for an action that had in
-- fact already happened.
--
-- Leaving a room you are not in is the desired end state, not an error. The
-- signature, return type and side effects are unchanged, so released builds are
-- unaffected: they simply stop getting an exception on a redundant leave.
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

  update room_members
  set is_active = false,
      left_at = now(),
      role = case when role = 'owner' then 'member' else role end
  where room_id = p_room_id
    and user_id = auth.uid()
    and is_active;
end;
$$;

grant execute on function public.leave_room(uuid) to authenticated;
