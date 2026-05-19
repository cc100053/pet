begin;

-- All multi-pet RPCs now treat `pets` as the canonical main-pet row and
-- `room_extra_pets` as the holder for everyone else. The 5-pet cap and
-- everything else still counts both tables together.

-- 1) get_room_pets: union both tables.
create or replace function public.get_room_pets(
  p_room_id uuid
)
returns table (
  pet_id uuid,
  room_id uuid,
  name text,
  color_dna jsonb,
  stage text,
  level int,
  exp int,
  avatar_url text,
  is_main boolean,
  created_at timestamptz
)
language plpgsql
stable
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  return query
  with combined as (
    select p.id, p.room_id, p.name, p.color_dna, p.stage, p.level, p.exp,
           p.avatar_url, p.created_at
    from public.pets p
    where p.room_id = p_room_id
    union all
    select e.id, e.room_id, e.name, e.color_dna, e.stage, e.level, e.exp,
           e.avatar_url, e.created_at
    from public.room_extra_pets e
    where e.room_id = p_room_id
  )
  select c.id, c.room_id, c.name, c.color_dna, c.stage, c.level, c.exp,
         c.avatar_url, c.id = r.main_pet_id, c.created_at
  from combined c
  join public.rooms r on r.id = c.room_id
  order by
    case when c.id = r.main_pet_id then 0 else 1 end,
    c.created_at asc,
    c.id;
end;
$$;

grant execute on function public.get_room_pets(uuid) to authenticated;

-- 2) Pet-ticket RPCs: insert into room_extra_pets when a main already
--    exists, otherwise insert into pets (and promote to main). The cap
--    check counts rows from both tables.
create or replace function public.use_pet_ticket(
  p_room_id uuid,
  p_pet_type text,
  p_pet_name text
)
returns table (
  pet_id uuid,
  room_pet_count int,
  remaining_tickets int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket_item_id uuid;
  v_ticket_quantity int;
  v_remaining_tickets int;
  v_pet_count int;
  v_pet_id uuid;
  v_pet_type text;
  v_pet_name text;
  v_has_main boolean;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms r where r.id = p_room_id for update;
  if not found then
    raise exception 'room_not_found';
  end if;

  v_pet_count :=
    (select count(*) from public.pets where room_id = p_room_id)::int
    + (select count(*) from public.room_extra_pets where room_id = p_room_id)::int;

  if v_pet_count >= 5 then
    raise exception 'room_pet_capacity_reached';
  end if;

  v_pet_type := nullif(trim(coalesce(p_pet_type, '')), '');
  if v_pet_type is null then
    raise exception 'invalid_pet_type';
  end if;

  v_pet_name := trim(coalesce(p_pet_name, ''));
  if v_pet_name = '' then
    raise exception 'invalid_pet_name';
  end if;
  if char_length(v_pet_name) > 20 then
    raise exception 'pet_name_too_long';
  end if;

  select i.id into v_ticket_item_id
  from public.items i where i.sku = 'pet_ticket' limit 1;
  if v_ticket_item_id is null then
    raise exception 'pet_ticket_not_found';
  end if;

  select inv.quantity into v_ticket_quantity
  from public.inventories inv
  where inv.user_id = auth.uid() and inv.item_id = v_ticket_item_id
  for update;

  if coalesce(v_ticket_quantity, 0) <= 0 then
    raise exception 'pet_ticket_not_owned';
  end if;

  v_remaining_tickets := v_ticket_quantity - 1;

  v_has_main := exists (select 1 from public.pets where room_id = p_room_id);

  if v_has_main then
    insert into public.room_extra_pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_pet_name,
      jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
  else
    insert into public.pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_pet_name,
      jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
    insert into public.pet_state (pet_id) values (v_pet_id)
      on conflict on constraint pet_state_pkey do nothing;
  end if;

  insert into public.room_pet_state (room_id) values (p_room_id)
    on conflict (room_id) do nothing;

  if v_remaining_tickets > 0 then
    update public.inventories set quantity = v_remaining_tickets
    where user_id = auth.uid() and item_id = v_ticket_item_id;
  else
    delete from public.inventories
    where user_id = auth.uid() and item_id = v_ticket_item_id;
  end if;

  update public.rooms
  set main_pet_id = coalesce(main_pet_id, v_pet_id)
  where id = p_room_id;

  return query select v_pet_id, v_pet_count + 1, v_remaining_tickets;
end;
$$;

grant execute on function public.use_pet_ticket(uuid, text, text)
  to authenticated;

create or replace function public.purchase_and_use_pet_ticket(
  p_room_id uuid,
  p_item_id uuid,
  p_pet_type text,
  p_pet_name text
)
returns table (
  pet_id uuid,
  room_pet_count int,
  remaining_diamonds int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_pet_count int;
  v_pet_id uuid;
  v_pet_type text;
  v_pet_name text;
  v_has_main boolean;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms r where r.id = p_room_id for update;
  if not found then
    raise exception 'room_not_found';
  end if;

  v_pet_count :=
    (select count(*) from public.pets where room_id = p_room_id)::int
    + (select count(*) from public.room_extra_pets where room_id = p_room_id)::int;

  if v_pet_count >= 5 then
    raise exception 'room_pet_capacity_reached';
  end if;

  v_pet_type := nullif(trim(coalesce(p_pet_type, '')), '');
  if v_pet_type is null then
    raise exception 'invalid_pet_type';
  end if;
  v_pet_name := trim(coalesce(p_pet_name, ''));
  if v_pet_name = '' then
    raise exception 'invalid_pet_name';
  end if;
  if char_length(v_pet_name) > 20 then
    raise exception 'pet_name_too_long';
  end if;

  select i.price_diamonds into v_price
  from public.items i
  where i.id = p_item_id
    and i.sku = 'pet_ticket'
    and (i.metadata->>'category') = 'pet_ticket'
    and (
      (coalesce(i.is_active, false) = true
       and coalesce(i.metadata->>'visibility_mode', 'public') = 'public')
      or
      (coalesce(i.metadata->>'visibility_mode', 'public') = 'version_gated'
       and coalesce(i.metadata->>'shop_visibility', '') <> 'hidden')
    );
  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select p.diamonds into v_current_diamonds
  from public.profiles p where p.user_id = auth.uid() for update;
  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;
  if v_current_diamonds < v_price then
    raise exception 'insufficient_diamonds';
  end if;

  v_has_main := exists (select 1 from public.pets where room_id = p_room_id);

  if v_has_main then
    insert into public.room_extra_pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_pet_name,
      jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
  else
    insert into public.pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_pet_name,
      jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
    insert into public.pet_state (pet_id) values (v_pet_id)
      on conflict on constraint pet_state_pkey do nothing;
  end if;

  insert into public.room_pet_state (room_id) values (p_room_id)
    on conflict (room_id) do nothing;

  update public.rooms
  set main_pet_id = coalesce(main_pet_id, v_pet_id)
  where id = p_room_id;

  update public.profiles
  set diamonds = diamonds - v_price
  where user_id = auth.uid();

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(), p_room_id, 'store_purchase', -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1,
                       'pet_id', v_pet_id, 'pet_type', v_pet_type)
  );

  return query select v_pet_id, v_pet_count + 1, v_current_diamonds - v_price;
