create table if not exists public.feature_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  body text not null check (char_length(body) between 1 and 1000),
  app_version text,
  created_at timestamptz not null default now()
);

alter table public.feature_requests enable row level security;

create policy "Users can insert own requests"
  on public.feature_requests for insert
  with check (auth.uid() = user_id or user_id is null);
