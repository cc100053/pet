-- Allow multiple push tokens per user (multi-device support).
-- Keep token uniqueness so each physical device token is deduplicated globally.

drop index if exists public.device_tokens_user_unique_idx;

alter table if exists public.device_tokens
  drop constraint if exists device_tokens_user_id_key;

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

