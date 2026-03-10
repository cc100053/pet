create table if not exists public.message_reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint message_reactions_pkey primary key (message_id, user_id),
  constraint message_reactions_emoji_length check (char_length(emoji) between 1 and 16)
);

create index if not exists message_reactions_room_message_idx
  on public.message_reactions (room_id, message_id);

create index if not exists message_reactions_room_user_idx
  on public.message_reactions (room_id, user_id);

alter table public.message_reactions enable row level security;

drop policy if exists message_reactions_select on public.message_reactions;
create policy message_reactions_select on public.message_reactions
for select to authenticated
using (
  exists (
    select 1
    from public.room_members rm
    where rm.room_id = message_reactions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
);

drop policy if exists message_reactions_insert on public.message_reactions;
create policy message_reactions_insert on public.message_reactions
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.room_members rm
    where rm.room_id = message_reactions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
  and exists (
    select 1
    from public.messages m
    where m.id = message_reactions.message_id
      and m.room_id = message_reactions.room_id
  )
);

drop policy if exists message_reactions_update on public.message_reactions;
create policy message_reactions_update on public.message_reactions
for update to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.room_members rm
    where rm.room_id = message_reactions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
)
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.room_members rm
    where rm.room_id = message_reactions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
  and exists (
    select 1
    from public.messages m
    where m.id = message_reactions.message_id
      and m.room_id = message_reactions.room_id
  )
);

drop policy if exists message_reactions_delete on public.message_reactions;
create policy message_reactions_delete on public.message_reactions
for delete to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.room_members rm
    where rm.room_id = message_reactions.room_id
      and rm.user_id = (select auth.uid())
      and rm.is_active
  )
);

drop trigger if exists set_message_reactions_updated_at on public.message_reactions;
create trigger set_message_reactions_updated_at
before update on public.message_reactions
for each row execute function public.set_updated_at();

do $$
begin
  alter publication supabase_realtime add table public.message_reactions;
exception
  when duplicate_object then null;
end $$;
