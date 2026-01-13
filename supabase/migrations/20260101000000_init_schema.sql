-- Initial schema for PicPet

create extension if not exists "pgcrypto";

-- Utility: keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text,
  avatar_url text,
  locale text default 'zh-TW',
  timezone text default 'Asia/Taipei',
  coins int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists rooms (
  id uuid primary key default gen_random_uuid(),
  name text,
  invite_code text not null unique,
  invite_expires_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_archived boolean not null default false,
  constraint invite_code_format check (invite_code ~ '^[0-9]{6}$')
);

create table if not exists room_members (
  room_id uuid not null references rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  is_active boolean not null default true,
  primary key (room_id, user_id),
  constraint room_members_role check (role in ('owner', 'member'))
);

create table if not exists pets (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null unique references rooms(id) on delete cascade,
  name text,
  color_dna jsonb not null default '{}'::jsonb,
  stage text not null default 'egg',
  level int not null default 1,
  days_alive int not null default 0,
  scale numeric not null default 1.0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pets_stage check (stage in ('egg', 'hatched')),
  constraint pets_scale check (scale > 0)
);

create table if not exists pet_state (
  pet_id uuid primary key references pets(id) on delete cascade,
  hunger int not null default 100,
  mood text not null default 'mid',
  hygiene int not null default 100,
  poop_at timestamptz,
  last_decay_at timestamptz not null default now(),
  last_feed_at timestamptz,
  last_touch_at timestamptz,
  last_clean_at timestamptz,
  constraint pet_state_hunger check (hunger between 0 and 100),
  constraint pet_state_hygiene check (hygiene between 0 and 100),
  constraint pet_state_mood check (mood in ('low', 'mid', 'high', 'sad'))
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references rooms(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  type text not null,
  body text,
  image_url text,
  caption text,
  labels jsonb not null default '[]'::jsonb,
  coins_awarded int not null default 0,
  mood_delta int not null default 0,
  created_at timestamptz not null default now(),
  client_created_at timestamptz,
  constraint messages_type check (type in ('text', 'image_feed', 'system'))
);

create table if not exists label_mappings (
  id uuid primary key default gen_random_uuid(),
  label_en text not null,
  canonical_tag text not null,
  locale text not null,
  label_local text not null,
  synonyms text[] not null default '{}'::text[],
  priority int not null default 0,
  constraint label_mappings_unique unique (label_en, canonical_tag, locale)
);

create table if not exists quests (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  name text,
  name_zh text,
  name_ja text,
  canonical_tags text[] not null default '{}'::text[],
  reward_coins int not null default 0,
  is_active boolean not null default true
);

create table if not exists daily_quests (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references rooms(id) on delete cascade,
  quest_id uuid not null references quests(id) on delete cascade,
  quest_date date not null,
  status text not null default 'active',
  reward_multiplier numeric not null default 1.0,
  constraint daily_quests_status check (status in ('active', 'claimed', 'expired')),
  constraint daily_quests_unique unique (room_id, quest_date)
);

create table if not exists action_cooldowns (
  user_id uuid not null references auth.users(id) on delete cascade,
  action_type text not null,
  last_reward_at timestamptz,
  primary key (user_id, action_type),
  constraint action_cooldowns_type check (action_type in ('feed', 'touch', 'clean', 'ad_reward'))
);

create table if not exists coin_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  room_id uuid references rooms(id) on delete set null,
  source text not null,
  amount int not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint coin_ledger_source check (source in ('feed', 'touch', 'clean', 'ad_reward', 'quest'))
);

create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  type text not null,
  name text not null,
  price_coins int,
  price_usd numeric,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  constraint items_type check (type in ('cosmetic', 'consumable'))
);

create table if not exists inventories (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references items(id) on delete cascade,
  quantity int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

create table if not exists purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid references items(id) on delete set null,
  platform text,
  receipt text,
  created_at timestamptz not null default now()
);

create table if not exists subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text,
  provider text,
  started_at timestamptz,
  expires_at timestamptz
);

create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references messages(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id)
);

create table if not exists app_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- updated_at triggers
create trigger set_profiles_updated_at
before update on profiles
for each row execute function public.set_updated_at();

create trigger set_rooms_updated_at
before update on rooms
for each row execute function public.set_updated_at();

create trigger set_pets_updated_at
before update on pets
for each row execute function public.set_updated_at();

create trigger set_inventories_updated_at
before update on inventories
for each row execute function public.set_updated_at();

create trigger set_app_config_updated_at
before update on app_config
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists messages_room_created_at_idx on messages (room_id, created_at desc);
create index if not exists room_members_user_room_idx on room_members (user_id, room_id);
create index if not exists rooms_invite_code_idx on rooms (invite_code);
create index if not exists pets_room_id_idx on pets (room_id);
create index if not exists daily_quests_room_date_idx on daily_quests (room_id, quest_date);
create index if not exists coin_ledger_user_created_at_idx on coin_ledger (user_id, created_at desc);
create unique index if not exists room_members_active_owner_unique
  on room_members (room_id) where role = 'owner' and is_active;

