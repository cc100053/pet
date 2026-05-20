begin;

-- Bug: set_room_main_pet swaps a pet between `pets` and `room_extra_pets` by
-- delete+insert of the same id. The AFTER DELETE cleanup trigger then wiped
-- that pet's pet_equipment even though the pet still exists (just in the other
-- table). Guard the cleanup with a transaction-local flag that the swap sets,
-- so equipment follows the pet across the move.
create or replace function public.cleanup_pet_equipment_on_pet_delete()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if coalesce(current_setting('app.skip_pet_equipment_cleanup', true), 'off') = 'on' then
    return old;
  end if;
  delete from public.pet_equipment where pet_id = old.id;
  return old;
end;
$$;

create or replace function public.set_room_main_pet(
  p_room_id uuid, p_pet_id uuid
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_old_main_id uuid; v_old_main record; v_new_main record;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not public.is_room_member(p_room_id) then raise exception 'not_room_member'; end if;
  perform 1 from public.rooms where id = p_room_id for update;
  select main_pet_id into v_old_main_id from public.rooms where id = p_room_id;
  if v_old_main_id = p_pet_id then
    return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
  end if;
  if not exists (
    select 1 from public.pets where id = p_pet_id and room_id = p_room_id
    union all
    select 1 from public.room_extra_pets where id = p_pet_id and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  -- Keep equipment attached to each pet while rows hop tables.
  perform set_config('app.skip_pet_equipment_cleanup', 'on', true);

  update public.rooms set main_pet_id = null where id = p_room_id;

  if v_old_main_id is not null then
    select * into v_old_main from public.pets where id = v_old_main_id;
    if v_old_main.id is not null then
      delete from public.pets where id = v_old_main_id;
      insert into public.room_extra_pets (
        id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
        avatar_url, created_at, updated_at
      )
      values (
        v_old_main.id, v_old_main.room_id, v_old_main.name, v_old_main.color_dna,
        v_old_main.stage, v_old_main.level, v_old_main.days_alive, v_old_main.scale,
        v_old_main.exp, v_old_main.avatar_url, v_old_main.created_at, now()
      );
    end if;
  end if;

  select * into v_new_main from public.room_extra_pets where id = p_pet_id;
  if v_new_main.id is not null then
    delete from public.room_extra_pets where id = p_pet_id;
    insert into public.pets (
      id, room_id, name, color_dna, stage, level, days_alive, scale, exp,
      avatar_url, created_at, updated_at
    )
    values (
      v_new_main.id, v_new_main.room_id, v_new_main.name, v_new_main.color_dna,
      v_new_main.stage, v_new_main.level, v_new_main.days_alive, v_new_main.scale,
      v_new_main.exp, v_new_main.avatar_url, v_new_main.created_at, now()
    );
    insert into public.pet_state (pet_id) values (p_pet_id) on conflict on constraint pet_state_pkey do nothing;
  end if;

  update public.rooms
  set main_pet_id = p_pet_id,
      name = coalesce(
        nullif(btrim(v_new_main.name), ''),
        nullif(btrim(v_old_main.name), ''),
        name
      )
  where id = p_room_id;

  perform set_config('app.skip_pet_equipment_cleanup', 'off', true);

  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);
  return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
end;
$$;

grant execute on function public.set_room_main_pet(uuid, uuid) to authenticated;

commit;
