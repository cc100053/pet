begin;

-- Both set_room_main_pet and add_room_pet contain `UPDATE public.rooms SET
-- main_pet_id = ...` statements but ran as SECURITY INVOKER. The rooms_update
-- RLS policy only allows the room owner to UPDATE rooms, so non-owner room
-- members would silently fail to mutate main_pet_id. Match the SECURITY
-- DEFINER pattern already used by use_pet_ticket and
-- purchase_and_use_pet_ticket; both functions still validate auth.uid() and
-- is_room_member before any mutation.

create or replace function public.set_room_main_pet(
  p_room_id uuid,
  p_pet_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1
    from public.pets p
    where p.id = p_pet_id
      and p.room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  update public.rooms
  set main_pet_id = p_pet_id
  where id = p_room_id;

  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);

  return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
end;
$$;

grant execute on function public.set_room_main_pet(uuid, uuid) to authenticated;

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
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

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

  v_name := trim(coalesce(p_pet_name, ''));
  if v_name = '' then
    raise exception 'invalid_pet_name';
  end if;
  if char_length(v_name) > 20 then
    raise exception 'pet_name_too_long';
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
    v_name,
    jsonb_build_object('pet_type', v_pet_type),
    'egg',
    1,
    0,
    1.0
  )
  returning id into v_pet_id;

  insert into public.pet_state (pet_id)
  select v_pet_id
  where not exists (
    select 1 from public.pet_state ps where ps.pet_id = v_pet_id
  );

  insert into public.room_pet_state (room_id)
  values (p_room_id)
  on conflict (room_id) do nothing;

  if not exists (
    select 1
    from public.rooms r
    where r.id = p_room_id
      and r.main_pet_id is not null
  ) then
    update public.rooms
    set main_pet_id = v_pet_id
    where id = p_room_id;
  end if;

  return query
  select v_pet_id, v_pet_count + 1;
end;
$$;

grant execute on function public.add_room_pet(uuid, text, text)
  to authenticated;

commit;
