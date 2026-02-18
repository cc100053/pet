-- Sync room timezone to the new owner's profile timezone when ownership
-- transfers (e.g., owner leaves and next active member is promoted).

create or replace function public.ensure_room_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_owner uuid;
  v_owner_timezone text;
begin
  v_room_id := coalesce(new.room_id, old.room_id);
  if v_room_id is null then
    return null;
  end if;

  select user_id into v_owner
  from room_members
  where room_id = v_room_id
    and role = 'owner'
    and is_active
  limit 1;

  if v_owner is null then
    select user_id into v_owner
    from room_members
    where room_id = v_room_id
      and is_active
    order by joined_at asc
    limit 1;

    if v_owner is not null then
      update room_members
      set role = 'owner'
      where room_id = v_room_id
        and user_id = v_owner;

      select ptn.name
      into v_owner_timezone
      from public.profiles pf
      left join pg_timezone_names ptn
        on ptn.name = nullif(trim(coalesce(pf.timezone, '')), '')
      where pf.user_id = v_owner
      limit 1;

      update rooms
      set created_by = v_owner,
          timezone = coalesce(v_owner_timezone, 'UTC')
      where id = v_room_id;
    end if;
  end if;

  return null;
end;
$$;
