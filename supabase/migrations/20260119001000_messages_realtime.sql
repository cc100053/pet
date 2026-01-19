-- Enable realtime updates for messages
do $$
begin
  begin
    alter publication supabase_realtime add table public.messages;
  exception
    when duplicate_object then
      null;
  end;
end $$;

-- Ensure updates emit full rows for clients
alter table public.messages replica identity full;
