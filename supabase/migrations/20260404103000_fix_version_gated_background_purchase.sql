begin;

create or replace function public.purchase_room_background_with_coins(
  p_room_id uuid,
  p_item_id uuid
)
returns table (remaining_coins int, already_owned boolean, message_id uuid)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_price int;
  v_current_coins int;
  v_owned boolean;
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

  if not exists (
    select 1
    from public.items
    where id = p_item_id
      and (metadata->>'category') = 'background'
      and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      and (
        coalesce(is_active, false) = true
        or coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
      )
  ) then
    raise exception 'item_not_background';
  end if;

  select price_coins, sku
  into v_price, v_item_sku
  from public.items
  where id = p_item_id
    and (metadata->>'category') = 'background'
    and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
    and (
      coalesce(is_active, false) = true
      or coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
    );

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  select coins into v_current_coins
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_coins is null then
    raise exception 'profile_missing';
  end if;

  select exists(
    select 1 from public.room_backgrounds
    where room_id = p_room_id
      and item_id = p_item_id
  ) into v_owned;

  if v_owned then
    return query select v_current_coins, true, null::uuid;
  end if;

  if v_current_coins < v_price then
    raise exception 'insufficient_coins';
  end if;

  update public.profiles
  set coins = coins - v_price
  where user_id = auth.uid();

  insert into public.room_backgrounds (room_id, item_id, acquired_by)
  values (p_room_id, p_item_id, auth.uid())
  on conflict (room_id, item_id) do nothing;

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
    'item_category', 'background'
  )::text;

  insert into public.messages (room_id, sender_id, type, body)
  values (p_room_id, null, 'system', v_message_body)
  returning id into v_message_id;

  return query select (v_current_coins - v_price), false, v_message_id;
end $$;

grant execute on function public.purchase_room_background_with_coins(uuid, uuid) to authenticated;

create or replace function public.purchase_room_background_with_diamonds(
  p_room_id uuid,
  p_item_id uuid
)
returns table (remaining_diamonds int, already_owned boolean, message_id uuid)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_owned boolean;
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

  if not exists (
    select 1
    from public.items
    where id = p_item_id
      and (metadata->>'category') = 'background'
      and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      and (
        coalesce(is_active, false) = true
        or coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
      )
  ) then
    raise exception 'item_not_background';
  end if;

  select price_diamonds, sku
  into v_price, v_item_sku
  from public.items
  where id = p_item_id
    and (metadata->>'category') = 'background'
    and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
    and (
      coalesce(is_active, false) = true
      or coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
    );

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select diamonds into v_current_diamonds
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  select exists(
    select 1 from public.room_backgrounds
    where room_id = p_room_id
      and item_id = p_item_id
  ) into v_owned;

  if v_owned then
    return query select v_current_diamonds, true, null::uuid;
  end if;

  if v_current_diamonds < v_price then
    raise exception 'insufficient_diamonds';
  end if;

  update public.profiles
  set diamonds = diamonds - v_price
  where user_id = auth.uid();

  insert into public.room_backgrounds (room_id, item_id, acquired_by)
  values (p_room_id, p_item_id, auth.uid())
  on conflict (room_id, item_id) do nothing;

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
    'item_category', 'background'
  )::text;

  insert into public.messages (room_id, sender_id, type, body)
  values (p_room_id, null, 'system', v_message_body)
  returning id into v_message_id;

  return query select (v_current_diamonds - v_price), false, v_message_id;
end $$;

grant execute on function public.purchase_room_background_with_diamonds(uuid, uuid) to authenticated;

commit;
