begin;

update public.items
set metadata = jsonb_set(
  coalesce(metadata, '{}'::jsonb),
  '{shop_visibility}',
  '"hidden"'::jsonb,
  true
)
where sku in ('background_sage_frame', 'background_lilac_frame');

update public.items
set
  price_coins = 250,
  price_diamonds = null,
  metadata = (jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{price_jpy}',
    '250'::jsonb,
    true
  ) - 'shop_visibility')
where sku = 'background_bubble_sky';

update public.items
set
  price_coins = 220,
  price_diamonds = null,
  metadata = (jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{price_jpy}',
    '220'::jsonb,
    true
  ) - 'shop_visibility')
where sku = 'background_starlit_dream';

insert into public.room_backgrounds (room_id, item_id, acquired_by)
select
  r.id,
  i.id,
  r.created_by
from public.rooms r
join public.items i
  on (i.metadata->>'category') = 'background'
 and coalesce(i.metadata->>'shop_visibility', '') = 'hidden'
left join public.room_backgrounds rb
  on rb.room_id = r.id
 and rb.item_id = i.id
where rb.room_id is null;

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

  insert into public.pet_state (pet_id) values (v_pet_id);

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
