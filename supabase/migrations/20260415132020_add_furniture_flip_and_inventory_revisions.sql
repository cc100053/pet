begin;

alter table public.room_furniture
  add column if not exists flip_x boolean not null default false;

create table if not exists public.room_item_inventory_revisions (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  updated_at timestamptz not null default now()
);

alter table public.room_item_inventory_revisions enable row level security;

drop policy if exists room_item_inventory_revisions_select
  on public.room_item_inventory_revisions;
create policy room_item_inventory_revisions_select
on public.room_item_inventory_revisions
for select
to authenticated
using (
  exists (
    select 1
    from public.room_members rm
    where rm.room_id = room_item_inventory_revisions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
);

alter table public.room_item_inventory_revisions replica identity full;

create or replace function public.touch_room_item_inventory_revision(
  p_room_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_room_id is null then
    return;
  end if;

  insert into public.room_item_inventory_revisions (room_id, updated_at)
  values (p_room_id, now())
  on conflict (room_id)
  do update set updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.touch_room_item_inventory_revision(uuid)
from public;

create or replace function public.handle_room_item_inventory_revision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
begin
  v_room_id := coalesce(new.room_id, old.room_id);
  perform public.touch_room_item_inventory_revision(v_room_id);
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists touch_room_item_inventory_revision
  on public.room_item_inventories;
create trigger touch_room_item_inventory_revision
after insert or update or delete on public.room_item_inventories
for each row execute function public.handle_room_item_inventory_revision();

create or replace function public.update_room_furniture_flip(
  p_id uuid,
  p_flip_x boolean
)
returns public.room_furniture
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.room_furniture%rowtype;
  v_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id
  into v_room_id
  from public.room_furniture
  where id = p_id;

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  update public.room_furniture
  set flip_x = coalesce(p_flip_x, false)
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.update_room_furniture_flip(uuid, boolean)
to authenticated;

do $$
begin
  alter publication supabase_realtime
    add table public.room_item_inventory_revisions;
exception
  when duplicate_object then null;
end $$;

commit;
