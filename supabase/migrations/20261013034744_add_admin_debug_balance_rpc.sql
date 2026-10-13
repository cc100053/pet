-- Currency stays server-only; the debug drawer may adjust only its admin's
-- own balances. No existing RPC, policy or column grant changes.
create or replace function public.debug_adjust_profile_balances(
  p_coin_delta integer,
  p_diamond_delta integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if not public.is_debug_admin() then
    raise exception 'not_debug_admin' using errcode = '42501';
  end if;
  if p_coin_delta is null or p_diamond_delta is null then
    raise exception 'invalid_balance_delta' using errcode = '22023';
  end if;

  -- One UPDATE serializes concurrent increments; bigint avoids underflow
  -- before clamping at zero. Out-of-range positive balances reject atomically.
  update public.profiles
  set coins = greatest(0::bigint, coins::bigint + p_coin_delta)::integer,
      diamonds = greatest(0::bigint, diamonds::bigint + p_diamond_delta)::integer
  where user_id = v_user_id;
  if not found then
    raise exception 'profile_not_found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.debug_adjust_profile_balances(integer, integer)
  from public, anon;
grant execute on function public.debug_adjust_profile_balances(integer, integer)
  to authenticated;
