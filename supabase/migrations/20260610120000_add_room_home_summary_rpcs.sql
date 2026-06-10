-- Additive home-summary RPCs (Phase 4b).
--
-- Backward-compatible: these are brand-new functions. Old app versions keep
-- using their direct PostgREST queries on `messages` / `room_members`; only new
-- clients call these RPCs. Both are SECURITY INVOKER so existing RLS on the
-- underlying tables applies unchanged — a caller sees exactly the rooms they
-- could already read directly, with no widened exposure.
--
-- Why they exist:
--  * get_room_latest_feeds fixes a correctness bug in the old client-side query,
--    which fetched all rooms' feeds under a single global LIMIT heuristic; a
--    chatty room could starve other rooms of their latest photos. This computes
--    the newest distinct-image feeds PER room.
--  * get_room_member_counts returns aggregated counts instead of transferring
--    every member row to the client just to count them.

create or replace function public.get_room_latest_feeds(
  p_room_ids uuid[],
  p_per_room_limit integer default 10
)
returns table (
  room_id uuid,
  id uuid,
  image_url text,
  caption text,
  sender_id uuid,
  created_at timestamptz
)
language sql
security invoker
set search_path = public
stable
as $$
  select f.room_id, f.id, f.image_url, f.caption, f.sender_id, f.created_at
  from unnest(p_room_ids) as r(room_id)
  cross join lateral (
    -- Per room: dedupe by image_url (keep the newest occurrence), then take the
    -- newest N distinct-image feeds. Independent per room, so no cross-room
    -- starvation.
    select d.room_id, d.id, d.image_url, d.caption, d.sender_id, d.created_at
    from (
      select distinct on (m.image_url)
             m.room_id, m.id, m.image_url, m.caption, m.sender_id, m.created_at
      from public.messages m
      where m.room_id = r.room_id
        and m.type = 'image_feed'
        and m.image_url is not null
        and m.image_url <> ''
      order by m.image_url, m.created_at desc, m.id desc
    ) d
    order by d.created_at desc, d.id desc
    limit least(greatest(p_per_room_limit, 0), 50)
  ) f;
$$;

create or replace function public.get_room_member_counts(p_room_ids uuid[])
returns table (
  room_id uuid,
  member_count integer
)
language sql
security invoker
set search_path = public
stable
as $$
  select rm.room_id, count(*)::int as member_count
  from public.room_members rm
  where rm.room_id = any (p_room_ids)
    and rm.is_active
  group by rm.room_id;
$$;

revoke all on function public.get_room_latest_feeds(uuid[], integer)
  from public, anon;
revoke all on function public.get_room_member_counts(uuid[])
  from public, anon;
grant execute on function public.get_room_latest_feeds(uuid[], integer)
  to authenticated;
grant execute on function public.get_room_member_counts(uuid[])
  to authenticated;
