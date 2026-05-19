begin;

-- Level/exp move from a per-pet concept to a per-room one. room_pet_state
-- holds the canonical level/exp; every pet in the room mirrors it so that
-- legacy clients reading pets.level (one row per room from their view) still
-- see the room's level. Existing leveling RPCs that still UPDATE pets.level
-- continue to work — the trigger cascades the change up to room_pet_state,
-- which then mirrors it down to every pet in the room. Recursion is
-- bounded by pg_trigger_depth().
alter table public.room_pet_state
  add column if not exists level int not null default 1,
  add column if not exists exp int not null default 0;

alter table public.room_pet_state
  drop constraint if exists room_pet_state_level_positive;
alter table public.room_pet_state
  add constraint room_pet_state_level_positive check (level >= 1);
alter table public.room_pet_state
  drop constraint if exists room_pet_state_exp_nonneg;
alter table public.room_pet_state
  add constraint room_pet_state_exp_nonneg check (exp >= 0);

-- One-time seed: room_pet_state.level/exp = the strongest pet currently in
-- the room (max level, then max exp at that level).
update public.room_pet_state rps
set level = best.level,
    exp = best.exp
from (
  select distinct on (room_id)
    room_id,
    coalesce(level, 1) as level,
    coalesce(exp, 0) as exp
  from public.pets
  order by room_id, coalesce(level, 1) desc, coalesce(exp, 0) desc
) best
where best.room_id = rps.room_id;

-- After seeding, mirror room level down to every pet so they all match.
update public.pets p
set level = rps.level,
    exp = rps.exp
from public.room_pet_state rps
where rps.room_id = p.room_id
  and (p.level is distinct from rps.level or p.exp is distinct from rps.exp);

-- pets.level/exp change → propagate to room_pet_state (which cascades to
-- the rest). Guarded by pg_trigger_depth so the room→pets sync doesn't
-- re-fire this trigger.
create or replace function public.sync_pet_level_to_room()
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
  update public.room_pet_state
  set level = new.level,
      exp = new.exp,
      updated_at = now()
  where room_id = new.room_id
    and (level is distinct from new.level or exp is distinct from new.exp);
  return new;
end;
$$;

drop trigger if exists sync_pet_level_to_room_trigger on public.pets;
create trigger sync_pet_level_to_room_trigger
after update of level, exp on public.pets
for each row execute function public.sync_pet_level_to_room();

-- room_pet_state.level/exp change → mirror to every pet in the room.
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
  set level = new.level,
      exp = new.exp
  where room_id = new.room_id
    and (level is distinct from new.level or exp is distinct from new.exp);
  return new;
end;
$$;

drop trigger if exists sync_room_level_to_pets_trigger on public.room_pet_state;
create trigger sync_room_level_to_pets_trigger
after update of level, exp on public.room_pet_state
for each row execute function public.sync_room_level_to_pets();

-- A new pet in a room inherits the room's current level/exp.
create or replace function public.inherit_room_level_on_new_pet()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_level int;
  v_exp int;
begin
  select level, exp into v_level, v_exp
  from public.room_pet_state
  where room_id = new.room_id;
  if v_level is not null then
    new.level := v_level;
    new.exp := v_exp;
  end if;
  return new;
end;
$$;

drop trigger if exists inherit_room_level_on_new_pet_trigger on public.pets;
create trigger inherit_room_level_on_new_pet_trigger
before insert on public.pets
for each row execute function public.inherit_room_level_on_new_pet();

commit;
