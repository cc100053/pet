begin;

-- Equipment purchase capacity must scale with the room's TOTAL pet count.
-- After extras moved to room_extra_pets, the capacity check (which counted
-- only `pets`, always 1) treated owning a single copy as fully owned, so the
-- shop hid the buy button for a 2-pet room. Count both tables.
create or replace function public.room_pet_count(p_room_id uuid)
returns int
language sql
stable
set search_path = public
as $$
  select greatest(
    1,
    (select count(*) from public.pets where room_id = p_room_id)
    + (select count(*) from public.room_extra_pets where room_id = p_room_id)
  )::int;
$$;

grant execute on function public.room_pet_count(uuid) to authenticated, service_role;

create or replace function public.purchase_room_equipment_with_coins(
  p_room_id uuid, p_item_id uuid
)
returns table (remaining_coins int, new_quantity int, room_total_quantity int)
language plpgsql security definer set search_path = public
as $$
declare
  v_price int;
  v_current_coins int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_pet_count int;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not public.is_room_member(p_room_id) then raise exception 'not_room_member'; end if;
  perform 1 from public.rooms where id = p_room_id for update;

  select price_coins into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (coalesce(is_active, false) = true and coalesce(metadata->>'visibility_mode', 'public') = 'public')
      or (coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
          and coalesce(metadata->>'shop_visibility', '') <> 'hidden')
    );
  if v_price is null then raise exception 'item_not_for_coins'; end if;

  v_pet_count := public.room_pet_count(p_room_id);

  select coalesce(sum(quantity), 0)::int into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) >= v_pet_count then
    raise exception 'equipment_capacity_reached';
  end if;

  select coins into v_current_coins from public.profiles where user_id = auth.uid() for update;
  if v_current_coins is null then raise exception 'profile_missing'; end if;
  if v_current_coins < v_price then raise exception 'insufficient_coins'; end if;

  update public.profiles set coins = coins - v_price where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = public.room_item_inventories.quantity + 1;

  select quantity into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id and user_id = auth.uid() and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id and item_id = p_item_id;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (auth.uid(), p_room_id, 'store_purchase', -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1));

  return query select (v_current_coins - v_price), coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_coins(uuid, uuid) to authenticated;

create or replace function public.purchase_room_equipment_with_diamonds(
  p_room_id uuid, p_item_id uuid
)
returns table (remaining_diamonds int, new_quantity int, room_total_quantity int)
language plpgsql security definer set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_pet_count int;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not public.is_room_member(p_room_id) then raise exception 'not_room_member'; end if;
  perform 1 from public.rooms where id = p_room_id for update;

  select price_diamonds into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (coalesce(is_active, false) = true and coalesce(metadata->>'visibility_mode', 'public') = 'public')
      or (coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
          and coalesce(metadata->>'shop_visibility', '') <> 'hidden')
    );
  if v_price is null then raise exception 'item_not_for_diamonds'; end if;

  v_pet_count := public.room_pet_count(p_room_id);

  select coalesce(sum(quantity), 0)::int into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) >= v_pet_count then
    raise exception 'equipment_capacity_reached';
  end if;

  select diamonds into v_current_diamonds from public.profiles where user_id = auth.uid() for update;
  if v_current_diamonds is null then raise exception 'profile_missing'; end if;
  if v_current_diamonds < v_price then raise exception 'insufficient_diamonds'; end if;

  update public.profiles set diamonds = diamonds - v_price where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = public.room_item_inventories.quantity + 1;

  select quantity into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id and user_id = auth.uid() and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id and item_id = p_item_id;

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (auth.uid(), p_room_id, 'store_purchase', -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1));

  return query select (v_current_diamonds - v_price), coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_diamonds(uuid, uuid) to authenticated;

commit;
