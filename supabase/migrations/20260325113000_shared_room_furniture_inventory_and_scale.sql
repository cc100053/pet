begin;

alter table public.room_furniture
  add column if not exists scale numeric not null default 1.0;

update public.room_furniture
set scale = 1.0
where scale is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'room_furniture_scale_range'
      and conrelid = 'public.room_furniture'::regclass
  ) then
    alter table public.room_furniture
      add constraint room_furniture_scale_range
      check (scale >= 0.8 and scale <= 1.6);
  end if;
end $$;

create index if not exists room_furniture_room_item_idx
  on public.room_furniture(room_id, item_id);

create or replace function public.get_room_furniture_inventory(
  p_room_id uuid
)
returns table (item_id uuid, total_quantity int)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  return query
  select
    rii.item_id,
    coalesce(sum(rii.quantity), 0)::int as total_quantity
  from public.room_item_inventories rii
  where rii.room_id = p_room_id
  group by rii.item_id;
end;
$$;

grant execute on function public.get_room_furniture_inventory(uuid) to authenticated;

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

  select coalesce(sum(quantity), 0)::int
  into v_qty
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  select count(*)::int
  into v_placed
  from public.room_furniture
  where room_id = p_room_id
    and item_id = p_item_id;

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
    position_y,
    scale
  ) values (
    p_room_id,
    p_item_id,
    auth.uid(),
    v_x,
    v_y,
    1.0
  )
  returning * into v_row;

  return v_row;
end;
$$;

create or replace function public.update_room_furniture_scale(
  p_id uuid,
  p_scale numeric
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
  set scale = least(greatest(coalesce(p_scale, 1.0), 0.8), 1.6)
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.update_room_furniture_scale(uuid, numeric) to authenticated;

drop function if exists public.purchase_room_furniture_with_coins(uuid, uuid);
create function public.purchase_room_furniture_with_coins(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_coins int,
  new_quantity int,
  room_total_quantity int,
  message_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_coins int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_nickname text;
  v_pet_name text;
  v_item_sku text;
  v_message_id uuid;
  v_message_body text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_coins, sku
  into v_price, v_item_sku
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

  select quantity
  into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  select coalesce(nullif(trim(nickname), ''), 'Someone')
  into v_nickname
  from public.profiles
  where user_id = auth.uid();

  select coalesce(nullif(trim(name), ''), 'the pet')
  into v_pet_name
  from public.pets
  where room_id = p_room_id;

  v_message_body := json_build_object(
    'kind', 'store_purchase',
    'user_id', auth.uid(),
    'user_name', coalesce(v_nickname, 'Someone'),
    'pet_name', coalesce(v_pet_name, 'the pet'),
    'item_sku', coalesce(v_item_sku, ''),
    'item_category', 'furniture'
  )::text;

  insert into public.messages (room_id, sender_id, type, body)
  values (p_room_id, null, 'system', v_message_body)
  returning id into v_message_id;

  return query
  select
    (v_current_coins - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0),
    v_message_id;
end;
$$;

grant execute on function public.purchase_room_furniture_with_coins(uuid, uuid) to authenticated;

drop function if exists public.purchase_room_furniture_with_diamonds(uuid, uuid);
create function public.purchase_room_furniture_with_diamonds(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_diamonds int,
  new_quantity int,
  room_total_quantity int,
  message_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_nickname text;
  v_pet_name text;
  v_item_sku text;
  v_message_id uuid;
  v_message_body text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_diamonds, sku
  into v_price, v_item_sku
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

  select quantity
  into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  select coalesce(nullif(trim(nickname), ''), 'Someone')
  into v_nickname
  from public.profiles
  where user_id = auth.uid();

  select coalesce(nullif(trim(name), ''), 'the pet')
  into v_pet_name
  from public.pets
  where room_id = p_room_id;

  v_message_body := json_build_object(
    'kind', 'store_purchase',
    'user_id', auth.uid(),
    'user_name', coalesce(v_nickname, 'Someone'),
    'pet_name', coalesce(v_pet_name, 'the pet'),
    'item_sku', coalesce(v_item_sku, ''),
    'item_category', 'furniture'
  )::text;

  insert into public.messages (room_id, sender_id, type, body)
  values (p_room_id, null, 'system', v_message_body)
  returning id into v_message_id;

  return query
  select
    (v_current_diamonds - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0),
    v_message_id;
end;
$$;

grant execute on function public.purchase_room_furniture_with_diamonds(uuid, uuid) to authenticated;

commit;
