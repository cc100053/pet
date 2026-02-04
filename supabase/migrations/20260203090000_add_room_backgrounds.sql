begin;

insert into public.items (sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active)
values
  (
    'background_default',
    'cosmetic',
    'Default Background',
    0,
    0,
    null,
    '{"price_jpy":0,"currency":"JPY","category":"background","background_key":"default","description":"Original cozy room backdrop."}'::jsonb,
    true
  ),
  (
    'background_test',
    'cosmetic',
    'Test Background',
    120,
    120,
    null,
    '{"price_jpy":120,"currency":"JPY","category":"background","background_key":"test","description":"Example background for testing."}'::jsonb,
    true
  )
on conflict (sku) do update
set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_diamonds = excluded.price_diamonds,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

create table if not exists public.room_backgrounds (
  room_id uuid not null references public.rooms(id) on delete cascade,
  item_id uuid not null references public.items(id),
  acquired_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (room_id, item_id)
);

create index if not exists room_backgrounds_room_id_idx
  on public.room_backgrounds(room_id);

alter table public.room_backgrounds enable row level security;

drop policy if exists room_backgrounds_select on public.room_backgrounds;
create policy room_backgrounds_select on public.room_backgrounds
for select using (public.is_room_member(room_id));

drop policy if exists room_backgrounds_insert on public.room_backgrounds;
create policy room_backgrounds_insert on public.room_backgrounds
for insert with check (
  public.is_room_member(room_id)
  and acquired_by = auth.uid()
  and exists (
    select 1 from public.items
    where items.id = room_backgrounds.item_id
      and items.is_active
      and (items.metadata->>'category') = 'background'
  )
);

create table if not exists public.room_background_state (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  active_item_id uuid not null references public.items(id),
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_room_background_state_updated_at
  on public.room_background_state;
create trigger set_room_background_state_updated_at
before update on public.room_background_state
for each row execute function public.set_updated_at();

alter table public.room_background_state enable row level security;

drop policy if exists room_background_state_select on public.room_background_state;
create policy room_background_state_select on public.room_background_state
for select using (public.is_room_member(room_id));

drop policy if exists room_background_state_insert on public.room_background_state;
create policy room_background_state_insert on public.room_background_state
for insert with check (
  public.is_room_member(room_id)
  and exists (
    select 1 from public.room_backgrounds rb
    where rb.room_id = room_background_state.room_id
      and rb.item_id = room_background_state.active_item_id
  )
);

drop policy if exists room_background_state_update on public.room_background_state;
create policy room_background_state_update on public.room_background_state
for update using (public.is_room_member(room_id))
with check (
  public.is_room_member(room_id)
  and exists (
    select 1 from public.room_backgrounds rb
    where rb.room_id = room_background_state.room_id
      and rb.item_id = room_background_state.active_item_id
  )
);

alter table public.room_backgrounds replica identity full;
alter table public.room_background_state replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.room_backgrounds;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.room_background_state;
exception
  when duplicate_object then null;
end $$;

create or replace function public.set_room_background(
  p_room_id uuid,
  p_item_id uuid
)
returns public.room_background_state
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.room_background_state%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if not exists (
    select 1 from public.room_backgrounds
    where room_id = p_room_id
      and item_id = p_item_id
  ) then
    raise exception 'background_not_owned';
  end if;

  update public.room_background_state
  set active_item_id = p_item_id,
      updated_by = auth.uid(),
      updated_at = now()
  where room_id = p_room_id
  returning * into v_row;

  if not found then
    insert into public.room_background_state (
      room_id,
      active_item_id,
      updated_by
    ) values (
      p_room_id,
      p_item_id,
      auth.uid()
    )
    returning * into v_row;
  end if;

  return v_row;
end $$;

grant execute on function public.set_room_background(uuid, uuid) to authenticated;

create or replace function public.grant_iap_room_background(
  p_room_id uuid,
  p_item_id uuid,
  p_product_id text,
  p_transaction_id text
)
returns table (room_id uuid, item_id uuid, already_owned boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owned boolean := false;
  v_metadata jsonb;
  v_product_id text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_room_id is null then
    raise exception 'invalid_room';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  if p_transaction_id is null or length(p_transaction_id) = 0 then
    raise exception 'invalid_transaction';
  end if;

  select metadata, (metadata->>'iap_product_id')
  into v_metadata, v_product_id
  from public.items
  where id = p_item_id
    and is_active;

  if v_metadata is null then
    raise exception 'item_not_found';
  end if;

  if (v_metadata->>'category') is distinct from 'background' then
    raise exception 'item_not_background';
  end if;

  if v_product_id is null or v_product_id <> p_product_id then
    raise exception 'product_mismatch';
  end if;

  begin
    insert into public.iap_transactions (user_id, product_id, transaction_id)
    values (auth.uid(), p_product_id, p_transaction_id);
  exception when unique_violation then
    select exists(
      select 1 from public.room_backgrounds rb
      where rb.room_id = p_room_id
        and rb.item_id = p_item_id
    ) into v_owned;
    return query select p_room_id, p_item_id, v_owned;
  end;

  insert into public.room_backgrounds (room_id, item_id, acquired_by)
  values (p_room_id, p_item_id, auth.uid())
  on conflict (room_id, item_id) do nothing;

  select exists(
    select 1 from public.room_backgrounds rb
    where rb.room_id = p_room_id
      and rb.item_id = p_item_id
  ) into v_owned;

  return query select p_room_id, p_item_id, v_owned;
end $$;

grant execute on function public.grant_iap_room_background(uuid, uuid, text, text) to authenticated;

create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
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
      select 1 from rooms r where r.invite_code = v_code
    );
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into rooms (name, invite_code, invite_expires_at, created_by)
  values (p_name, v_code, now() + interval '60 minutes', auth.uid())
  returning id into v_room_id;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  insert into pets (room_id, name, stage, level, days_alive, scale)
  values (v_room_id, null, 'egg', 1, 0, 1.0)
  returning id into v_pet_id;

  insert into pet_state (pet_id) values (v_pet_id);

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

  return query select v_room_id, v_code;
end;
$$;

with default_bg as (
  select id from public.items where sku = 'background_default' limit 1
)
insert into public.room_backgrounds (room_id, item_id, acquired_by)
select r.id, default_bg.id, r.created_by
from public.rooms r
cross join default_bg
left join public.room_backgrounds rb
  on rb.room_id = r.id and rb.item_id = default_bg.id
where rb.room_id is null;

with default_bg as (
  select id from public.items where sku = 'background_default' limit 1
)
insert into public.room_background_state (room_id, active_item_id, updated_by)
select r.id, default_bg.id, r.created_by
from public.rooms r
cross join default_bg
left join public.room_background_state rs
  on rs.room_id = r.id
where rs.room_id is null;

commit;
