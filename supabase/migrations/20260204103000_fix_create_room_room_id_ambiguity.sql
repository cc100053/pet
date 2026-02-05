-- Fix create_room ambiguity by preferring column names when conflicts exist.
-- This guards against "room_id" output parameter clashing with table columns.

create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_code text;
  v_room_id uuid;
  v_pet_id uuid;
  v_background_id uuid;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (
      select 1
      from public.rooms r
      where r.invite_code = v_code
    );
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into public.rooms (name, invite_code, invite_expires_at, created_by)
  values (p_name, v_code, now() + interval '60 minutes', auth.uid())
  returning id into v_room_id;

  insert into public.room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  insert into public.pets (room_id, name, stage, level, days_alive, scale)
  values (v_room_id, null, 'egg', 1, 0, 1.0)
  returning id into v_pet_id;

  insert into public.pet_state (pet_id) values (v_pet_id);

  select id into v_background_id
  from public.items
  where sku = 'background_default'
  limit 1;

  if v_background_id is not null then
    insert into public.room_backgrounds (room_id, item_id, acquired_by)
    values (v_room_id, v_background_id, auth.uid())
    on conflict (room_id, item_id) do nothing;

    insert into public.room_background_state (
      room_id,
      active_item_id,
      updated_by
    ) values (
      v_room_id,
      v_background_id,
      auth.uid()
    )
    on conflict (room_id) do update
    set active_item_id = excluded.active_item_id,
        updated_by = excluded.updated_by;
  end if;

  return query select v_room_id as room_id, v_code as invite_code;
end;
$$;
