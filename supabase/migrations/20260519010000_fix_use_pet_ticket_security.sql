begin;

-- use_pet_ticket was SECURITY INVOKER (default), but the rooms_update RLS
-- policy restricts UPDATE to room owners only. A non-owner member using an
-- inventory pet ticket would silently fail to set main_pet_id, matching the
-- same SECURITY DEFINER approach used by purchase_and_use_pet_ticket.
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

  select i.id
  into v_ticket_item_id
  from public.items i
  where i.sku = 'pet_ticket'
  limit 1;

  if v_ticket_item_id is null then
    raise exception 'pet_ticket_not_found';
  end if;

  select inv.quantity
  into v_ticket_quantity
  from public.inventories inv
  where inv.user_id = auth.uid()
    and inv.item_id = v_ticket_item_id
  for update;

  if coalesce(v_ticket_quantity, 0) <= 0 then
    raise exception 'pet_ticket_not_owned';
  end if;

  v_remaining_tickets := v_ticket_quantity - 1;

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
  on conflict on constraint pet_state_pkey do nothing;

  insert into public.room_pet_state (room_id)
  values (p_room_id)
  on conflict (room_id) do nothing;

  if v_remaining_tickets > 0 then
    update public.inventories
    set quantity = v_remaining_tickets
    where user_id = auth.uid()
      and item_id = v_ticket_item_id;
  else
    delete from public.inventories
    where user_id = auth.uid()
      and item_id = v_ticket_item_id;
  end if;

  update public.rooms
  set main_pet_id = coalesce(main_pet_id, v_pet_id)
  where id = p_room_id;

  return query
  select v_pet_id, v_pet_count + 1, v_remaining_tickets;
end;
$$;

grant execute on function public.use_pet_ticket(uuid, text, text)
  to authenticated;

commit;