-- RLS
alter table profiles enable row level security;
alter table rooms enable row level security;
alter table room_members enable row level security;
alter table pets enable row level security;
alter table pet_state enable row level security;
alter table messages enable row level security;
alter table label_mappings enable row level security;
alter table quests enable row level security;
alter table daily_quests enable row level security;
alter table action_cooldowns enable row level security;
alter table coin_ledger enable row level security;
alter table items enable row level security;
alter table inventories enable row level security;
alter table purchases enable row level security;
alter table subscriptions enable row level security;
alter table reports enable row level security;
alter table blocks enable row level security;
alter table app_config enable row level security;

-- profiles
create policy profiles_select on profiles
for select using (
  user_id = auth.uid() or
  exists (
    select 1
    from room_members rm1
    join room_members rm2 on rm1.room_id = rm2.room_id
    where rm1.user_id = auth.uid()
      and rm2.user_id = profiles.user_id
      and rm1.is_active
      and rm2.is_active
  )
);

create policy profiles_insert on profiles
for insert with check (user_id = auth.uid());

create policy profiles_update on profiles
for update using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy profiles_delete on profiles
for delete using (user_id = auth.uid());

-- rooms
create policy rooms_select on rooms
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = rooms.id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy rooms_insert on rooms
for insert with check (created_by = auth.uid());

create policy rooms_update on rooms
for update using (
  exists (
    select 1 from room_members rm
    where rm.room_id = rooms.id
      and rm.user_id = auth.uid()
      and rm.role = 'owner'
      and rm.is_active
  )
)
with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = rooms.id
      and rm.user_id = auth.uid()
      and rm.role = 'owner'
      and rm.is_active
  )
);

create policy rooms_delete on rooms
for delete using (
  exists (
    select 1 from room_members rm
    where rm.room_id = rooms.id
      and rm.user_id = auth.uid()
      and rm.role = 'owner'
      and rm.is_active
  )
);

-- room_members
create policy room_members_select on room_members
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = room_members.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy room_members_update on room_members
for update using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy room_members_delete on room_members
for delete using (user_id = auth.uid());

