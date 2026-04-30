begin;

alter table public.pet_equipment
  drop constraint if exists pet_equipment_unique_slot;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'pet_equipment_unique_room_pet_slot'
      and conrelid = 'public.pet_equipment'::regclass
  ) then
    alter table public.pet_equipment
      add constraint pet_equipment_unique_room_pet_slot
      unique (room_id, pet_id, slot);
  end if;
end $$;

create index if not exists pet_equipment_room_pet_slot_idx
  on public.pet_equipment (room_id, pet_id, slot);

insert into public.room_item_inventories (
  room_id,
  user_id,
  item_id,
  quantity
)
select
  pe.room_id,
  coalesce(pe.equipped_by, fallback_member.user_id),
  pe.item_id,
  1
from public.pet_equipment pe
join public.items i
  on i.id = pe.item_id
  and i.metadata->>'category' = 'equipment'
left join lateral (
  select rm.user_id
  from public.room_members rm
  where rm.room_id = pe.room_id
    and rm.is_active
  order by (rm.role = 'owner') desc, rm.joined_at
  limit 1
) fallback_member on true
where coalesce(pe.equipped_by, fallback_member.user_id) is not null
on conflict (room_id, user_id, item_id)
do update set quantity = greatest(public.room_item_inventories.quantity, excluded.quantity);

create or replace function public.get_room_equipment_inventory(
  p_room_id uuid
)
returns table (
  id uuid,
  sku text,
  type text,
  name text,
  price_coins int,
  price_diamonds int,
  price_usd numeric,
  metadata jsonb,
  is_active boolean,
  total_quantity int
)
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
    i.id,
    i.sku,
    i.type,
    i.name,
    i.price_coins,
    i.price_diamonds,
    i.price_usd,
    i.metadata,
    i.is_active,
    coalesce(sum(rii.quantity), 0)::int as total_quantity
  from public.room_item_inventories rii
  join public.items i
    on i.id = rii.item_id
  where rii.room_id = p_room_id
    and rii.quantity > 0
    and i.metadata->>'category' = 'equipment'
  group by
    i.id,
    i.sku,
    i.type,
    i.name,
    i.price_coins,
    i.price_diamonds,
    i.price_usd,
    i.metadata,
    i.is_active
  order by i.sku;
end;
$$;

grant execute on function public.get_room_equipment_inventory(uuid) to authenticated;

create or replace function public.get_pet_equipment(
  p_pet_id uuid,
  p_room_id uuid
)
returns table (
  slot text,
  item_id uuid,
  item_sku text,
  equipped_at timestamptz,
  equipped_by uuid
)
language plpgsql
stable
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1
    from public.pets
    where id = p_pet_id
      and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  return query
  select
    pe.slot,
    pe.item_id,
    i.sku as item_sku,
    pe.equipped_at,
    pe.equipped_by
  from public.pet_equipment pe
  join public.items i
    on i.id = pe.item_id
  where pe.pet_id = p_pet_id
    and pe.room_id = p_room_id
  order by pe.slot;
end;
$$;

grant execute on function public.get_pet_equipment(uuid, uuid) to authenticated;

create or replace function public.equip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_item_id uuid,
  p_slot text
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_item_sku text;
  v_global_qty int;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_slot not in ('head', 'body', 'back') then
    raise exception 'invalid_slot';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1
    from public.pets
    where id = p_pet_id
      and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  select sku
  into v_item_sku
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and metadata->>'equipment_slot' = p_slot;

  if v_item_sku is null then
    raise exception 'item_not_equipment_for_slot';
  end if;

  if not exists (
    select 1
    from public.room_item_inventories rii
    where rii.room_id = p_room_id
      and rii.item_id = p_item_id
      and rii.quantity > 0
  ) then
    select quantity
    into v_global_qty
    from public.inventories
    where user_id = v_user_id
      and item_id = p_item_id
      and quantity > 0
    for update;

    if coalesce(v_global_qty, 0) <= 0 then
      raise exception 'item_not_owned_in_room';
    end if;

    insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
    values (p_room_id, v_user_id, p_item_id, 1)
    on conflict (room_id, user_id, item_id)
    do update set quantity = greatest(public.room_item_inventories.quantity, 1);

    if v_global_qty > 1 then
      update public.inventories
      set quantity = v_global_qty - 1
      where user_id = v_user_id
        and item_id = p_item_id;
    else
      delete from public.inventories
      where user_id = v_user_id
        and item_id = p_item_id;
    end if;
  end if;

  insert into public.pet_equipment (
    pet_id,
    room_id,
    item_id,
    slot,
    equipped_by,
    equipped_at
  )
  values (
    p_pet_id,
    p_room_id,
    p_item_id,
    p_slot,
    v_user_id,
    now()
  )
  on conflict (room_id, pet_id, slot)
  do update set
    item_id = excluded.item_id,
    equipped_by = excluded.equipped_by,
    equipped_at = excluded.equipped_at;

  return jsonb_build_object(
    'success', true,
    'slot', p_slot,
    'item_sku', v_item_sku
  );
end;
$$;

grant execute on function public.equip_pet_item(uuid, uuid, uuid, text) to authenticated;

create or replace function public.purchase_room_equipment_with_coins(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_coins int,
  new_quantity int,
  room_total_quantity int
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
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_coins
  into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (
        coalesce(is_active, false) = true
        and coalesce(metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) > 0 then
    raise exception 'already_owned';
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
  do update set quantity = 1;

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

  return query
  select
    (v_current_coins - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_coins(uuid, uuid) to authenticated;

create or replace function public.purchase_room_equipment_with_diamonds(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_diamonds int,
  new_quantity int,
  room_total_quantity int
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
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select price_diamonds
  into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (
        coalesce(is_active, false) = true
        and coalesce(metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) > 0 then
    raise exception 'already_owned';
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
  do update set quantity = 1;

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

  return query
  select
    (v_current_diamonds - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_diamonds(uuid, uuid) to authenticated;

commit;
