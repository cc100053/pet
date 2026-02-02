-- Add diamond currency support.

alter table profiles
  add column if not exists diamonds int not null default 0;

alter table items
  add column if not exists price_diamonds int;

create table if not exists diamond_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  room_id uuid references rooms(id) on delete set null,
  source text not null,
  amount int not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint diamond_ledger_source check (
    source in ('iap_purchase', 'store_purchase', 'exchange', 'admin_adjust')
  )
);

create index if not exists diamond_ledger_user_created_at_idx
  on diamond_ledger (user_id, created_at desc);

alter table diamond_ledger enable row level security;

create policy diamond_ledger_select on diamond_ledger
for select using (user_id = auth.uid());

create policy diamond_ledger_insert on diamond_ledger
for insert with check (user_id = auth.uid());

-- Expand coin_ledger sources for diamond exchange.
alter table coin_ledger
  drop constraint if exists coin_ledger_source;

alter table coin_ledger
  add constraint coin_ledger_source check (
    source in (
      'feed',
      'touch',
      'clean',
      'ad_reward',
      'quest',
      'store_purchase',
      'iap_purchase',
      'diamond_exchange'
    )
  );

-- RPC: grant diamonds for an IAP transaction (idempotent by transaction_id).
create or replace function public.grant_iap_diamonds(
  p_product_id text,
  p_amount int,
  p_transaction_id text
)
returns table (new_balance int, added int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  if p_product_id is null or length(p_product_id) = 0 then
    raise exception 'invalid_product';
  end if;

  if p_transaction_id is null or length(p_transaction_id) = 0 then
    raise exception 'invalid_transaction';
  end if;

  begin
    insert into iap_transactions (user_id, product_id, transaction_id)
    values (auth.uid(), p_product_id, p_transaction_id);
  exception when unique_violation then
    select diamonds into v_current
    from profiles
    where user_id = auth.uid();
    return query select coalesce(v_current, 0), 0;
  end;

  update profiles
  set diamonds = diamonds + p_amount
  where user_id = auth.uid();

  if not found then
    raise exception 'profile_missing';
  end if;

  insert into diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    null,
    'iap_purchase',
    p_amount,
    jsonb_build_object('product_id', p_product_id, 'transaction_id', p_transaction_id)
  );

  select diamonds into v_current
  from profiles
  where user_id = auth.uid();

  return query select coalesce(v_current, 0), p_amount;
end;
$$;

grant execute on function public.grant_iap_diamonds(text, int, text) to authenticated;

-- RPC: purchase item with diamonds (supports diamond-to-coin exchange items).
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
  from items
  where id = p_item_id
    and is_active;

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
    from inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    if v_existing_qty is not null and v_existing_qty > 0 then
      raise exception 'already_owned';
    end if;
    v_final_qty := 1;
  elsif v_type = 'consumable' then
    if not v_is_exchange then
      select quantity into v_existing_qty
      from inventories
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
  from profiles
  where user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  if v_current_diamonds < v_total then
    raise exception 'insufficient_diamonds';
  end if;

  update profiles
  set diamonds = diamonds - v_total
  where user_id = auth.uid();

  if not v_is_exchange then
    insert into inventories (user_id, item_id, quantity)
    values (auth.uid(), p_item_id, v_final_qty)
    on conflict (user_id, item_id)
    do update set quantity = excluded.quantity;
  else
    v_coin_total := v_coin_amount * p_quantity;
    update profiles
    set coins = coins + v_coin_total
    where user_id = auth.uid();

    insert into coin_ledger (user_id, room_id, source, amount, metadata)
    values (
      auth.uid(),
      null,
      'diamond_exchange',
      v_coin_total,
      jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity)
    );

    select coins into v_new_coin_balance
    from profiles
    where user_id = auth.uid();
  end if;

  insert into diamond_ledger (user_id, room_id, source, amount, metadata)
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
