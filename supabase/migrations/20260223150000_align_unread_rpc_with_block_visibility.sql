-- Keep unread badge calculations aligned with message visibility rules:
-- exclude messages from users in a mutual block relationship with the target user.

create or replace function public.get_unread_message_total_for_user(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  with target as (
    select
      case
        when (select auth.role()) = 'authenticated' then (select auth.uid())
        else p_user_id
      end as target_user_id,
      (select auth.role()) as caller_role
  )
  select coalesce(count(*), 0)::integer
  from target t
  join public.room_members rm
    on rm.user_id = t.target_user_id
   and rm.is_active = true
  join public.messages m
    on m.room_id = rm.room_id
  where (
      t.caller_role <> 'authenticated'
      or p_user_id = t.target_user_id
    )
    and m.created_at > coalesce(rm.last_read_at, 'epoch'::timestamptz)
    and (
      m.sender_id is null
      or m.sender_id <> t.target_user_id
    )
    and (
      m.sender_id is null
      or not exists (
        select 1
        from public.blocks b
        where (
          b.blocker_id = t.target_user_id
          and b.blocked_user_id = m.sender_id
        ) or (
          b.blocker_id = m.sender_id
          and b.blocked_user_id = t.target_user_id
        )
      )
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
  with target as (
    select
      case
        when (select auth.role()) = 'authenticated' then (select auth.uid())
        else p_user_id
      end as target_user_id,
      (select auth.role()) as caller_role
  )
  select rm.room_id, count(*)::integer as unread_count
  from target t
  join public.room_members rm
    on rm.user_id = t.target_user_id
   and rm.is_active = true
  join public.messages m
    on m.room_id = rm.room_id
  where (
      t.caller_role <> 'authenticated'
      or p_user_id = t.target_user_id
    )
    and m.created_at > coalesce(rm.last_read_at, 'epoch'::timestamptz)
    and (
      m.sender_id is null
      or m.sender_id <> t.target_user_id
    )
    and (
      m.sender_id is null
      or not exists (
        select 1
        from public.blocks b
        where (
          b.blocker_id = t.target_user_id
          and b.blocked_user_id = m.sender_id
        ) or (
          b.blocker_id = m.sender_id
          and b.blocked_user_id = t.target_user_id
        )
      )
    )
  group by rm.room_id;
$$;

revoke all on function public.get_unread_message_counts_for_user(uuid) from public;
grant execute on function public.get_unread_message_counts_for_user(uuid) to authenticated;
