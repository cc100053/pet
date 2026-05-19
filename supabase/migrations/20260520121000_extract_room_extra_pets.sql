begin;

-- Restore backward compatibility: legacy clients query
-- `from('pets').eq('room_id', $r).maybeSingle()` and crash when multiple
-- rows exist. Multi-pet v2.0.0 dropped the unique(room_id) constraint;
-- here we restore the 1-row-per-room invariant on `pets` and relocate
-- extras to a sibling `room_extra_pets` table that only v2.0.0+ clients
-- see (via the get_room_pets RPC). pet_equipment.pet_id can now point
-- at either table so we drop the FK and replace it with cleanup triggers
-- on both source tables.

create table if not exists public.room_extra_pets (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text,
  color_dna jsonb not null default '{}'::jsonb,
  stage text not null default 'egg',
  level int not null default 1,
  days_alive int not null default 0,
  scale numeric not null default 1.0,
  exp int not null default 0,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists room_extra_pets_room_id_idx
  on public.room_extra_pets (room_id);

-- Set updated_at automatically (shared helper from init schema).
drop trigger if exists set_room_extra_pets_updated_at on public.room_extra_pets;
create trigger set_room_extra_pets_updated_at
before update on public.room_extra_pets
for each row execute function public.set_updated_at();

-- Inherit room level/exp on insert (same trigger function as pets uses).
drop trigger if exists inherit_room_level_on_new_extra_pet_trigger
  on public.room_extra_pets;
create trigger inherit_room_level_on_new_extra_pet_trigger
before insert on public.room_extra_pets
for each row execute function public.inherit_room_level_on_new_pet();

-- And keep their level/exp synced with the room state too.
drop trigger if exists sync_extra_pet_level_to_room_trigger
  on public.room_extra_pets;
create trigger sync_extra_pet_level_to_room_trigger
after update of level, exp on public.room_extra_pets
for each row execute function public.sync_pet_level_to_room();

-- Extend the room_pet_state → all pets trigger to also push into extras.
create or replace function public.sync_room_level_to_pets()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  if new.level is not distinct from old.level
     and new.exp is not distinct from old.exp then
    return new;
  end if;
  update public.pets
  set level = new.level, exp = new.exp
  where room_id = new.room_id
    and (level is distinct from new.level or exp is distinct from new.exp);
  update public.room_extra_pets
  set level = new.level, exp = new.exp
  where room_id = new.room_id
    and (level is distinct from new.level or exp is distinct from new.exp);
  return new;
end;
$$;

alter table public.room_extra_pets enable row level security;

drop policy if exists room_extra_pets_select on public.room_extra_pets;
create policy room_extra_pets_select on public.room_extra_pets
for select to authenticated
using (public.is_room_member(room_id));

drop policy if exists room_extra_pets_insert on public.room_extra_pets;
create policy room_extra_pets_insert on public.room_extra_pets
for insert to authenticated
with check (public.is_room_member(room_id));

drop policy if exists room_extra_pets_update on public.room_extra_pets;
create policy room_extra_pets_update on public.room_extra_pets
for update to authenticated
using (public.is_room_member(room_id))
with check (public.is_room_member(room_id));

drop policy if exists room_extra_pets_delete on public.room_extra_pets;
create policy room_extra_pets_delete on public.room_extra_pets
for delete to authenticated
using (public.is_room_member(room_id));

revoke all on table public.room_extra_pets from public, anon;
grant select, insert, update, delete on table public.room_extra_pets
  to authenticated;
grant select, insert, update, delete on table public.room_extra_pets
  to service_role;

-- Realtime so v2.0.0+ clients still get live updates for extras.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'room_extra_pets'
  ) then
    alter publication supabase_realtime add table public.room_extra_pets;
  end if;
end $$;

-- Relocate existing extras (the non-main pets) out of pets.
insert into public.room_extra_pets (
  id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
  avatar_url, created_at, updated_at
)
select p.id, p.room_id, p.name, p.color_dna, p.stage, p.level,
       p.days_alive, p.scale, p.exp, p.avatar_url, p.created_at, p.updated_at
from public.pets p
join public.rooms r on r.id = p.room_id
where r.main_pet_id is not null
  and p.id <> r.main_pet_id;

-- pet_equipment's FK to pets(id) blocks deletes of relocated rows. We allow
-- pet_equipment.pet_id to reference either table going forward, so drop
-- the FK. Cleanup is enforced via AFTER DELETE triggers below.
alter table public.pet_equipment
  drop constraint if exists pet_equipment_pet_id_fkey;

-- Pet_state and any other per-pet child tables FK to pets(id). For extras
-- they don't currently exist (pet_state is per-pet but extras share the
-- room's state via room_pet_state). We don't relocate pet_state.

delete from public.pets p
using public.rooms r
where r.id = p.room_id
  and r.main_pet_id is not null
  and p.id <> r.main_pet_id;

-- Restore the 1-row-per-room invariant so legacy clients' maybeSingle()
-- works again. After the delete above this should hold.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.pets'::regclass
      and conname = 'pets_room_id_key'
  ) then
    alter table public.pets add constraint pets_room_id_key unique (room_id);
  end if;
end $$;

-- Garbage-collect pet_equipment when its target pet row vanishes (now from
-- either source table since the FK is gone).
create or replace function public.cleanup_pet_equipment_on_pet_delete()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  delete from public.pet_equipment where pet_id = old.id;
  return old;
end;
$$;

drop trigger if exists cleanup_pet_equipment_on_pet_delete_trigger
  on public.pets;
create trigger cleanup_pet_equipment_on_pet_delete_trigger
after delete on public.pets
for each row execute function public.cleanup_pet_equipment_on_pet_delete();

drop trigger if exists cleanup_pet_equipment_on_extra_pet_delete_trigger
  on public.room_extra_pets;
create trigger cleanup_pet_equipment_on_extra_pet_delete_trigger
after delete on public.room_extra_pets
for each row execute function public.cleanup_pet_equipment_on_pet_delete();

commit;
