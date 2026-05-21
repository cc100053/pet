begin;

create or replace function public.set_room_hunger_decay_paused(
  p_room_id uuid,
  p_paused_until timestamptz default null,
  p_reason text default null
)
returns table (
  room_id uuid,
  hunger_decay_paused_until timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  v_main_pet_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_debug_admin() then
    raise exception 'not_debug_admin';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select r.main_pet_id
  into v_main_pet_id
  from public.rooms r
  where r.id = p_room_id
    and not r.is_archived;

  if not found then
    raise exception 'room_not_found';
  end if;

  if p_paused_until is not null and p_paused_until > v_now then
    insert into public.room_debug_overrides (
      room_id,
      hunger_decay_paused_until,
      reason,
      created_by,
      updated_at
    ) values (
      p_room_id,
      p_paused_until,
      nullif(left(coalesce(p_reason, 'debug_hunger_freeze'), 200), ''),
      auth.uid(),
      v_now
    )
    on conflict on constraint room_debug_overrides_pkey do update
    set hunger_decay_paused_until = excluded.hunger_decay_paused_until,
        reason = excluded.reason,
        updated_at = v_now;

    update public.room_pet_state
    set hunger = 100,
        last_decay_at = v_now,
        updated_at = v_now
    where room_pet_state.room_id = p_room_id;

    update public.pet_state ps
    set hunger = 100,
        last_decay_at = v_now
    from public.pets p
    where p.id = ps.pet_id
      and p.id = v_main_pet_id
      and p.room_id = p_room_id;
  else
    delete from public.room_debug_overrides rdo
    where rdo.room_id = p_room_id;

    update public.room_pet_state
    set last_decay_at = v_now,
        updated_at = v_now
    where room_pet_state.room_id = p_room_id;

    update public.pet_state ps
    set last_decay_at = v_now
    from public.pets p
    where p.id = ps.pet_id
      and p.id = v_main_pet_id
      and p.room_id = p_room_id;
  end if;

  if v_main_pet_id is not null then
    perform public.refresh_pet_hunger_tick_schedule(v_main_pet_id, v_now);
  end if;

  return query
  select p_room_id,
         (
           select rdo.hunger_decay_paused_until
           from public.room_debug_overrides rdo
           where rdo.room_id = p_room_id
             and rdo.hunger_decay_paused_until > v_now
         );
end;
$$;

revoke all on function public.set_room_hunger_decay_paused(uuid, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.set_room_hunger_decay_paused(uuid, timestamptz, text)
  to authenticated;

commit;
