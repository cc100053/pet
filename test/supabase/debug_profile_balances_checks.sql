-- Run via Supabase MCP as postgres on ilxzpszgirhwxpeocygs.
-- Select an existing admin profile; simulate trusted claims only inside this
-- transaction. Every balance/timestamp change rolls back; no notifications.
begin;
do $$
declare
  v_admin uuid;
  v_fixture record;
  v_coins integer;
  v_diamonds integer;
begin
  if has_function_privilege('anon',
      'public.debug_adjust_profile_balances(integer,integer)', 'EXECUTE')
    or not has_function_privilege('authenticated',
      'public.debug_adjust_profile_balances(integer,integer)', 'EXECUTE')
    or has_column_privilege('authenticated', 'public.profiles', 'coins', 'UPDATE')
    or has_column_privilege('authenticated', 'public.profiles', 'diamonds', 'UPDATE') then
    raise exception 'unexpected debug currency privileges';
  end if;

  perform set_config('request.jwt.claim.sub', '', true);
  for v_fixture in
    select p.user_id, u.raw_app_meta_data
    from public.profiles p join auth.users u on u.id = p.user_id
  loop
    perform set_config('request.jwt.claims', jsonb_build_object(
      'sub', v_fixture.user_id, 'role', 'authenticated',
      'app_metadata', v_fixture.raw_app_meta_data)::text, true);
    if public.is_debug_admin() then
      v_admin := v_fixture.user_id;
      exit;
    end if;
  end loop;
  if v_admin is null then raise exception 'missing admin profile fixture'; end if;

  update public.profiles set coins = 10, diamonds = 20 where user_id = v_admin;
  execute 'set local role authenticated';
  perform public.debug_adjust_profile_balances(0, 100);
  select coins, diamonds into v_coins, v_diamonds
    from public.profiles where user_id = v_admin;
  if v_coins <> 10 or v_diamonds <> 120 then
    raise exception 'debug +100 diamonds did not apply';
  end if;
  perform public.debug_adjust_profile_balances(100, 0);
  perform public.debug_adjust_profile_balances(100, 0);
  select coins, diamonds into v_coins, v_diamonds
    from public.profiles where user_id = v_admin;
  if v_coins <> 210 or v_diamonds <> 120 then
    raise exception 'coin increments overwrote balances';
  end if;
  perform public.debug_adjust_profile_balances(-2147483648, -2147483648);
  perform public.debug_adjust_profile_balances(0, 0);
  select coins, diamonds into v_coins, v_diamonds
    from public.profiles where user_id = v_admin;
  if v_coins <> 0 or v_diamonds <> 0 then
    raise exception 'negative balances were not clamped';
  end if;
  begin
    perform public.debug_adjust_profile_balances(null, 100);
    raise exception 'null coin delta accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.debug_adjust_profile_balances(100, null);
    raise exception 'null diamond delta accepted';
  exception when invalid_parameter_value then null;
  end;
  perform public.debug_adjust_profile_balances(0, 2147483647);
  begin
    perform public.debug_adjust_profile_balances(100, 1);
    raise exception 'overflow accepted';
  exception when numeric_value_out_of_range then null;
  end;
  select coins, diamonds into v_coins, v_diamonds
    from public.profiles where user_id = v_admin;
  if v_coins <> 0 or v_diamonds <> 2147483647 then
    raise exception 'overflow partially changed balances';
  end if;
  begin
    update public.profiles set diamonds = 100 where user_id = v_admin;
    raise exception 'direct currency write accepted';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', v_admin, 'role', 'authenticated',
    'user_metadata', jsonb_build_object('is_admin', true))::text, true);
  begin
    perform public.debug_adjust_profile_balances(0, 100);
    raise exception 'user-editable admin metadata accepted';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claims', '{"app_metadata":{"is_admin":true}}', true);
  begin
    perform public.debug_adjust_profile_balances(0, 100);
    raise exception 'missing session accepted';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', '00000000-0000-0000-0000-000000000000',
    'app_metadata', jsonb_build_object('is_admin', true))::text, true);
  begin
    perform public.debug_adjust_profile_balances(0, 100);
    raise exception 'missing profile accepted';
  exception when no_data_found then null;
  end;
  execute 'reset role';
end;
$$;
rollback;
select 'PASS: admin +100 diamonds, additive coins, zero clamp, null/overflow rejection, direct-write denial, nonadmin/session/profile denial; all writes rolled back' as result;
