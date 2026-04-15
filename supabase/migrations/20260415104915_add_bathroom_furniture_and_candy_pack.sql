begin;

insert into public.items (
  sku,
  type,
  name,
  price_coins,
  price_diamonds,
  price_usd,
  metadata,
  is_active
)
values
  (
    'furniture_toilet',
    'cosmetic',
    'Toilet',
    150,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/toilet.png',
      'price_jpy', 150,
      'description', 'A clean little bathroom piece.',
      'visibility_mode', 'version_gated',
      'min_app_version', '1.1.2',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'furniture_tub',
    'cosmetic',
    'Tub',
    300,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/bathtub.png',
      'price_jpy', 300,
      'description', 'A cozy tub for bath time.',
      'visibility_mode', 'version_gated',
      'min_app_version', '1.1.2',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'diamond_candy_pack_500',
    'consumable',
    '500 Candy Pack',
    null,
    50,
    null,
    jsonb_build_object(
      'category', 'candy_pack',
      'coin_amount', 500,
      'currency', 'DIAMOND',
      'description', 'Exchange 50 diamonds for 500 candy.',
      'visibility_mode', 'version_gated',
      'min_app_version', '1.1.2'
    ),
    false
  )
on conflict (sku) do update
set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_diamonds = excluded.price_diamonds,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

create or replace function public.purchase_item_with_diamonds(
  p_item_id uuid,
  p_quantity int default 1
)
returns table (remaining_diamonds int, new_quantity int, new_coin_balance int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_type text;
  v_total int;
  v_current_diamonds int;
  v_existing_qty int;
  v_final_qty int;
  v_metadata jsonb;
  v_coin_amount int;
  v_coin_total int;
  v_new_coin_balance int;
  v_is_exchange boolean := false;
  v_source text := 'store_purchase';
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'invalid_quantity';
  end if;

  select price_diamonds, type, metadata
  into v_price, v_type, v_metadata
  from public.items
  where id = p_item_id
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

  if v_type is null then
    raise exception 'item_not_found';
  end if;

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  if v_metadata ? 'coin_amount' then
    begin
      v_coin_amount := (v_metadata->>'coin_amount')::int;
    exception when others then
      v_coin_amount := null;
    end;
    if v_coin_amount is not null and v_coin_amount > 0 then
      v_is_exchange := true;
      v_source := 'exchange';
    else
      v_coin_amount := null;
    end if;
  end if;

  if v_type = 'cosmetic' then
    p_quantity := 1;
    select quantity into v_existing_qty
    from public.inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    if v_existing_qty is not null and v_existing_qty > 0 then
      raise exception 'already_owned';
    end if;
    v_final_qty := 1;
  elsif v_type = 'consumable' then
    if not v_is_exchange then
      select quantity into v_existing_qty
      from public.inventories
      where user_id = auth.uid()
        and item_id = p_item_id;
      v_final_qty := coalesce(v_existing_qty, 0) + p_quantity;
    end if;
  elsif v_type = 'subscription' then
    raise exception 'invalid_item_type';
  else
    raise exception 'invalid_item_type';
  end if;

  v_total := v_price * p_quantity;

  select diamonds
  into v_current_diamonds
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  if v_current_diamonds < v_total then
    raise exception 'insufficient_diamonds';
  end if;

  update public.profiles
  set diamonds = diamonds - v_total
  where user_id = auth.uid();

  if not v_is_exchange then
    insert into public.inventories (user_id, item_id, quantity)
    values (auth.uid(), p_item_id, v_final_qty)
    on conflict (user_id, item_id)
    do update set quantity = excluded.quantity;
  else
    v_coin_total := v_coin_amount * p_quantity;
    update public.profiles
    set coins = coins + v_coin_total
    where user_id = auth.uid();

    insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
    values (
      auth.uid(),
      null,
      'diamond_exchange',
      v_coin_total,
      jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity)
    );

    select coins into v_new_coin_balance
    from public.profiles
    where user_id = auth.uid();
  end if;

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    null,
    v_source,
    -v_total,
    jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity)
  );

  return query select (v_current_diamonds - v_total), v_final_qty, v_new_coin_balance;
end;
$$;

grant execute on function public.purchase_item_with_diamonds(uuid, int) to authenticated;

create or replace function public.purchase_room_furniture_with_coins(
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
    and (metadata->>'category') = 'furniture'
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

create or replace function public.purchase_room_furniture_with_diamonds(
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
    and (metadata->>'category') = 'furniture'
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

grant execute on function public.place_room_furniture(uuid, uuid, numeric, numeric) to authenticated;

commit;
