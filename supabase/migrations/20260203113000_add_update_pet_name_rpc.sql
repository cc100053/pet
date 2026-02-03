-- Allow authenticated room members to rename their pet.
create or replace function public.update_pet_name(
  p_pet_id uuid,
  p_name text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_trimmed text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id into v_room_id from pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  v_trimmed := trim(coalesce(p_name, ''));
  if v_trimmed = '' then
    raise exception 'invalid_name';
  end if;
  if char_length(v_trimmed) > 20 then
    raise exception 'name_too_long';
  end if;

  update pets
  set name = v_trimmed
  where id = p_pet_id;
end;
$$;

grant execute on function public.update_pet_name(uuid, text) to authenticated;
