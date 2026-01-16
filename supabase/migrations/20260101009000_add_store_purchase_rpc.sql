-- Expand coin_ledger sources for store purchases
alter table coin_ledger
  drop constraint if exists coin_ledger_source;

alter table coin_ledger
  add constraint coin_ledger_source check (
    source in ('feed', 'touch', 'clean', 'ad_reward', 'quest', 'store_purchase')
  );

-- RPC: purchase item with coins
create or replace function public.purchase_item_with_coins(
  p_item_id uuid,
  p_quantity int default 1
)
returns table (remaining_coins int, new_quantity int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_type text;
  v_total int;
  v_current_coins int;
  v_existing_qty int;
  v_final_qty int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'invalid_quantity';
  end if;

  select price_coins, type
  into v_price, v_type
  from items
  where id = p_item_id
    and is_active;

  if v_type is null then
    raise exception 'item_not_found';
  end if;

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  if v_type = 'cosmetic' then
    p_quantity := 1;
    select quantity into v_existing_qty
    from inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    if v_existing_qty is not null and v_existing_qty > 0 then
      raise exception 'already_owned';
    end if;
    v_final_qty := 1;
  elsif v_type = 'consumable' then
    select quantity into v_existing_qty
    from inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    v_final_qty := coalesce(v_existing_qty, 0) + p_quantity;
  else
    raise exception 'invalid_item_type';
  end if;

  v_total := v_price * p_quantity;

  select coins
  into v_current_coins
  from profiles
  where user_id = auth.uid()
  for update;

  if v_current_coins is null then
    raise exception 'profile_missing';
  end if;

  if v_current_coins < v_total then
    raise exception 'insufficient_coins';
  end if;

  update profiles
  set coins = coins - v_total
  where user_id = auth.uid();

  insert into inventories (user_id, item_id, quantity)
  values (auth.uid(), p_item_id, v_final_qty)
  on conflict (user_id, item_id)
  do update set quantity = excluded.quantity;

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    null,
    'store_purchase',
    -v_total,
    jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity)
  );

  return query select (v_current_coins - v_total), v_final_qty;
end;
$$;

grant execute on function public.purchase_item_with_coins(uuid, int) to authenticated;
