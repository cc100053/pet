begin;

create or replace function public.update_room_furniture_transform(
  p_id uuid,
  p_scale numeric,
  p_position_x numeric,
  p_position_y numeric
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
    position_y = least(greatest(coalesce(p_position_y, 0), 0), 1)
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.update_room_furniture_transform(uuid, numeric, numeric, numeric)
to authenticated;

commit;
