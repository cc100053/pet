-- Keep legacy 4-arg furniture RPC calls unambiguous for old clients while
-- preserving the 6-arg canvas-coordinate overloads for new clients.
begin;

drop function if exists public.place_room_furniture(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric
);

create function public.place_room_furniture(
  p_room_id uuid,
  p_item_id uuid,
  p_position_x numeric,
  p_position_y numeric,
  p_canvas_position_x numeric,
  p_canvas_position_y numeric
)
returns public.room_furniture
language plpgsql
security definer
set search_path = public
as $$
declare
  v_qty int;
  v_placed int;
  v_is_furniture boolean;
  v_row public.room_furniture%rowtype;
  v_x numeric;
  v_y numeric;
  v_cx numeric;
  v_cy numeric;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select (metadata->>'category') = 'furniture'
  into v_is_furniture
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

  if v_is_furniture is distinct from true then
    raise exception 'item_not_furniture';
  end if;

  select coalesce(sum(quantity), 0)::int
  into v_qty
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  select count(*)::int
  into v_placed
  from public.room_furniture
  where room_id = p_room_id
    and item_id = p_item_id;

  if v_qty <= v_placed then
    raise exception 'insufficient_inventory';
  end if;

  v_x := least(greatest(p_position_x, 0), 1);
  v_y := least(greatest(p_position_y, 0), 1);
  v_cx := least(greatest(coalesce(p_canvas_position_x, v_x), 0), 1);
  v_cy := least(greatest(coalesce(p_canvas_position_y, v_y), 0), 1);

  insert into public.room_furniture (
    room_id,
    item_id,
    owner_user_id,
    position_x,
    position_y,
    canvas_position_x,
    canvas_position_y,
    scale
  ) values (
    p_room_id,
    p_item_id,
    auth.uid(),
    v_x,
    v_y,
    v_cx,
    v_cy,
    1.0
  )
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.place_room_furniture(
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric
) to authenticated;

drop function if exists public.update_room_furniture_transform(
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric
);

create function public.update_room_furniture_transform(
  p_id uuid,
  p_scale numeric,
  p_position_x numeric,
  p_position_y numeric,
  p_canvas_position_x numeric,
  p_canvas_position_y numeric
)
returns public.room_furniture
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.room_furniture%rowtype;
  v_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id
  into v_room_id
  from public.room_furniture
  where id = p_id;

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  update public.room_furniture
  set
    scale = least(greatest(coalesce(p_scale, 1.0), 0.8), 2.0),
    position_x = least(greatest(coalesce(p_position_x, 0), 0), 1),
    position_y = least(greatest(coalesce(p_position_y, 0), 0), 1),
    canvas_position_x = least(
      greatest(coalesce(p_canvas_position_x, p_position_x, 0), 0),
      1
    ),
    canvas_position_y = least(
      greatest(coalesce(p_canvas_position_y, p_position_y, 0), 0),
      1
    )
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.update_room_furniture_transform(
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric
) to authenticated;

commit;
