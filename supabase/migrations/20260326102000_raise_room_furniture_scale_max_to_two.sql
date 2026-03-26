begin;

alter table public.room_furniture
  drop constraint if exists room_furniture_scale_range;

alter table public.room_furniture
  add constraint room_furniture_scale_range
  check (scale >= 0.8 and scale <= 2.0);

create or replace function public.update_room_furniture_scale(
  p_id uuid,
  p_scale numeric
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
  set scale = least(greatest(coalesce(p_scale, 1.0), 0.8), 2.0)
  where id = p_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.update_room_furniture_scale(uuid, numeric) to authenticated;

commit;
