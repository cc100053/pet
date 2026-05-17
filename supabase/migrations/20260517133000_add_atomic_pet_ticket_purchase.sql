begin;

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
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1
  from public.rooms r
  where r.id = p_room_id
  for update;

  if not found then
    raise exception 'room_not_found';
  end if;

  select count(*)::int
  into v_pet_count
  from public.pets p
  where p.room_id = p_room_id;

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

  select i.price_diamonds
  into v_price
  from public.items i
  where i.id = p_item_id
    and i.sku = 'pet_ticket'
    and (i.metadata->>'category') = 'pet_ticket'
    and (
      (
        coalesce(i.is_active, false) = true
        and coalesce(i.metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(i.metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(i.metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select p.diamonds
  into v_current_diamonds
  from public.profiles p
  where p.user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  if v_current_diamonds < v_price then
    raise exception 'insufficient_diamonds';
  end if;

  insert into public.pets (
    room_id,
    name,
    color_dna,
    stage,
    level,
    days_alive,
    scale
  )
  values (
    p_room_id,
    v_pet_name,
    jsonb_build_object('pet_type', v_pet_type),
    'egg',
    1,
    0,
    1.0
  )
  returning id into v_pet_id;

  insert into public.pet_state (pet_id)
  values (v_pet_id)
  on conflict (pet_id) do nothing;

  insert into public.room_pet_state (room_id)
  values (p_room_id)
  on conflict (room_id) do nothing;

  update public.rooms
  set main_pet_id = coalesce(main_pet_id, v_pet_id)
  where id = p_room_id;

  update public.profiles
  set diamonds = diamonds - v_price
  where user_id = auth.uid();

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object(
      'item_id', p_item_id,
      'quantity', 1,
      'pet_id', v_pet_id,
      'pet_type', v_pet_type
    )
  );

  return query
  select v_pet_id, v_pet_count + 1, v_current_diamonds - v_price;
end;
$$;

grant execute on function public.purchase_and_use_pet_ticket(uuid, uuid, text, text)
  to authenticated;

commit;
