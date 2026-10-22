-- Debug drawer: let a debug admin delete one extra pet from a room they belong
-- to. The main pet (public.pets) is refused because old clients require every
-- room to keep one; swap it out with set_room_main_pet first. Equipment rows
-- are removed by cleanup_pet_equipment_on_extra_pet_delete_trigger, and
-- room_pet_count() is computed, so nothing else needs adjusting.
create or replace function public.admin_debug_remove_room_pet(
  p_room_id uuid,
  p_pet_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if not public.is_debug_admin() then
    raise exception 'not_debug_admin' using errcode = '42501';
  end if;
  if p_room_id is null or p_pet_id is null then
    raise exception 'invalid_pet' using errcode = '22023';
  end if;
  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member' using errcode = '42501';
  end if;

  -- Serialize with set_room_main_pet, which moves rows between the tables.
  perform 1 from public.rooms where id = p_room_id for update;

  if exists (
    select 1 from public.pets where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'cannot_remove_main_pet' using errcode = '22023';
  end if;

  delete from public.room_extra_pets
  where id = p_pet_id and room_id = p_room_id;
  if not found then
    raise exception 'pet_not_found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.admin_debug_remove_room_pet(uuid, uuid)
  from public, anon;
grant execute on function public.admin_debug_remove_room_pet(uuid, uuid)
  to authenticated;
