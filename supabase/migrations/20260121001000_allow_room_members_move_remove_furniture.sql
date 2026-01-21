begin;

-- Allow any room member to move/remove furniture (not just owner)

drop policy if exists room_furniture_update on public.room_furniture;
create policy room_furniture_update on public.room_furniture
for update using (public.is_room_member(room_id));

drop policy if exists room_furniture_delete on public.room_furniture;
create policy room_furniture_delete on public.room_furniture
for delete using (public.is_room_member(room_id));

create or replace function public.update_room_furniture_position(
  p_id uuid,
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

  select room_id into v_room_id
  from public.room_furniture
  where id = p_id;

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  update public.room_furniture
  set position_x = least(greatest(p_position_x, 0), 1),
      position_y = least(greatest(p_position_y, 0), 1)
  where id = p_id
  returning * into v_row;

  return v_row;
end $$;

create or replace function public.remove_room_furniture(
  p_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_deleted uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id into v_room_id
  from public.room_furniture
  where id = p_id;

  if v_room_id is null then
    raise exception 'not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  delete from public.room_furniture
  where id = p_id
  returning id into v_deleted;

  return v_deleted is not null;
end $$;

commit;
