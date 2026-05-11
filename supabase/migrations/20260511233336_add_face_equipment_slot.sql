begin;

alter table public.pet_equipment
  drop constraint if exists pet_equipment_slot_check;

alter table public.pet_equipment
  add constraint pet_equipment_slot_check
  check (slot in ('head', 'face', 'body', 'back'));

update public.items
set metadata = jsonb_set(
  coalesce(metadata, '{}'::jsonb),
  '{equipment_slot}',
  '"face"'::jsonb,
  true
)
where sku = 'equip_sunglasses'
  and metadata->>'category' = 'equipment';

update public.pet_equipment pe
set slot = 'face'
from public.items i
where pe.item_id = i.id
  and i.sku = 'equip_sunglasses'
  and pe.slot = 'head';

create or replace function public.equip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_item_id uuid,
  p_slot text
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_item_sku text;
  v_global_qty int;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_slot not in ('head', 'face', 'body', 'back') then
    raise exception 'invalid_slot';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1
    from public.pets
    where id = p_pet_id
      and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  select sku
  into v_item_sku
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and metadata->>'equipment_slot' = p_slot;

  if v_item_sku is null then
    raise exception 'item_not_equipment_for_slot';
  end if;

  if not exists (
    select 1
    from public.room_item_inventories rii
    where rii.room_id = p_room_id
      and rii.item_id = p_item_id
      and rii.quantity > 0
  ) then
    select quantity
    into v_global_qty
    from public.inventories
    where user_id = v_user_id
      and item_id = p_item_id
      and quantity > 0
    for update;

    if coalesce(v_global_qty, 0) <= 0 then
      raise exception 'item_not_owned_in_room';
    end if;

    insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
    values (p_room_id, v_user_id, p_item_id, 1)
    on conflict (room_id, user_id, item_id)
    do update set quantity = greatest(public.room_item_inventories.quantity, 1);

    if v_global_qty > 1 then
      update public.inventories
      set quantity = v_global_qty - 1
      where user_id = v_user_id
        and item_id = p_item_id;
    else
      delete from public.inventories
      where user_id = v_user_id
        and item_id = p_item_id;
    end if;
  end if;

  insert into public.pet_equipment (
    pet_id,
    room_id,
    item_id,
    slot,
    equipped_by,
    equipped_at
  )
  values (
    p_pet_id,
    p_room_id,
    p_item_id,
    p_slot,
    v_user_id,
    now()
  )
  on conflict (room_id, pet_id, slot)
  do update set
    item_id = excluded.item_id,
    equipped_by = excluded.equipped_by,
    equipped_at = excluded.equipped_at;

  return jsonb_build_object(
    'success', true,
    'slot', p_slot,
    'item_sku', v_item_sku
  );
end;
$$;

grant execute on function public.equip_pet_item(uuid, uuid, uuid, text)
  to authenticated;

create or replace function public.unequip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_slot text
)
returns jsonb
language plpgsql
set search_path = public
as $$
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
    select 1
    from public.pets
    where id = p_pet_id
      and room_id = p_room_id
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
$$;

grant execute on function public.unequip_pet_item(uuid, uuid, text)
  to authenticated;

commit;
