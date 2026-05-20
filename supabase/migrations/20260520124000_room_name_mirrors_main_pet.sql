begin;

-- Naming model B: the room's display name IS the main pet's name. We keep
-- rooms.name as the rendered field (so no UI/query changes), but it now
-- mirrors the main pet's name. Renaming the main pet renames the room;
-- switching the main pet switches the room name. Each pet still has its own
-- name for multi-pet identity. rooms.name stays populated for legacy clients.

-- Backfill: give every main pet the room's current name where it has none,
-- so the existing displayed identity is preserved on the pet row.
update public.pets p
set name = r.name
from public.rooms r
where r.id = p.room_id
  and r.main_pet_id = p.id
  and (p.name is null or btrim(p.name) = '')
  and r.name is not null
  and btrim(r.name) <> '';

-- Keep rooms.name in lockstep with the main pet's name.
create or replace function public.sync_main_pet_name_to_room()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.name is distinct from old.name and new.name is not null then
    update public.rooms
    set name = new.name
    where id = new.room_id
      and main_pet_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_main_pet_name_to_room_trigger on public.pets;
create trigger sync_main_pet_name_to_room_trigger
after update of name on public.pets
for each row execute function public.sync_main_pet_name_to_room();

-- When the main pet is switched, the room name follows the new main pet.
-- Recreate set_room_main_pet (from the extras-table version) with one extra
-- line that copies the promoted pet's name into rooms.name.
create or replace function public.set_room_main_pet(
  p_room_id uuid, p_pet_id uuid
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_old_main_id uuid; v_old_main record; v_new_main record;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not public.is_room_member(p_room_id) then raise exception 'not_room_member'; end if;
  perform 1 from public.rooms where id = p_room_id for update;
  select main_pet_id into v_old_main_id from public.rooms where id = p_room_id;
  if v_old_main_id = p_pet_id then
    return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
  end if;
  if not exists (
    select 1 from public.pets where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  update public.rooms set main_pet_id = null where id = p_room_id;

  if v_old_main_id is not null then
    select * into v_old_main from public.pets where id = v_old_main_id;
    if v_old_main.id is not null then
      delete from public.pets where id = v_old_main_id;
      insert into public.room_extra_pets (
        id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
        avatar_url, created_at, updated_at
      )
      values (
        v_old_main.id, v_old_main.room_id, v_old_main.name, v_old_main.color_dna,
        v_old_main.stage, v_old_main.level, v_old_main.days_alive, v_old_main.scale,
        v_old_main.exp, v_old_main.avatar_url, v_old_main.created_at, now()
      );
    end if;
  end if;

  select * into v_new_main from public.room_extra_pets where id = p_pet_id;
  if v_new_main.id is not null then
    delete from public.room_extra_pets where id = p_pet_id;
    insert into public.pets (
      id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
      avatar_url, created_at, updated_at
    )
    values (
      v_new_main.id, v_new_main.room_id, v_new_main.name, v_new_main.color_dna,
      v_new_main.stage, v_new_main.level, v_new_main.days_alive, v_new_main.scale,
      v_new_main.exp, v_new_main.avatar_url, v_new_main.created_at, now()
    );
    insert into public.pet_state (pet_id) values (p_pet_id) on conflict on constraint pet_state_pkey do nothing;
  end if;

  update public.rooms
  set main_pet_id = p_pet_id,
      name = coalesce(
        nullif(btrim(v_new_main.name), ''),
        nullif(btrim(v_old_main.name), ''),
        name
      )
  where id = p_room_id;

  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);
  return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
end;
$$;

grant execute on function public.set_room_main_pet(uuid, uuid) to authenticated;

commit;
