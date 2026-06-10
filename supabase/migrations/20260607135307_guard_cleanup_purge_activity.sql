-- Fail closed for human-approved abandoned-room cleanup when a room becomes
-- active again after review. The Edge Function also rechecks live room/R2 state
-- at purge time; this trigger prevents old approvals from being reused later.

create or replace function public.reset_cleanup_candidate_on_room_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.last_activity_at is null or old.last_activity_at is null then
    return new;
  end if;

  if new.last_activity_at > old.last_activity_at then
    update public.room_cleanup_candidates
    set review_status = 'pending',
        reviewed_at = null
    where room_id = new.id
      and review_status = 'approved'
      and (
        last_activity_at is null
        or new.last_activity_at > last_activity_at
      );
  end if;

  return new;
end;
$$;

revoke all on function public.reset_cleanup_candidate_on_room_activity()
  from public, anon, authenticated;
grant execute on function public.reset_cleanup_candidate_on_room_activity()
  to service_role;

drop trigger if exists trg_rooms_cleanup_candidate_activity_reset
  on public.rooms;
create trigger trg_rooms_cleanup_candidate_activity_reset
after update of last_activity_at on public.rooms
for each row
when (new.last_activity_at is distinct from old.last_activity_at)
execute function public.reset_cleanup_candidate_on_room_activity();