end;
$$;

grant execute on function public.purchase_and_use_pet_ticket(uuid, uuid, text, text)
  to authenticated;

create or replace function public.add_room_pet(
  p_room_id uuid,
  p_pet_type text,
  p_pet_name text
)
returns table (
  pet_id uuid,
  room_pet_count int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet_count int;
  v_pet_id uuid;
  v_name text;
  v_pet_type text;
  v_has_main boolean;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

  v_pet_count :=
    (select count(*) from public.pets where room_id = p_room_id)::int
    + (select count(*) from public.room_extra_pets where room_id = p_room_id)::int;

  if v_pet_count >= 5 then
    raise exception 'room_pet_capacity_reached';
  end if;

  v_pet_type := nullif(trim(coalesce(p_pet_type, '')), '');
  if v_pet_type is null then
    raise exception 'invalid_pet_type';
  end if;
  v_name := trim(coalesce(p_pet_name, ''));
  if v_name = '' then
    raise exception 'invalid_pet_name';
  end if;
  if char_length(v_name) > 20 then
    raise exception 'pet_name_too_long';
  end if;

  v_has_main := exists (select 1 from public.pets where room_id = p_room_id);

  if v_has_main then
    insert into public.room_extra_pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_name, jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
  else
    insert into public.pets (
      room_id, name, color_dna, stage, days_alive, scale
    )
    values (
      p_room_id, v_name, jsonb_build_object('pet_type', v_pet_type),
      'egg', 0, 1.0
    )
    returning id into v_pet_id;
    insert into public.pet_state (pet_id)
    select v_pet_id
    where not exists (select 1 from public.pet_state ps where ps.pet_id = v_pet_id);
    update public.rooms set main_pet_id = v_pet_id
    where id = p_room_id and main_pet_id is null;
  end if;

  insert into public.room_pet_state (room_id) values (p_room_id)
    on conflict (room_id) do nothing;

  return query select v_pet_id, v_pet_count + 1;
end;
$$;

grant execute on function public.add_room_pet(uuid, text, text)
  to authenticated;

-- 3) set_room_main_pet: swap rows between pets and room_extra_pets so the
--    chosen pet becomes the canonical main row and the old main moves to
--    extras. Both id and equipment references stay intact (FK was dropped).
create or replace function public.set_room_main_pet(
  p_room_id uuid,
  p_pet_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_main_id uuid;
  v_old_main record;
  v_new_main record;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

  select main_pet_id into v_old_main_id
  from public.rooms where id = p_room_id;

  if v_old_main_id = p_pet_id then
    return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
  end if;

  -- Validate the chosen pet belongs to this room (in either table).
  if not exists (
    select 1 from public.pets where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  -- Clear main_pet_id first so the swap doesn't trip the BEFORE-UPDATE
  -- validation trigger (which requires main pet to currently exist in
  -- pets). We will set it to the new id at the end.
  update public.rooms set main_pet_id = null where id = p_room_id;

  -- Snapshot the current main row, then move it to room_extra_pets.
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
        v_old_main.stage, v_old_main.level, v_old_main.days_alive,
        v_old_main.scale, v_old_main.exp, v_old_main.avatar_url,
        v_old_main.created_at, now()
      );
    end if;
  end if;

  -- Promote the chosen pet: pull from extras into pets.
  select * into v_new_main from public.room_extra_pets where id = p_pet_id;
  if v_new_main.id is not null then
    delete from public.room_extra_pets where id = p_pet_id;
    insert into public.pets (
      id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
      avatar_url, created_at, updated_at
    )
    values (
      v_new_main.id, v_new_main.room_id, v_new_main.name, v_new_main.color_dna,
      v_new_main.stage, v_new_main.level, v_new_main.days_alive,
      v_new_main.scale, v_new_main.exp, v_new_main.avatar_url,
      v_new_main.created_at, now()
    );
    -- Ensure pet_state row exists for the new main (extras don't have one).
    insert into public.pet_state (pet_id) values (p_pet_id)
      on conflict on constraint pet_state_pkey do nothing;
  end if;

  update public.rooms set main_pet_id = p_pet_id where id = p_room_id;
  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);

  return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
end;
$$;

grant execute on function public.set_room_main_pet(uuid, uuid) to authenticated;

-- 4) equip_pet_item: now accepts pet ids from either table.
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
  v_room_total_qty int;
  v_equipped_qty int;
  v_current_item_id uuid;
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

  perform 1 from public.rooms where id = p_room_id for update;

  if not exists (
    select 1 from public.pets
    where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets
    where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  select sku into v_item_sku
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and metadata->>'equipment_slot' = p_slot;
  if v_item_sku is null then
    raise exception 'item_not_equipment_for_slot';
  end if;

  if not exists (
    select 1 from public.room_item_inventories rii
    where rii.room_id = p_room_id and rii.item_id = p_item_id and rii.quantity > 0
  ) then
    select quantity into v_global_qty
    from public.inventories
    where user_id = v_user_id and item_id = p_item_id and quantity > 0
    for update;
    if coalesce(v_global_qty, 0) <= 0 then
      raise exception 'item_not_owned_in_room';
    end if;
    insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
    values (p_room_id, v_user_id, p_item_id, 1)
    on conflict (room_id, user_id, item_id)
    do update set quantity = greatest(public.room_item_inventories.quantity, 1);
    if v_global_qty > 1 then
      update public.inventories set quantity = v_global_qty - 1
      where user_id = v_user_id and item_id = p_item_id;
    else
      delete from public.inventories
      where user_id = v_user_id and item_id = p_item_id;
    end if;
  end if;

  select coalesce(sum(quantity), 0)::int into v_room_total_qty
  from public.room_item_inventories
  where room_id = p_room_id and item_id = p_item_id;
  if coalesce(v_room_total_qty, 0) <= 0 then
    raise exception 'item_not_owned_in_room';
  end if;

  select item_id into v_current_item_id
  from public.pet_equipment
  where room_id = p_room_id and pet_id = p_pet_id and slot = p_slot
  for update;

  if v_current_item_id is distinct from p_item_id then
    select count(*)::int into v_equipped_qty
    from public.pet_equipment
    where room_id = p_room_id and item_id = p_item_id;
    if coalesce(v_equipped_qty, 0) >= v_room_total_qty then
      raise exception 'equipment_copy_unavailable';
    end if;
  end if;

  insert into public.pet_equipment (
    pet_id, room_id, item_id, slot, equipped_by, equipped_at
  )
  values (
    p_pet_id, p_room_id, p_item_id, p_slot, v_user_id, now()
  )
  on conflict (room_id, pet_id, slot)
  do update set
    item_id = excluded.item_id,
    equipped_by = excluded.equipped_by,
    equipped_at = excluded.equipped_at;

  return jsonb_build_object('success', true, 'slot', p_slot, 'item_sku', v_item_sku);
end;
$$;

grant execute on function public.equip_pet_item(uuid, uuid, uuid, text)
  to authenticated;

commit;
