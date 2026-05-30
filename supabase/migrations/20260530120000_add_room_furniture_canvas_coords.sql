-- Plan A: fixed virtual room canvas for furniture sync.
-- Additive + backward compatible: old clients keep reading/writing legacy
-- position_x/y (top-left fraction). New clients dual-write canvas center
-- fractions here and prefer them on read. New RPC overloads add optional canvas
-- params with DEFAULT NULL so the original 4-arg signatures remain intact for
-- old clients.
begin;

alter table public.room_furniture
  add column if not exists canvas_position_x numeric,
  add column if not exists canvas_position_y numeric;

alter table public.room_furniture
  drop constraint if exists room_furniture_canvas_position_x;
alter table public.room_furniture
  add constraint room_furniture_canvas_position_x
  check (
    canvas_position_x is null
    or (canvas_position_x >= 0 and canvas_position_x <= 1)
  );

alter table public.room_furniture
  drop constraint if exists room_furniture_canvas_position_y;
alter table public.room_furniture
  add constraint room_furniture_canvas_position_y
  check (
    canvas_position_y is null
    or (canvas_position_y >= 0 and canvas_position_y <= 1)
  );

-- Place: 6-arg overload (original 4-arg version stays for old clients).
create or replace function public.place_room_furniture(
  p_room_id uuid,
  p_item_id uuid,
  p_position_x numeric,
  p_position_y numeric,
  p_canvas_position_x numeric default null,
  p_canvas_position_y numeric default null
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
    and is_active;

  if v_is_furniture is distinct from true then
    raise exception 'item_not_furniture';
  end if;

  select quantity into v_qty
  from public.inventories
  where user_id = auth.uid()
    and item_id = p_item_id;

  v_qty := coalesce(v_qty, 0);

  select count(*)
  into v_placed
  from public.room_furniture
  where room_id = p_room_id
    and item_id = p_item_id
    and owner_user_id = auth.uid();

  if v_qty <= v_placed then
    raise exception 'insufficient_inventory';
  end if;

  v_x := least(greatest(p_position_x, 0), 1);
  v_y := least(greatest(p_position_y, 0), 1);
  v_cx := case
            when p_canvas_position_x is null then null
            else least(greatest(p_canvas_position_x, 0), 1)
          end;
  v_cy := case
            when p_canvas_position_y is null then null
            else least(greatest(p_canvas_position_y, 0), 1)
          end;

  insert into public.room_furniture (
    room_id,
    item_id,
    owner_user_id,
    position_x,
    position_y,
    canvas_position_x,
    canvas_position_y
  ) values (
    p_room_id,
    p_item_id,
    auth.uid(),
    v_x,
    v_y,
    v_cx,
    v_cy
  )
  returning * into v_row;

  return v_row;
end $$;

grant execute on function public.place_room_furniture(
  uuid, uuid, numeric, numeric, numeric, numeric
) to authenticated;

-- Transform: 6-arg overload (original 4-arg version stays for old clients).
create or replace function public.update_room_furniture_transform(
  p_id uuid,
  p_scale numeric,
  p_position_x numeric,
  p_position_y numeric,
  p_canvas_position_x numeric default null,
  p_canvas_position_y numeric default null
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
    canvas_position_x = case
      when p_canvas_position_x is null then canvas_position_x
      else least(greatest(p_canvas_position_x, 0), 1)
    end,
    canvas_position_y = case
      when p_canvas_position_y is null then canvas_position_y
      else least(greatest(p_canvas_position_y, 0), 1)
    end
  where id = p_id
  returning * into v_row;

  return v_row;
end $$;

grant execute on function public.update_room_furniture_transform(
  uuid, numeric, numeric, numeric, numeric, numeric
) to authenticated;

commit;
