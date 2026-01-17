-- Track IAP transaction IDs to avoid double-granting coins.
create table if not exists iap_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  transaction_id text not null unique,
  created_at timestamptz not null default now()
);

alter table iap_transactions enable row level security;

create policy iap_transactions_select on iap_transactions
for select using (user_id = auth.uid());

create policy iap_transactions_insert on iap_transactions
for insert with check (user_id = auth.uid());

-- Expand coin_ledger sources for IAP purchases.
alter table coin_ledger
  drop constraint if exists coin_ledger_source;

alter table coin_ledger
  add constraint coin_ledger_source check (
    source in ('feed', 'touch', 'clean', 'ad_reward', 'quest', 'store_purchase', 'iap_purchase')
  );

-- RPC: grant coins for an IAP transaction (idempotent by transaction_id).
create or replace function public.grant_iap_coins(
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
    select coins into v_current
    from profiles
    where user_id = auth.uid();
    return query select coalesce(v_current, 0), 0;
  end;

  update profiles
  set coins = coins + p_amount
  where user_id = auth.uid();

  if not found then
    raise exception 'profile_missing';
  end if;

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    null,
    'iap_purchase',
    p_amount,
    jsonb_build_object('product_id', p_product_id, 'transaction_id', p_transaction_id)
  );

  select coins into v_current
  from profiles
  where user_id = auth.uid();

  return query select coalesce(v_current, 0), p_amount;
end;
$$;

grant execute on function public.grant_iap_coins(text, int, text) to authenticated;
