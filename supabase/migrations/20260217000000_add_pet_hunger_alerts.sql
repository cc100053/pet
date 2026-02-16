begin;

alter table public.pet_state
  add column if not exists hunger_alert_30_sent_at timestamptz,
  add column if not exists hunger_alert_30_message_id uuid references public.messages(id) on delete set null,
  add column if not exists hunger_alert_30_triggered_by uuid references auth.users(id) on delete set null,
  add column if not exists hunger_alert_10_sent_at timestamptz,
  add column if not exists hunger_alert_10_message_id uuid references public.messages(id) on delete set null,
  add column if not exists hunger_alert_10_triggered_by uuid references auth.users(id) on delete set null;

create or replace function public.handle_pet_hunger_alerts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_pet_name text;
  v_message_id uuid;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.hunger is null or old.hunger is null then
    return new;
  end if;

  if new.hunger > 30 then
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

  if old.hunger > 30
     and new.hunger <= 30
     and new.hunger > 0
     and new.hunger_alert_30_sent_at is null then
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
$$;

drop trigger if exists before_pet_state_hunger_alerts on public.pet_state;
create trigger before_pet_state_hunger_alerts
before update of hunger on public.pet_state
for each row
execute function public.handle_pet_hunger_alerts();

commit;
