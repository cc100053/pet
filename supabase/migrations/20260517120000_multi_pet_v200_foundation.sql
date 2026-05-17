begin;

alter table public.pets
  drop constraint if exists pets_room_id_key;

alter table public.rooms
  add column if not exists main_pet_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'rooms_main_pet_id_fkey'
      and conrelid = 'public.rooms'::regclass
  ) then
    alter table public.rooms
      add constraint rooms_main_pet_id_fkey
      foreign key (main_pet_id)
      references public.pets(id)
      on delete set null;
  end if;
end $$;

create index if not exists rooms_main_pet_id_idx
  on public.rooms (main_pet_id);

create index if not exists pets_room_created_at_idx
  on public.pets (room_id, created_at, id);

create table if not exists public.room_pet_state (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  hunger int not null default 100,
  mood text not null default 'mid',
  hygiene int not null default 100,
  poop_at timestamptz,
  last_decay_at timestamptz not null default now(),
  last_feed_at timestamptz,
  last_touch_at timestamptz,
  last_clean_at timestamptz,
  mood_boost int not null default 0,
  mood_boost_expires_at timestamptz,
  last_feed_boost_at timestamptz,
  last_touch_boost_at timestamptz,
  last_clean_boost_at timestamptz,
  feed_count_since_poop int not null default 0,
  poop_count int not null default 0,
  poop_positions jsonb not null default '[]'::jsonb,
  last_poop_spawn_at timestamptz,
  feed_burst_count int not null default 0,
  feed_burst_started_at timestamptz,
  last_overfed_at timestamptz,
  hunger_alert_50_sent_at timestamptz,
  hunger_alert_50_message_id uuid references public.messages(id) on delete set null,
  hunger_alert_50_triggered_by uuid references auth.users(id) on delete set null,
  hunger_alert_30_sent_at timestamptz,
  hunger_alert_30_message_id uuid references public.messages(id) on delete set null,
  hunger_alert_30_triggered_by uuid references auth.users(id) on delete set null,
  hunger_alert_10_sent_at timestamptz,
  hunger_alert_10_message_id uuid references public.messages(id) on delete set null,
  hunger_alert_10_triggered_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint room_pet_state_hunger check (hunger between 0 and 100),
  constraint room_pet_state_hygiene check (hygiene between 0 and 100),
  constraint room_pet_state_mood check (mood in ('mid', 'high', 'sad')),
  constraint room_pet_state_mood_boost check (mood_boost between 0 and 2),
  constraint room_pet_state_feed_count check (feed_count_since_poop >= 0),
  constraint room_pet_state_poop_count check (poop_count >= 0)
);

alter table public.room_pet_state enable row level security;

drop policy if exists room_pet_state_select on public.room_pet_state;
create policy room_pet_state_select
on public.room_pet_state
for select
to authenticated
using (public.is_room_member(room_id));

drop policy if exists room_pet_state_insert on public.room_pet_state;
create policy room_pet_state_insert
on public.room_pet_state
for insert
to authenticated
with check (public.is_room_member(room_id));

drop policy if exists room_pet_state_update on public.room_pet_state;
create policy room_pet_state_update
on public.room_pet_state
for update
to authenticated
using (public.is_room_member(room_id))
with check (public.is_room_member(room_id));

revoke all on table public.room_pet_state from public, anon;
grant select, insert, update on table public.room_pet_state to authenticated;
grant select, insert, update, delete on table public.room_pet_state to service_role;

