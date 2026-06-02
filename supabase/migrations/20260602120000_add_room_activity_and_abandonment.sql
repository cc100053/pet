-- Room activity tracking + abandonment lifecycle for R2 photo cleanup.
--
-- Context:
--   * Room photos live in Cloudflare R2 under the key prefix `rooms/<room_id>/`.
--   * `rooms` previously had no activity/abandonment columns, so we add them here
--     and keep `last_activity_at` fresh server-side via triggers (no app/client
--     changes required -> old app versions keep working).
--   * The cleanup edge function (`cleanup_abandoned_rooms`) reads these columns
--     with the service role to decide which rooms to purge.

-- 1) Lifecycle columns ------------------------------------------------------
alter table rooms
  add column if not exists last_activity_at timestamptz not null default now(),
  add column if not exists status text not null default 'active',
  add column if not exists abandoned_at timestamptz,
  add column if not exists photos_purged_at timestamptz,
  add column if not exists photos_purged_count integer not null default 0;

-- status check constraint (guarded so the migration is re-runnable)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'rooms_status_check'
  ) then
    alter table rooms
      add constraint rooms_status_check check (status in ('active', 'abandoned'));
  end if;
end
$$;

-- Index to make the "stale active rooms" scan cheap.
create index if not exists rooms_status_last_activity_idx
  on rooms (status, last_activity_at);

-- 2) Backfill last_activity_at from real signals ----------------------------
-- Greatest of: room creation, latest message, latest member join.
update rooms r
set last_activity_at = greatest(
  r.created_at,
  coalesce((select max(m.created_at) from messages m where m.room_id = r.id), r.created_at),
  coalesce((select max(rm.joined_at) from room_members rm where rm.room_id = r.id), r.created_at)
);

-- 3) Trigger to keep last_activity_at fresh ---------------------------------
-- Fires on new messages and on member join / activation changes. Also
-- "revives" a room if it somehow receives activity after being marked
-- abandoned (defensive; should not normally happen).
create or replace function public.touch_room_last_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room uuid := coalesce(new.room_id, old.room_id);
begin
  if v_room is not null then
    update rooms
    set last_activity_at = now(),
        status = case when status = 'abandoned' then 'active' else status end,
        abandoned_at = case when status = 'abandoned' then null else abandoned_at end
    where id = v_room;
  end if;
  return coalesce(new, old);
end
$$;

drop trigger if exists trg_messages_touch_room_activity on messages;
create trigger trg_messages_touch_room_activity
after insert on messages
for each row execute function public.touch_room_last_activity();

drop trigger if exists trg_room_members_touch_room_activity on room_members;
create trigger trg_room_members_touch_room_activity
after insert or update of is_active, joined_at on room_members
for each row execute function public.touch_room_last_activity();

-- 4) Optional manual touch RPC ----------------------------------------------
-- Lets the app (or an edge function) bump activity on events that don't write
-- a row, e.g. a Realtime presence "join". Not required for cleanup to work.
create or replace function public.touch_room_activity(p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update rooms
  set last_activity_at = now(),
      status = case when status = 'abandoned' then 'active' else status end,
      abandoned_at = case when status = 'abandoned' then null else abandoned_at end
  where id = p_room_id
    and exists (
      select 1 from room_members rm
      where rm.room_id = p_room_id
        and rm.user_id = auth.uid()
        and rm.is_active = true
    );
end
$$;

revoke all on function public.touch_room_activity(uuid) from public, anon;
grant execute on function public.touch_room_activity(uuid) to authenticated, service_role;

-- 5) Scheduler auth secret accessor -----------------------------------------
-- Mirrors get_hunger_tick_secret(): the cron job posts this vault secret as a
-- Bearer token; the edge function verifies it via this RPC (service role only).
create or replace function public.get_cleanup_rooms_secret()
returns text
language sql
security definer
set search_path = public, vault
as $$
  select decrypted_secret
  from vault.decrypted_secrets
  where name = 'cleanup_rooms_secret'
  limit 1;
$$;

revoke all on function public.get_cleanup_rooms_secret() from public, anon, authenticated;
grant execute on function public.get_cleanup_rooms_secret() to service_role;
