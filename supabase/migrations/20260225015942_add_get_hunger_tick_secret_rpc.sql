create or replace function public.get_hunger_tick_secret()
returns text
language sql
security definer
set search_path = public, vault
as $$
  select decrypted_secret
  from vault.decrypted_secrets
  where name = 'hunger_tick_secret'
  limit 1;
$$;

revoke all on function public.get_hunger_tick_secret() from public, anon, authenticated;
grant execute on function public.get_hunger_tick_secret() to service_role;