insert into public.room_pet_state (
  room_id,
  hunger,
  mood,
  hygiene,
  poop_at,
  last_decay_at,
  last_feed_at,
  last_touch_at,
  last_clean_at,
  mood_boost,
  mood_boost_expires_at,
  last_feed_boost_at,
  last_touch_boost_at,
  last_clean_boost_at,
  feed_count_since_poop,
  poop_count,
  poop_positions,
  last_poop_spawn_at,
  feed_burst_count,
  feed_burst_started_at,
  last_overfed_at,
  hunger_alert_50_sent_at,
  hunger_alert_50_message_id,
  hunger_alert_50_triggered_by,
  hunger_alert_30_sent_at,
  hunger_alert_30_message_id,
  hunger_alert_30_triggered_by,
  hunger_alert_10_sent_at,
  hunger_alert_10_message_id,
  hunger_alert_10_triggered_by,
  created_at,
  updated_at
)
select distinct on (p.room_id)
  p.room_id,
  ps.hunger,
  ps.mood,
  ps.hygiene,
  ps.poop_at,
  ps.last_decay_at,
  ps.last_feed_at,
  ps.last_touch_at,
  ps.last_clean_at,
  ps.mood_boost,
  ps.mood_boost_expires_at,
  ps.last_feed_boost_at,
  ps.last_touch_boost_at,
  ps.last_clean_boost_at,
  ps.feed_count_since_poop,
  ps.poop_count,
  ps.poop_positions,
  ps.last_poop_spawn_at,
  ps.feed_burst_count,
  ps.feed_burst_started_at,
  ps.last_overfed_at,
  ps.hunger_alert_50_sent_at,
  ps.hunger_alert_50_message_id,
  ps.hunger_alert_50_triggered_by,
  ps.hunger_alert_30_sent_at,
  ps.hunger_alert_30_message_id,
  ps.hunger_alert_30_triggered_by,
  ps.hunger_alert_10_sent_at,
  ps.hunger_alert_10_message_id,
  ps.hunger_alert_10_triggered_by,
  now(),
  now()
from public.pets p
join public.pet_state ps on ps.pet_id = p.id
order by p.room_id, p.created_at asc, p.id
on conflict (room_id) do nothing;

update public.rooms r
set main_pet_id = p.id
from (
  select distinct on (room_id) room_id, id
  from public.pets
  order by room_id, created_at asc, id
) p
where r.id = p.room_id
  and r.main_pet_id is null;

create or replace function public.validate_room_main_pet()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.main_pet_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.pets p
    where p.id = new.main_pet_id
      and p.room_id = new.id
  ) then
    raise exception 'main_pet_not_in_room';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_room_main_pet_before_write on public.rooms;
create trigger validate_room_main_pet_before_write
before insert or update of main_pet_id on public.rooms
for each row
execute function public.validate_room_main_pet();

