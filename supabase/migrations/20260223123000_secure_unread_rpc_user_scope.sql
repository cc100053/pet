-- Harden unread RPC access: authenticated callers can only query their own unread state.
-- Keep service-role/internal callers functional for server-side notification pipelines.

create or replace function public.get_unread_message_total_for_user(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  select coalesce(count(*), 0)::integer
  from public.room_members rm
  join public.messages m on m.room_id = rm.room_id
  where rm.user_id = case
      when (select auth.role()) = 'authenticated' then (select auth.uid())
      else p_user_id
    end
    and rm.is_active = true
    and (
      (select auth.role()) <> 'authenticated'
      or p_user_id = (select auth.uid())
    )
    and m.created_at > coalesce(rm.last_read_at, 'epoch'::timestamptz)
    and (
      m.sender_id is null
      or m.sender_id <> case
        when (select auth.role()) = 'authenticated' then (select auth.uid())
        else p_user_id
      end
    );
$$;

revoke all on function public.get_unread_message_total_for_user(uuid) from public;
grant execute on function public.get_unread_message_total_for_user(uuid) to authenticated;

create or replace function public.get_unread_message_counts_for_user(p_user_id uuid)
returns table(room_id uuid, unread_count integer)
language sql
security definer
set search_path = public
as $$
  select rm.room_id, count(*)::integer as unread_count
  from public.room_members rm
  join public.messages m on m.room_id = rm.room_id
  where rm.user_id = case
      when (select auth.role()) = 'authenticated' then (select auth.uid())
      else p_user_id
    end
    and rm.is_active = true
    and (
      (select auth.role()) <> 'authenticated'
      or p_user_id = (select auth.uid())
    )
    and m.created_at > coalesce(rm.last_read_at, 'epoch'::timestamptz)
    and (
      m.sender_id is null
      or m.sender_id <> case
        when (select auth.role()) = 'authenticated' then (select auth.uid())
        else p_user_id
      end
    )
  group by rm.room_id;
$$;

revoke all on function public.get_unread_message_counts_for_user(uuid) from public;
grant execute on function public.get_unread_message_counts_for_user(uuid) to authenticated;
