begin;

-- Atomically applies the multi-pet naming step that fires the first time a
-- room goes from 1 to 2 pets: rename the room and inherit/replace the first
-- pet's name in one shot. Both fields are optional so the caller can skip
-- either side. SECURITY DEFINER because rooms_update RLS restricts owners
-- only; multi-pet rooms can be co-edited by any member.
create or replace function public.apply_multi_pet_room_naming(
  p_room_id uuid,
  p_room_name text,
  p_first_pet_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_name text;
  v_first_pet_name text;
  v_first_pet_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  v_room_name := nullif(trim(coalesce(p_room_name, '')), '');
  v_first_pet_name := nullif(trim(coalesce(p_first_pet_name, '')), '');

  if v_room_name is not null and char_length(v_room_name) > 30 then
    raise exception 'room_name_too_long';
  end if;
  if v_first_pet_name is not null and char_length(v_first_pet_name) > 20 then
    raise exception 'pet_name_too_long';
  end if;

  if v_room_name is not null then
    update public.rooms
    set name = v_room_name
    where id = p_room_id;
  end if;

  if v_first_pet_name is not null then
    select coalesce(
      r.main_pet_id,
      (
        select p.id
        from public.pets p
        where p.room_id = r.id
        order by p.created_at asc, p.id
        limit 1
      )
    )
    into v_first_pet_id
    from public.rooms r
    where r.id = p_room_id;

    if v_first_pet_id is null then
      raise exception 'first_pet_not_found';
    end if;

    update public.pets
    set name = v_first_pet_name
    where id = v_first_pet_id;
  end if;

  return jsonb_build_object(
    'success', true,
    'room_name', v_room_name,
    'first_pet_id', v_first_pet_id,
    'first_pet_name', v_first_pet_name
  );
end;
$$;

grant execute on function public.apply_multi_pet_room_naming(uuid, text, text)
  to authenticated;

commit;
