-- Supabase will stop granting Data API table access implicitly for new public
-- tables. Keep the app's existing PostgREST/supabase-js access contract
-- explicit for fresh project builds and future migrations.

grant usage on schema public to anon, authenticated, service_role;

grant select on table
  public.action_cooldowns,
  public.app_config,
  public.blocks,
  public.coin_ledger,
  public.daily_quests,
  public.device_tokens,
  public.diamond_ledger,
  public.feature_requests,
  public.iap_transactions,
  public.inventories,
  public.items,
  public.label_mappings,
  public.message_reactions,
  public.messages,
  public.notification_delivery_logs,
  public.pet_equipment,
  public.pet_state,
  public.pets,
  public.profiles,
  public.purchases,
  public.quests,
  public.reports,
  public.room_background_state,
  public.room_backgrounds,
  public.room_furniture,
  public.room_invite_codes,
  public.room_item_inventories,
  public.room_item_inventory_revisions,
  public.room_members,
  public.rooms,
  public.subscriptions
to anon;

grant select, insert, update, delete on table
  public.action_cooldowns,
  public.app_config,
  public.blocks,
  public.coin_ledger,
  public.daily_quests,
  public.device_tokens,
  public.diamond_ledger,
  public.feature_requests,
  public.iap_transactions,
  public.inventories,
  public.items,
  public.label_mappings,
  public.message_reactions,
  public.messages,
  public.notification_delivery_logs,
  public.pet_equipment,
  public.pet_state,
  public.pets,
  public.profiles,
  public.purchases,
  public.quests,
  public.reports,
  public.room_background_state,
  public.room_backgrounds,
  public.room_furniture,
  public.room_invite_codes,
  public.room_item_inventories,
  public.room_item_inventory_revisions,
  public.room_members,
  public.rooms,
  public.subscriptions
to authenticated, service_role;

-- This scheduler table is intentionally not exposed to anon/authenticated
-- clients; hunger_tick_dispatch reads and writes it with the service role.
grant select, insert, update, delete on table
  public.pet_hunger_tick_schedule
to service_role;

alter default privileges for role postgres in schema public
  grant select on tables to anon;

alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated, service_role;

alter default privileges for role postgres in schema public
  grant usage, select, update on sequences to anon, authenticated, service_role;
