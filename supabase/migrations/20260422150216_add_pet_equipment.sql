begin;

create table if not exists public.pet_equipment (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  item_id uuid not null references public.items(id),
  slot text not null,
  equipped_at timestamptz not null default now(),
  equipped_by uuid default auth.uid(),
  constraint pet_equipment_unique_slot unique (pet_id, slot),
  constraint pet_equipment_slot_check check (slot in ('head', 'body', 'back'))
);

create index if not exists pet_equipment_pet_id_idx
  on public.pet_equipment (pet_id);

create index if not exists pet_equipment_room_id_idx
  on public.pet_equipment (room_id);

alter table public.pet_equipment enable row level security;

drop policy if exists pet_equipment_select on public.pet_equipment;
create policy pet_equipment_select
  on public.pet_equipment
  for select
  to authenticated
  using (public.is_room_member(room_id));

drop policy if exists pet_equipment_insert on public.pet_equipment;
create policy pet_equipment_insert
  on public.pet_equipment
  for insert
  to authenticated
  with check (
    public.is_room_member(room_id)
    and equipped_by = auth.uid()
    and exists (
      select 1
      from public.pets
      where pets.id = pet_equipment.pet_id
        and pets.room_id = pet_equipment.room_id
    )
    and exists (
      select 1
      from public.items
      where items.id = pet_equipment.item_id
        and items.metadata->>'category' = 'equipment'
        and items.metadata->>'equipment_slot' = pet_equipment.slot
    )
  );

drop policy if exists pet_equipment_update on public.pet_equipment;
create policy pet_equipment_update
  on public.pet_equipment
  for update
  to authenticated
  using (public.is_room_member(room_id))
  with check (
    public.is_room_member(room_id)
    and equipped_by = auth.uid()
    and exists (
      select 1
      from public.pets
      where pets.id = pet_equipment.pet_id
        and pets.room_id = pet_equipment.room_id
    )
    and exists (
      select 1
      from public.items
      where items.id = pet_equipment.item_id
        and items.metadata->>'category' = 'equipment'
        and items.metadata->>'equipment_slot' = pet_equipment.slot
    )
  );

drop policy if exists pet_equipment_delete on public.pet_equipment;
create policy pet_equipment_delete
  on public.pet_equipment
  for delete
  to authenticated
  using (public.is_room_member(room_id));

alter publication supabase_realtime add table public.pet_equipment;

insert into public.items (
  sku,
  type,
  name,
  price_coins,
  price_diamonds,
  price_usd,
  metadata,
  is_active
)
values (
  'equip_straw_hat',
  'cosmetic',
  'Straw Hat',
  120,
  null,
  null,
  jsonb_build_object(
    'category', 'equipment',
    'equipment_slot', 'head',
    'asset_path', 'assets/equipment/hats/straw_hat.png',
    'emoji', '👒',
    'price_jpy', 120,
    'description', 'A sunny hat for your pet.',
    'visibility_mode', 'version_gated',
    'min_app_version', '1.3.0'
  ),
  false
)
on conflict (sku) do update
set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_diamonds = excluded.price_diamonds,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

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
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_slot not in ('head', 'body', 'back') then
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
    from public.inventories
    where user_id = v_user_id
      and item_id = p_item_id
      and quantity > 0
  ) then
    raise exception 'item_not_owned';
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
  on conflict (pet_id, slot)
  do update set
    room_id = excluded.room_id,
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

grant execute on function public.equip_pet_item(uuid, uuid, uuid, text) to authenticated;

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

  if p_slot not in ('head', 'body', 'back') then
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

grant execute on function public.unequip_pet_item(uuid, uuid, text) to authenticated;

create or replace function public.get_pet_equipment(
  p_pet_id uuid
)
returns table (
  slot text,
  item_id uuid,
  item_sku text,
  equipped_at timestamptz,
  equipped_by uuid
)
language sql
stable
set search_path = public
as $$
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
  order by pe.slot;
$$;

grant execute on function public.get_pet_equipment(uuid) to authenticated;

create or replace function public.purchase_item_with_coins(
  p_item_id uuid,
  p_quantity int default 1
)
returns table (remaining_coins int, new_quantity int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_type text;
  v_total int;
  v_current_coins int;
  v_existing_qty int;
  v_final_qty int;
  v_metadata jsonb;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'invalid_quantity';
  end if;

  select price_coins, type, metadata
  into v_price, v_type, v_metadata
  from public.items
  where id = p_item_id
    and (
      (
        coalesce(is_active, false) = true
        and coalesce(metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_type is null then
    raise exception 'item_not_found';
  end if;

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  if v_type = 'cosmetic' then
    p_quantity := 1;
    select quantity
    into v_existing_qty
    from public.inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    if v_existing_qty is not null and v_existing_qty > 0 then
      raise exception 'already_owned';
    end if;
    v_final_qty := 1;
  elsif v_type = 'consumable' then
    select quantity
    into v_existing_qty
    from public.inventories
    where user_id = auth.uid()
      and item_id = p_item_id;
    v_final_qty := coalesce(v_existing_qty, 0) + p_quantity;
  else
    raise exception 'invalid_item_type';
  end if;

  v_total := v_price * p_quantity;

  select coins
  into v_current_coins
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_coins is null then
    raise exception 'profile_missing';
  end if;

  if v_current_coins < v_total then
    raise exception 'insufficient_coins';
  end if;

  update public.profiles
  set coins = coins - v_total
  where user_id = auth.uid();

  insert into public.inventories (user_id, item_id, quantity)
  values (auth.uid(), p_item_id, v_final_qty)
  on conflict (user_id, item_id)
  do update set quantity = excluded.quantity;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    null,
    'store_purchase',
    -v_total,
    jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity)
  );

  return query
  select (v_current_coins - v_total), v_final_qty;
end;
$$;

grant execute on function public.purchase_item_with_coins(uuid, int) to authenticated;

commit;
