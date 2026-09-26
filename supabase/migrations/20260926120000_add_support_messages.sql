-- In-app customer support thread (one thread per user).
--
-- Users insert their own messages (sender forced to 'user' by column grants).
-- The admin replies by inserting a row with sender = 'admin' from the Supabase
-- dashboard / SQL editor. Every insert pings the support_notify Edge Function:
-- user messages are emailed to the support inbox, admin replies are pushed to
-- the user's devices.

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  sender text not null default 'user' check (sender in ('user', 'admin')),
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  meta jsonb not null default '{}'::jsonb
    check (jsonb_typeof(meta) = 'object' and pg_column_size(meta) <= 4096),
  created_at timestamptz not null default now()
);

create index if not exists support_messages_user_id_created_at_idx
  on public.support_messages (user_id, created_at);

alter table public.support_messages enable row level security;

revoke all on public.support_messages from anon, authenticated;
grant select on public.support_messages to authenticated;
-- user_id / sender / created_at come from defaults, so clients cannot spoof
-- an admin reply or another user's thread.
grant insert (body, meta) on public.support_messages to authenticated;

drop policy if exists support_messages_select_own on public.support_messages;
create policy support_messages_select_own
  on public.support_messages
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists support_messages_insert_own on public.support_messages;
create policy support_messages_insert_own
  on public.support_messages
  for insert
  to authenticated
  with check (user_id = (select auth.uid()) and sender = 'user');

-- Every user insert emails the inbox, so cap how fast one account can send.
create or replace function public.support_messages_rate_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.sender = 'user' and (
    select count(*)
    from public.support_messages m
    where m.user_id = new.user_id
      and m.sender = 'user'
      and m.created_at > now() - interval '1 hour'
  ) >= 20 then
    raise exception 'support_rate_limited' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists support_messages_rate_limit on public.support_messages;
create trigger support_messages_rate_limit
  before insert on public.support_messages
  for each row execute function public.support_messages_rate_limit();

-- Needs the vault secret `support_notify_secret`, matching the Edge Function's
-- SUPPORT_NOTIFY_SECRET env var.
create or replace function public.support_messages_notify()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform net.http_post(
    url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/support_notify',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce((
        select decrypted_secret from vault.decrypted_secrets
        where name = 'support_notify_secret' limit 1
      ), '')
    ),
    body := jsonb_build_object('id', new.id)
  );
  return null;
end;
$$;

revoke all on function public.support_messages_notify() from public, anon, authenticated;
revoke all on function public.support_messages_rate_limit() from public, anon, authenticated;

drop trigger if exists support_messages_notify on public.support_messages;
create trigger support_messages_notify
  after insert on public.support_messages
  for each row execute function public.support_messages_notify();