-- pets
create policy pets_select on pets
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = pets.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy pets_insert on pets
for insert with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = pets.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy pets_update on pets
for update using (
  exists (
    select 1 from room_members rm
    where rm.room_id = pets.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
)
with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = pets.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy pets_delete on pets
for delete using (
  exists (
    select 1 from room_members rm
    where rm.room_id = pets.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

-- pet_state
create policy pet_state_select on pet_state
for select using (
  exists (
    select 1
    from pets p
    join room_members rm on rm.room_id = p.room_id
    where p.id = pet_state.pet_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy pet_state_insert on pet_state
for insert with check (
  exists (
    select 1
    from pets p
    join room_members rm on rm.room_id = p.room_id
    where p.id = pet_state.pet_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy pet_state_update on pet_state
for update using (
  exists (
    select 1
    from pets p
    join room_members rm on rm.room_id = p.room_id
    where p.id = pet_state.pet_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
)
with check (
  exists (
    select 1
    from pets p
    join room_members rm on rm.room_id = p.room_id
    where p.id = pet_state.pet_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

-- messages
create policy messages_select on messages
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = messages.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy messages_insert on messages
for insert with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = messages.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
  and (sender_id = auth.uid() or sender_id is null)
);

-- label_mappings + quests
create policy label_mappings_read on label_mappings
for select using (auth.role() = 'authenticated');

create policy quests_read on quests
for select using (auth.role() = 'authenticated');

-- daily_quests
create policy daily_quests_select on daily_quests
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = daily_quests.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy daily_quests_insert on daily_quests
for insert with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = daily_quests.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

create policy daily_quests_update on daily_quests
for update using (
  exists (
    select 1 from room_members rm
    where rm.room_id = daily_quests.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
)
with check (
  exists (
    select 1 from room_members rm
    where rm.room_id = daily_quests.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
);

-- action_cooldowns
create policy action_cooldowns_rw on action_cooldowns
for all using (user_id = auth.uid())
with check (user_id = auth.uid());

-- coin_ledger
create policy coin_ledger_select on coin_ledger
for select using (user_id = auth.uid());

create policy coin_ledger_insert on coin_ledger
for insert with check (user_id = auth.uid());

-- items
create policy items_read on items
for select using (auth.role() = 'authenticated');

-- inventories
create policy inventories_rw on inventories
for all using (user_id = auth.uid())
with check (user_id = auth.uid());

-- purchases
create policy purchases_rw on purchases
for all using (user_id = auth.uid())
with check (user_id = auth.uid());

-- subscriptions
create policy subscriptions_rw on subscriptions
for all using (user_id = auth.uid())
with check (user_id = auth.uid());

-- reports
create policy reports_select on reports
for select using (reporter_id = auth.uid());

create policy reports_insert on reports
for insert with check (reporter_id = auth.uid());

-- blocks
create policy blocks_rw on blocks
for all using (blocker_id = auth.uid())
with check (blocker_id = auth.uid());

-- app_config
create policy app_config_read on app_config
for select using (auth.role() = 'authenticated');

-- Ownership: ensure one active owner per room (transfer on leave/delete)
create or replace function public.ensure_room_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_owner uuid;
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

      update rooms
      set created_by = v_owner
      where id = v_room_id;
    end if;
  end if;

  return null;
end;
$$;

create trigger room_members_ensure_owner_after_change
after insert or update or delete on room_members
for each row execute function public.ensure_room_owner();

-- RPC: create room with owner membership + invite code
create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_room_id uuid;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from rooms where invite_code = v_code);
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into rooms (name, invite_code, invite_expires_at, created_by)
  values (p_name, v_code, now() + interval '60 minutes', auth.uid())
  returning id into v_room_id;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  return query select v_room_id, v_code;
end;
$$;

-- RPC: join room by invite code
create or replace function public.join_room_by_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select id into v_room_id
  from rooms
  where invite_code = code
    and (invite_expires_at is null or invite_expires_at > now())
    and is_archived = false
  limit 1;

  if v_room_id is null then
    raise exception 'invalid_invite';
  end if;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'member', now(), true)
  on conflict (room_id, user_id)
  do update set is_active = true, left_at = null, joined_at = now();

  return v_room_id;
end;
$$;

-- RPC: apply pet actions (minimal server-side enforcement)
create or replace function public.apply_pet_action(p_pet_id uuid, p_action_type text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id into v_room_id from pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not exists (
    select 1 from room_members rm
    where rm.room_id = v_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  ) then
    raise exception 'not_authorized';
  end if;

  if p_action_type = 'feed' then
    update pet_state
    set hunger = least(100, hunger + 10),
        last_feed_at = now()
    where pet_id = p_pet_id;
  elsif p_action_type = 'clean' then
    update pet_state
    set hygiene = least(100, hygiene + 10),
        poop_at = null,
        last_clean_at = now()
    where pet_id = p_pet_id;
  elsif p_action_type = 'touch' then
    update pet_state
    set last_touch_at = now()
    where pet_id = p_pet_id;
  else
    raise exception 'invalid_action';
  end if;
end;
$$;

-- RPC: claim action reward (1-hour cooldown)
create or replace function public.claim_action_reward(p_action_type text, p_room_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last timestamptz;
  v_reward int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_action_type not in ('feed', 'touch', 'clean', 'ad_reward') then
    raise exception 'invalid_action';
  end if;

  select last_reward_at into v_last
  from action_cooldowns
  where user_id = auth.uid() and action_type = p_action_type;

  if v_last is not null and v_last > now() - interval '1 hour' then
    return 0;
  end if;

  v_reward := case p_action_type
    when 'feed' then 10
    when 'clean' then 5
    when 'touch' then 1
    when 'ad_reward' then 10
    else 0
  end;

  insert into action_cooldowns (user_id, action_type, last_reward_at)
  values (auth.uid(), p_action_type, now())
  on conflict (user_id, action_type)
  do update set last_reward_at = now();

  update profiles
  set coins = coins + v_reward
  where user_id = auth.uid();

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (auth.uid(), p_room_id, p_action_type, v_reward, '{}'::jsonb);

  return v_reward;
end;
$$;

-- RPC: tick pet state (minimal hunger decay + night mode)
create or replace function public.tick_pet_state(p_pet_id uuid, p_now timestamptz)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last timestamptz;
  v_hours numeric;
  v_decay int;
  v_timezone text;
  v_local_hour int;
  v_rate numeric := 1.0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select ps.last_decay_at, coalesce(pf.timezone, 'UTC')
  into v_last, v_timezone
  from pet_state ps
  join pets p on p.id = ps.pet_id
  join room_members rm on rm.room_id = p.room_id
  join profiles pf on pf.user_id = rm.user_id
  where ps.pet_id = p_pet_id
    and rm.user_id = auth.uid()
    and rm.is_active;

  if v_last is null then
    update pet_state set last_decay_at = p_now where pet_id = p_pet_id;
    return;
  end if;

  v_hours := extract(epoch from (p_now - v_last)) / 3600.0;
  if v_hours <= 0 then
    return;
  end if;

  v_local_hour := extract(hour from (p_now at time zone v_timezone));
  if v_local_hour between 0 and 7 then
    v_rate := 0.5;
  end if;

  v_decay := floor(v_hours * 5 * v_rate);

  if v_decay > 0 then
    update pet_state
    set hunger = greatest(0, hunger - v_decay),
        last_decay_at = p_now
    where pet_id = p_pet_id;
  else
    update pet_state set last_decay_at = p_now where pet_id = p_pet_id;
  end if;
end;
$$;

grant execute on function public.join_room_by_code(text) to authenticated;
grant execute on function public.create_room(text) to authenticated;
grant execute on function public.apply_pet_action(uuid, text) to authenticated;
grant execute on function public.claim_action_reward(text, uuid) to authenticated;
grant execute on function public.tick_pet_state(uuid, timestamptz) to authenticated;
