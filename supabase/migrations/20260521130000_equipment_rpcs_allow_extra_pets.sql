-- Fix: reading/removing equipment on a non-main (extra) pet failed because
-- get_pet_equipment(p_pet_id, p_room_id) and unequip_pet_item validated the
-- pet only against public.pets and raised 'pet_not_found' for pets that live
-- in public.room_extra_pets. equip_pet_item already checks both tables; align
-- these two so the dress-up panel can load an extra pet's gear (preview +
-- equipped state) and remove it.

create or replace function public.get_pet_equipment(p_pet_id uuid, p_room_id uuid)
returns table(
  slot text,
  item_id uuid,
  item_sku text,
  equipped_at timestamptz,
  equipped_by uuid
)
language plpgsql
stable
set search_path to 'public'
as $function$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1 from public.pets
    where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets
    where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  return query
  select
    pe.slot,
    pe.item_id,
    i.sku as item_sku,
    pe.equipped_at,
    pe.equipped_by
  from public.pet_equipment pe
  join public.items i
    on i.id = pe.item_id
  where pe.pet_id = p_pet_id
    and pe.room_id = p_room_id
  order by pe.slot;
end;
$function$;

create or replace function public.unequip_pet_item(p_pet_id uuid, p_room_id uuid, p_slot text)
returns jsonb
language plpgsql
set search_path to 'public'
as $function$
declare
  v_deleted int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_slot not in ('head', 'face', 'body', 'back') then
    raise exception 'invalid_slot';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1 from public.pets
    where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets
    where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  delete from public.pet_equipment
  where pet_id = p_pet_id
    and room_id = p_room_id
    and slot = p_slot;

  get diagnostics v_deleted = row_count;

  return jsonb_build_object(
    'success', true,
    'slot', p_slot,
    'removed', v_deleted > 0
  );
end;
$function$;