create or replace function public.sync_room_pet_state_to_main_pet_state(
  p_room_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet_id uuid;
begin
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
  into v_pet_id
  from public.rooms r
  where r.id = p_room_id;

  if v_pet_id is null then
    return;
  end if;

  insert into public.pet_state (pet_id)
  values (v_pet_id)
  on conflict (pet_id) do nothing;

  update public.pet_state ps
  set hunger = rps.hunger,
      mood = rps.mood,
      hygiene = rps.hygiene,
      poop_at = rps.poop_at,
      last_decay_at = rps.last_decay_at,
      last_feed_at = rps.last_feed_at,
      last_touch_at = rps.last_touch_at,
      last_clean_at = rps.last_clean_at,
      mood_boost = rps.mood_boost,
      mood_boost_expires_at = rps.mood_boost_expires_at,
      last_feed_boost_at = rps.last_feed_boost_at,
      last_touch_boost_at = rps.last_touch_boost_at,
      last_clean_boost_at = rps.last_clean_boost_at,
      feed_count_since_poop = rps.feed_count_since_poop,
      poop_count = rps.poop_count,
      poop_positions = rps.poop_positions,
      last_poop_spawn_at = rps.last_poop_spawn_at,
      feed_burst_count = rps.feed_burst_count,
      feed_burst_started_at = rps.feed_burst_started_at,
      last_overfed_at = rps.last_overfed_at
  from public.room_pet_state rps
  where rps.room_id = p_room_id
    and ps.pet_id = v_pet_id;
end;
$$;

grant execute on function public.sync_room_pet_state_to_main_pet_state(uuid)
  to authenticated, service_role;

create or replace function public.get_room_pets(
  p_room_id uuid
)
returns table (
  pet_id uuid,
  room_id uuid,
  name text,
  color_dna jsonb,
  stage text,
  level int,
  exp int,
  avatar_url text,
  is_main boolean,
  created_at timestamptz
)
language plpgsql
stable
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  return query
  select
    p.id,
    p.room_id,
    p.name,
    p.color_dna,
    p.stage,
    p.level,
    p.exp,
    p.avatar_url,
    p.id = r.main_pet_id,
    p.created_at
  from public.pets p
  join public.rooms r on r.id = p.room_id
  where p.room_id = p_room_id
  order by
    case when p.id = r.main_pet_id then 0 else 1 end,
    p.created_at asc,
    p.id;
end;
$$;

grant execute on function public.get_room_pets(uuid) to authenticated;

create or replace function public.set_room_main_pet(
  p_room_id uuid,
  p_pet_id uuid
)
returns jsonb
language plpgsql
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

create or replace function public.purchase_room_equipment_with_coins(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_coins int,
  new_quantity int,
  room_total_quantity int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_coins int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_pet_count int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

  select price_coins
  into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (
        coalesce(is_active, false) = true
        and coalesce(metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_price is null then
    raise exception 'item_not_for_coins';
  end if;

  select greatest(1, count(*))::int
  into v_pet_count
  from public.pets
  where room_id = p_room_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) >= v_pet_count then
    raise exception 'equipment_capacity_reached';
  end if;

  select coins
  into v_current_coins
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_coins is null then
    raise exception 'profile_missing';
  end if;

  if v_current_coins < v_price then
    raise exception 'insufficient_coins';
  end if;

  update public.profiles
  set coins = coins - v_price
  where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = public.room_item_inventories.quantity + 1;

  select quantity
  into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  return query
  select
    (v_current_coins - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_coins(uuid, uuid)
  to authenticated;

create or replace function public.purchase_room_equipment_with_diamonds(
  p_room_id uuid,
  p_item_id uuid
)
returns table (
  remaining_diamonds int,
  new_quantity int,
  room_total_quantity int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price int;
  v_current_diamonds int;
  v_new_quantity int;
  v_room_total_quantity int;
  v_pet_count int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

  select price_diamonds
  into v_price
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and (
      (
        coalesce(is_active, false) = true
        and coalesce(metadata->>'visibility_mode', 'public') = 'public'
      )
      or (
        coalesce(metadata->>'visibility_mode', 'public') = 'version_gated'
        and coalesce(metadata->>'shop_visibility', '') <> 'hidden'
      )
    );

  if v_price is null then
    raise exception 'item_not_for_diamonds';
  end if;

  select greatest(1, count(*))::int
  into v_pet_count
  from public.pets
  where room_id = p_room_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  if coalesce(v_room_total_quantity, 0) >= v_pet_count then
    raise exception 'equipment_capacity_reached';
  end if;

  select diamonds
  into v_current_diamonds
  from public.profiles
  where user_id = auth.uid()
  for update;

  if v_current_diamonds is null then
    raise exception 'profile_missing';
  end if;

  if v_current_diamonds < v_price then
    raise exception 'insufficient_diamonds';
  end if;

  update public.profiles
  set diamonds = diamonds - v_price
  where user_id = auth.uid();

  insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
  values (p_room_id, auth.uid(), p_item_id, 1)
  on conflict (room_id, user_id, item_id)
  do update set quantity = public.room_item_inventories.quantity + 1;

  select quantity
  into v_new_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and user_id = auth.uid()
    and item_id = p_item_id;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_quantity
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  insert into public.diamond_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'store_purchase',
    -v_price,
    jsonb_build_object('item_id', p_item_id, 'quantity', 1)
  );

  return query
  select
    (v_current_diamonds - v_price),
    coalesce(v_new_quantity, 0),
    coalesce(v_room_total_quantity, 0);
end;
$$;

grant execute on function public.purchase_room_equipment_with_diamonds(uuid, uuid)
  to authenticated;

create or replace function public.equip_pet_item(
  p_pet_id uuid,
  p_room_id uuid,
  p_item_id uuid,
  p_slot text
)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_item_sku text;
  v_global_qty int;
  v_room_total_qty int;
  v_equipped_qty int;
  v_current_item_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_slot not in ('head', 'face', 'body', 'back') then
    raise exception 'invalid_slot';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  perform 1 from public.rooms where id = p_room_id for update;

  if not exists (
    select 1
    from public.pets
    where id = p_pet_id
      and room_id = p_room_id
  ) then
    raise exception 'pet_not_found';
  end if;

  select sku
  into v_item_sku
  from public.items
  where id = p_item_id
    and metadata->>'category' = 'equipment'
    and metadata->>'equipment_slot' = p_slot;

  if v_item_sku is null then
    raise exception 'item_not_equipment_for_slot';
  end if;

  if not exists (
    select 1
    from public.room_item_inventories rii
    where rii.room_id = p_room_id
      and rii.item_id = p_item_id
      and rii.quantity > 0
  ) then
    select quantity
    into v_global_qty
    from public.inventories
    where user_id = v_user_id
      and item_id = p_item_id
      and quantity > 0
    for update;

    if coalesce(v_global_qty, 0) <= 0 then
      raise exception 'item_not_owned_in_room';
    end if;

    insert into public.room_item_inventories (room_id, user_id, item_id, quantity)
    values (p_room_id, v_user_id, p_item_id, 1)
    on conflict (room_id, user_id, item_id)
    do update set quantity = greatest(public.room_item_inventories.quantity, 1);

    if v_global_qty > 1 then
      update public.inventories
      set quantity = v_global_qty - 1
      where user_id = v_user_id
        and item_id = p_item_id;
    else
      delete from public.inventories
      where user_id = v_user_id
        and item_id = p_item_id;
    end if;
  end if;

  select coalesce(sum(quantity), 0)::int
  into v_room_total_qty
  from public.room_item_inventories
  where room_id = p_room_id
    and item_id = p_item_id;

  if coalesce(v_room_total_qty, 0) <= 0 then
    raise exception 'item_not_owned_in_room';
  end if;

  select item_id
  into v_current_item_id
  from public.pet_equipment
  where room_id = p_room_id
    and pet_id = p_pet_id
    and slot = p_slot
  for update;

  if v_current_item_id is distinct from p_item_id then
    select count(*)::int
    into v_equipped_qty
    from public.pet_equipment
    where room_id = p_room_id
      and item_id = p_item_id;

    if coalesce(v_equipped_qty, 0) >= v_room_total_qty then
      raise exception 'equipment_copy_unavailable';
    end if;
  end if;

  insert into public.pet_equipment (
    pet_id,
    room_id,
    item_id,
    slot,
    equipped_by,
    equipped_at
  )
  values (
    p_pet_id,
    p_room_id,
    p_item_id,
    p_slot,
    v_user_id,
    now()
  )
  on conflict (room_id, pet_id, slot)
  do update set
    item_id = excluded.item_id,
    equipped_by = excluded.equipped_by,
    equipped_at = excluded.equipped_at;

  return jsonb_build_object(
    'success', true,
    'slot', p_slot,
    'item_sku', v_item_sku
  );
end;
$$;

grant execute on function public.equip_pet_item(uuid, uuid, uuid, text)
  to authenticated;

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
  v_room_timezone text := 'UTC';
  v_expires_at timestamptz := now() + interval '60 minutes';
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select coalesce(nullif(trim(pf.timezone), ''), 'UTC')
  into v_room_timezone
  from public.profiles pf
  where pf.user_id = auth.uid();

  select ptn.name
  into v_room_timezone
  from pg_timezone_names ptn
  where ptn.name = coalesce(v_room_timezone, 'UTC')
  limit 1;

  if v_room_timezone is null then
    v_room_timezone := 'UTC';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (
      select 1
      from public.rooms r
      where r.invite_code = v_code
    )
    and not exists (
      select 1
      from public.room_invite_codes ric
      where ric.code = v_code
    );

    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into public.rooms (
    name,
    invite_code,
    invite_expires_at,
    created_by,
    timezone
  )
  values (
    p_name,
    v_code,
    v_expires_at,
    auth.uid(),
    v_room_timezone
  )
  returning id into v_room_id;

  insert into public.room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  insert into public.room_invite_codes (
    room_id,
    code,
    created_by,
    expires_at
  ) values (
    v_room_id,
    v_code,
    auth.uid(),
    v_expires_at
  );

  insert into public.pets (room_id, name, stage, level, days_alive, scale)
  values (v_room_id, null, 'egg', 1, 0, 1.0)
  returning id into v_pet_id;

  update public.rooms
  set main_pet_id = v_pet_id
  where id = v_room_id;

  insert into public.pet_state (pet_id) values (v_pet_id);
  insert into public.room_pet_state (room_id) values (v_room_id);

  select id into v_background_id
  from public.items
  where sku = 'background_default'
  limit 1;

  if v_background_id is not null then
    insert into public.room_backgrounds (room_id, item_id, acquired_by)
    select
      v_room_id,
      i.id,
      auth.uid()
    from public.items i
    where i.sku = 'background_default'
       or (
         (i.metadata->>'category') = 'background'
         and coalesce(i.metadata->>'shop_visibility', '') = 'hidden'
       )
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

grant execute on function public.create_room(text) to authenticated;

commit;
