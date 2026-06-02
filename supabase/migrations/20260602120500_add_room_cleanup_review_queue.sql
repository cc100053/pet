-- Human-in-the-loop review queue for abandoned-room photo cleanup.
--
-- Flow:
--   1. cleanup_abandoned_rooms (mode=scan) finds stale active rooms, counts
--      their R2 photos, and records a candidate row here as 'pending'.
--   2. You review `room_cleanup_review` in Supabase Studio and set
--      review_status = 'approved' (or 'rejected') on each row.
--   3. cleanup_abandoned_rooms (mode=purge) deletes R2 photos ONLY for
--      candidates with review_status = 'approved', then marks them 'purged'.
--
-- Nothing is ever deleted without an explicit 'approved' status.

-- 1) Review queue -----------------------------------------------------------
create table if not exists room_cleanup_candidates (
  room_id          uuid primary key references rooms(id) on delete cascade,
  review_status    text not null default 'pending',
  photo_count      integer not null default 0,
  photo_bytes      bigint  not null default 0,
  last_activity_at timestamptz,
  detected_at      timestamptz not null default now(),
  last_scanned_at  timestamptz not null default now(),
  reviewed_at      timestamptz,
  purged_at        timestamptz,
  purged_count     integer,
  note             text,
  constraint room_cleanup_review_status_check
    check (review_status in ('pending', 'approved', 'rejected', 'purged'))
);

create index if not exists room_cleanup_candidates_status_idx
  on room_cleanup_candidates (review_status);

-- Auto-stamp reviewed_at when you approve / reject in Studio.
create or replace function public.set_room_cleanup_reviewed_at()
returns trigger
language plpgsql
as $$
begin
  if new.review_status is distinct from old.review_status
     and new.review_status in ('approved', 'rejected') then
    new.reviewed_at = now();
  end if;
  return new;
end
$$;

drop trigger if exists trg_room_cleanup_reviewed_at on room_cleanup_candidates;
create trigger trg_room_cleanup_reviewed_at
before update on room_cleanup_candidates
for each row execute function public.set_room_cleanup_reviewed_at();

-- 2) Upsert RPC used by the scan job (preserves review_status) ---------------
create or replace function public.record_room_cleanup_candidate(
  p_room_id uuid,
  p_photo_count integer,
  p_photo_bytes bigint,
  p_last_activity timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into room_cleanup_candidates (
    room_id, photo_count, photo_bytes, last_activity_at,
    detected_at, last_scanned_at
  )
  values (
    p_room_id, p_photo_count, p_photo_bytes, p_last_activity,
    now(), now()
  )
  on conflict (room_id) do update
    set photo_count      = excluded.photo_count,
        photo_bytes      = excluded.photo_bytes,
        last_activity_at = excluded.last_activity_at,
        last_scanned_at  = now();
  -- review_status is intentionally NOT touched on conflict.
end
$$;

revoke all on function public.record_room_cleanup_candidate(uuid, integer, bigint, timestamptz)
  from public, anon, authenticated;
grant execute on function public.record_room_cleanup_candidate(uuid, integer, bigint, timestamptz)
  to service_role;

-- 3) Human-readable review view --------------------------------------------
-- Joins the R2 snapshot (candidate row) with live DB evidence:
--   * all_members_left  -> hard proof everyone explicitly left the room
--   * members[]         -> per-user is_active / left_at / last_action_at
--     (last_action_at = that user's most recent message; best available
--      proxy for "last online" since presence is not persisted)
create or replace view room_cleanup_review as
select
  c.room_id,
  r.name as room_name,
  not exists (
    select 1 from room_members rm
    where rm.room_id = c.room_id and rm.is_active
  ) as all_members_left,
  c.photo_count,
  round(c.photo_bytes / 1048576.0, 1) as size_mb,
  c.last_activity_at,
  extract(day from now() - c.last_activity_at)::int as inactive_days,
  (
    select jsonb_agg(
      jsonb_build_object(
        'nickname', p.nickname,
        'is_active', rm.is_active,
        'left_at', rm.left_at,
        'last_action_at', (
          select max(m.created_at)
          from messages m
          where m.room_id = c.room_id and m.sender_id = rm.user_id
        )
      )
      order by rm.is_active desc, rm.joined_at
    )
    from room_members rm
    left join profiles p on p.user_id = rm.user_id
    where rm.room_id = c.room_id
  ) as members,
  c.review_status,
  c.detected_at,
  c.last_scanned_at,
  c.purged_at,
  c.purged_count,
  c.note
from room_cleanup_candidates c
join rooms r on r.id = c.room_id
order by
  case c.review_status
    when 'pending' then 0 when 'approved' then 1
    when 'rejected' then 2 else 3 end,
  c.last_activity_at;

-- Admin-only data: keep it OUT of the public API. Accessible via Supabase
-- Studio (which connects with elevated privileges), not via PostgREST.
revoke all on table room_cleanup_candidates from anon, authenticated;
revoke all on room_cleanup_review from anon, authenticated;
grant all on table room_cleanup_candidates to service_role;
grant select on room_cleanup_review to service_role;
