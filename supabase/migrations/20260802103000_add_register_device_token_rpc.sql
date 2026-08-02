-- Device tokens could not change owner.
--
-- The client upserts with `on conflict (token)`, which Postgres resolves to an
-- UPDATE of the existing row. The `device_tokens_update` policy evaluates its
-- USING expression against that *existing* row, whose user_id is still the
-- previous owner, so any account switch on a device failed with
-- `42501 ... (USING expression)`. The client could not self-heal either: the
-- delete policy is also scoped to auth.uid(), so the arriving user could not
-- remove the stale row.
--
-- Consequence was worse than a missing push: the row kept the old user_id, so
-- the device carried on receiving the previous account's notifications while
-- the signed-in account received none.
--
-- Registering through a SECURITY DEFINER function lets the token be reassigned
-- atomically without granting clients broad UPDATE rights, so the table
-- policies stay exactly as strict as they are today.

create or replace function public.register_device_token(
  p_token text,
  p_platform text default null,
  p_device_locale text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_token text := nullif(btrim(p_token), '');
begin
  if v_user_id is null then
    raise exception 'register_device_token requires an authenticated caller'
      using errcode = '42501';
  end if;

  if v_token is null then
    raise exception 'register_device_token requires a non-empty token'
      using errcode = '22023';
  end if;

  -- `created_at` is preserved on re-registration so the row keeps its original
  -- first-seen timestamp; only ownership and liveness move.
  insert into public.device_tokens as dt (
    user_id,
    token,
    platform,
    device_locale,
    last_seen_at,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    v_token,
    p_platform,
    p_device_locale,
    now(),
    now(),
    now()
  )
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = coalesce(excluded.platform, dt.platform),
        device_locale = coalesce(excluded.device_locale, dt.device_locale),
        last_seen_at = excluded.last_seen_at,
        updated_at = excluded.updated_at;
end;
$$;

-- Signed-in callers only: the function claims a token for auth.uid(), so anon
-- must never reach it.
revoke all on function public.register_device_token(text, text, text)
  from public, anon, authenticated;
grant execute on function public.register_device_token(text, text, text)
  to authenticated;
