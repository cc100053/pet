create table if not exists public.notification_delivery_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  room_id text not null,
  message_id text not null,
  sender_id text,
  recipient_user_id text,
  token_prefix text not null,
  token_suffix text not null,
  platform text,
  locale text,
  payload_type text not null,
  message_kind text not null,
  success boolean not null,
  http_status integer,
  error_text text,
  provider_response jsonb
);

alter table public.notification_delivery_logs enable row level security;

create index if not exists idx_notification_delivery_logs_created_at
  on public.notification_delivery_logs (created_at desc);

create index if not exists idx_notification_delivery_logs_message
  on public.notification_delivery_logs (room_id, message_id, created_at desc);

