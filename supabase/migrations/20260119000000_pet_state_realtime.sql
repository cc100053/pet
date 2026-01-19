-- Enable realtime updates for pet_state
alter publication supabase_realtime add table public.pet_state;

-- Ensure updates emit full rows for clients
alter table public.pet_state replica identity full;
