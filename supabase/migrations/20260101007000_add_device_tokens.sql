create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists device_tokens_token_idx on device_tokens (token);
create index if not exists device_tokens_user_idx on device_tokens (user_id);

create trigger set_device_tokens_updated_at
before update on device_tokens
for each row execute function public.set_updated_at();

alter table device_tokens enable row level security;

create policy device_tokens_select on device_tokens
for select using (user_id = auth.uid());

create policy device_tokens_insert on device_tokens
for insert with check (user_id = auth.uid());

create policy device_tokens_update on device_tokens
for update using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy device_tokens_delete on device_tokens
for delete using (user_id = auth.uid());
