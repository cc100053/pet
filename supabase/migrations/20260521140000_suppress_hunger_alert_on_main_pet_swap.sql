-- Fix: switching the main pet spawned a spurious low-hunger alert (chat system
-- message + toast + push) even though room hunger never changed.
--
-- Root cause: set_room_main_pet inserts the promoted pet's pet_state at the
-- default hunger (100), then sync_room_pet_state_to_main_pet_state updates it
-- down to the shared (low) room hunger. The before-update trigger
-- handle_pet_hunger_alerts sees old.hunger=100 -> new.hunger<=50/30 as a fresh
-- downward crossing and creates a hunger_alert message (triggered_by=auth.uid),
-- which the client then surfaces as a toast and dispatches as a push.
--
-- Fix: gate the alert trigger behind a transaction-local flag and set it while
-- set_room_main_pet performs the swap sync, so the swap can't manufacture a
-- false crossing. Genuine decay (tick_pet_state) is unaffected.

create or replace function public.handle_pet_hunger_alerts()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_room_id uuid;
  v_pet_name text;
  v_message_id uuid;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  -- Skip alert generation while a main-pet swap re-materializes pet_state, so
  -- mirroring the shared room hunger onto the promoted pet does not look like a
  -- fresh downward crossing.
  if coalesce(current_setting('app.skip_hunger_alerts', true), 'off') = 'on' then
    return new;
  end if;

  if new.hunger is null or old.hunger is null then
    return new;
  end if;

  if new.hunger > 50 then
    new.hunger_alert_50_sent_at := null;
    new.hunger_alert_50_message_id := null;
    new.hunger_alert_50_triggered_by := null;
    new.hunger_alert_30_sent_at := null;
    new.hunger_alert_30_message_id := null;
    new.hunger_alert_30_triggered_by := null;
    new.hunger_alert_10_sent_at := null;
    new.hunger_alert_10_message_id := null;
    new.hunger_alert_10_triggered_by := null;
  elsif new.hunger > 30 then
    new.hunger_alert_30_sent_at := null;
    new.hunger_alert_30_message_id := null;
    new.hunger_alert_30_triggered_by := null;
    new.hunger_alert_10_sent_at := null;
    new.hunger_alert_10_message_id := null;
    new.hunger_alert_10_triggered_by := null;
  elsif new.hunger > 10 then
    new.hunger_alert_10_sent_at := null;
    new.hunger_alert_10_message_id := null;
    new.hunger_alert_10_triggered_by := null;
  end if;

  if old.hunger > 50
     and new.hunger <= 50
     and new.hunger > 0
     and new.hunger_alert_50_sent_at is null then
    select p.room_id, nullif(trim(p.name), '')
    into v_room_id, v_pet_name
    from public.pets p
    where p.id = new.pet_id;

    if v_room_id is not null then
      insert into public.messages (room_id, sender_id, type, body)
      values (
        v_room_id,
        null,
        'system',
        'hunger_alert_50::' || coalesce(v_pet_name, 'Pet')
      )
      returning id into v_message_id;

      new.hunger_alert_50_sent_at := now();
      new.hunger_alert_50_message_id := v_message_id;
      new.hunger_alert_50_triggered_by := auth.uid();
    end if;
  end if;

  if old.hunger > 30
     and new.hunger <= 30
     and new.hunger > 0
     and new.hunger_alert_30_sent_at is null then
    if v_room_id is null then
      select p.room_id, nullif(trim(p.name), '')
      into v_room_id, v_pet_name
      from public.pets p
      where p.id = new.pet_id;
    end if;

    if v_room_id is not null then
      insert into public.messages (room_id, sender_id, type, body)
      values (
        v_room_id,
        null,
        'system',
        'hunger_alert_30::' || coalesce(v_pet_name, 'Pet')
      )
      returning id into v_message_id;

      new.hunger_alert_30_sent_at := now();
      new.hunger_alert_30_message_id := v_message_id;
      new.hunger_alert_30_triggered_by := auth.uid();
    end if;
  end if;

  if old.hunger > 10
     and new.hunger <= 10
     and new.hunger > 0
     and new.hunger_alert_10_sent_at is null then
    if v_room_id is null then
      select p.room_id, nullif(trim(p.name), '')
      into v_room_id, v_pet_name
      from public.pets p
      where p.id = new.pet_id;
    end if;

    if v_room_id is not null then
      insert into public.messages (room_id, sender_id, type, body)
      values (
        v_room_id,
        null,
        'system',
        'hunger_alert_10::' || coalesce(v_pet_name, 'Pet')
      )
      returning id into v_message_id;

      new.hunger_alert_10_sent_at := now();
      new.hunger_alert_10_message_id := v_message_id;
      new.hunger_alert_10_triggered_by := auth.uid();
    end if;
  end if;

  return new;
end;
$function$;

create or replace function public.set_room_main_pet(p_room_id uuid, p_pet_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  -- Mirroring shared room hunger onto the freshly-promoted pet would otherwise
  -- look like a downward crossing and spawn a bogus hunger alert. Suppress
  -- alert generation just for this sync.
  perform set_config('app.skip_hunger_alerts', 'on', true);
  perform public.sync_room_pet_state_to_main_pet_state(p_room_id);
  perform set_config('app.skip_hunger_alerts', 'off', true);

  return jsonb_build_object('success', true, 'main_pet_id', p_pet_id);
end;
$function$;
