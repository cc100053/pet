begin;

create table if not exists public.room_furniture (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  item_id uuid not null references public.items(id),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  position_x numeric not null default 0,
  position_y numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint room_furniture_position_x check (position_x >= 0 and position_x <= 1),
  constraint room_furniture_position_y check (position_y >= 0 and position_y <= 1)
);

create index if not exists room_furniture_room_id_idx
  on public.room_furniture(room_id);

create index if not exists room_furniture_owner_idx
  on public.room_furniture(owner_user_id);

drop trigger if exists set_room_furniture_updated_at on public.room_furniture;
create trigger set_room_furniture_updated_at
before update on public.room_furniture
for each row execute function public.set_updated_at();

alter table public.room_furniture enable row level security;

drop policy if exists room_furniture_select on public.room_furniture;
create policy room_furniture_select on public.room_furniture
for select using (public.is_room_member(room_id));

drop policy if exists room_furniture_insert on public.room_furniture;
create policy room_furniture_insert on public.room_furniture
for insert with check (
  owner_user_id = auth.uid()
  and public.is_room_member(room_id)
  and exists (
    select 1 from public.items
    where items.id = room_furniture.item_id
      and items.is_active
      and (items.metadata->>'category') = 'furniture'
  )
);

drop policy if exists room_furniture_update on public.room_furniture;
create policy room_furniture_update on public.room_furniture
for update using (
  owner_user_id = auth.uid()
  and public.is_room_member(room_id)
);

drop policy if exists room_furniture_delete on public.room_furniture;
create policy room_furniture_delete on public.room_furniture
for delete using (
  owner_user_id = auth.uid()
  and public.is_room_member(room_id)
);

alter table public.room_furniture replica identity full;

-- Enable realtime updates for room_furniture (safe if already enabled).
do $$
begin
  alter publication supabase_realtime add table public.room_furniture;
exception
  when duplicate_object then null;
end $$;

create or replace function public.place_room_furniture(
  p_room_id uuid,
  p_item_id uuid,
  p_position_x numeric,
  p_position_y numeric
)
returns public.room_furniture
language plpgsql
security definer
set search_path = public
as $$
declare
  v_qty int;
  v_placed int;
  v_is_furniture boolean;
  v_row public.room_furniture%rowtype;
  v_x numeric;
  v_y numeric;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select (metadata->>'category') = 'furniture'
  into v_is_furniture
  from public.items
  where id = p_item_id
    and is_active;

  if v_is_furniture is distinct from true then
    raise exception 'item_not_furniture';
  end if;

  select quantity into v_qty
  from public.inventories
  where user_id = auth.uid()
    and item_id = p_item_id;

  v_qty := coalesce(v_qty, 0);

  select count(*)
  into v_placed
  from public.room_furniture
  where room_id = p_room_id
    and item_id = p_item_id
    and owner_user_id = auth.uid();

  if v_qty <= v_placed then
    raise exception 'insufficient_inventory';
  end if;

  v_x := least(greatest(p_position_x, 0), 1);
  v_y := least(greatest(p_position_y, 0), 1);

  insert into public.room_furniture (
    room_id,
    item_id,
    owner_user_id,
    position_x,
    position_y
  ) values (
    p_room_id,
    p_item_id,
    auth.uid(),
    v_x,
    v_y
  )
  returning * into v_row;

  return v_row;
end $$;

create or replace function public.update_room_furniture_position(
  p_id uuid,
  p_position_x numeric,
  p_position_y numeric
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

  select room_id into v_room_id
  from public.room_furniture
  where id = p_id
    and owner_user_id = auth.uid();

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  update public.room_furniture
  set position_x = least(greatest(p_position_x, 0), 1),
      position_y = least(greatest(p_position_y, 0), 1)
  where id = p_id
    and owner_user_id = auth.uid()
  returning * into v_row;

  return v_row;
end $$;

create or replace function public.remove_room_furniture(
  p_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_deleted uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id into v_room_id
  from public.room_furniture
  where id = p_id
    and owner_user_id = auth.uid();

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  delete from public.room_furniture
  where id = p_id
    and owner_user_id = auth.uid()
  returning id into v_deleted;

  return v_deleted is not null;
end $$;

commit;
