begin;

create table if not exists public.room_item_inventories (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  quantity int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id, item_id),
  constraint room_item_inventories_quantity_check check (quantity >= 0)
);

create index if not exists room_item_inventories_user_idx
  on public.room_item_inventories (user_id, room_id);

create index if not exists room_item_inventories_room_item_idx
  on public.room_item_inventories (room_id, item_id);

drop trigger if exists set_room_item_inventories_updated_at on public.room_item_inventories;
create trigger set_room_item_inventories_updated_at
before update on public.room_item_inventories
for each row execute function public.set_updated_at();

alter table public.room_item_inventories enable row level security;

drop policy if exists room_item_inventories_select on public.room_item_inventories;
create policy room_item_inventories_select on public.room_item_inventories
for select using (
  user_id = auth.uid()
  and public.is_room_member(room_id)
);

drop policy if exists room_item_inventories_insert on public.room_item_inventories;
create policy room_item_inventories_insert on public.room_item_inventories
for insert with check (
  user_id = auth.uid()
  and public.is_room_member(room_id)
);

drop policy if exists room_item_inventories_update on public.room_item_inventories;
create policy room_item_inventories_update on public.room_item_inventories
for update using (
  user_id = auth.uid()
  and public.is_room_member(room_id)
)
with check (
  user_id = auth.uid()
  and public.is_room_member(room_id)
);

create or replace function public.purchase_room_furniture_with_coins(
  p_room_id uuid,
  p_item_id uuid
)
returns table (remaining_coins int, new_quantity int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_coins int;
  v_new_quantity int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_coins into v_price
  from public.items
  where id = p_item_id
    and is_active
    and (metadata->>'category') = 'furniture';

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  select coins
  into v_current_coins
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_coins is null then
    raise exception 'profile_missing';
  end if;

  if v_current_coins < v_price then
    raise exception 'insufficient_coins';
  end if;

  update public.profiles
  set coins = coins - v_price
  where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = room_item_inventories.quantity + 1;

  select quantity into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  return query select (v_current_coins - v_price), coalesce(v_new_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_furniture_with_coins(uuid, uuid) to authenticated;

create or replace function public.purchase_room_furniture_with_diamonds(
  p_room_id uuid,
  p_item_id uuid
)
returns table (remaining_diamonds int, new_quantity int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_new_quantity int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_diamonds into v_price
  from public.items
  where id = p_item_id
    and is_active
    and (metadata->>'category') = 'furniture';

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select diamonds
  into v_current_diamonds
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  if v_current_diamonds < v_price then
    raise exception 'insufficient_diamonds';
  end if;

  update public.profiles
  set diamonds = diamonds - v_price
  where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = room_item_inventories.quantity + 1;

  select quantity into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  return query select (v_current_diamonds - v_price), coalesce(v_new_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_furniture_with_diamonds(uuid, uuid) to authenticated;

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
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
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
end;
$$;

commit;
