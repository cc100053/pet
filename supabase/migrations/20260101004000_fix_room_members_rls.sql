-- Fix room_members RLS recursion by using a security definer helper.

create or replace function public.is_room_member(p_room_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from room_members
    where room_id = p_room_id
      and user_id = auth.uid()
      and is_active
  );
$$;

drop policy if exists room_members_select on room_members;

create policy room_members_select on room_members
for select using (
  user_id = auth.uid()
  or public.is_room_member(room_id)
);
