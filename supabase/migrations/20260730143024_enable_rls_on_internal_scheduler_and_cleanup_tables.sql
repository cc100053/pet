-- Defense in depth for internal service-only tables in the exposed public
-- schema. Both tables already revoke all access from client roles; enabling
-- RLS ensures a future accidental grant still has no usable rows.

alter table public.pet_hunger_tick_schedule enable row level security;
alter table public.room_cleanup_candidates enable row level security;

-- Keep the existing service-only Data API contract explicit. No RLS policies
-- are intentional: postgres and service_role retain their existing BYPASSRLS
-- access, while client roles remain denied at both the grant and RLS layers.
revoke all on table public.pet_hunger_tick_schedule
from public, anon, authenticated;
revoke all on table public.room_cleanup_candidates
from public, anon, authenticated;
