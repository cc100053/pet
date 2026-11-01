-- Manual furniture layering. Additive: old clients never read z_order and keep
-- their previous (unordered) draw order; new clients order by z_order.
begin;

alter table public.room_furniture
  add column if not exists z_order double precision;

-- Existing rooms keep placement order (oldest at the back).
update public.room_furniture f
set z_order = ranked.rn
from (
  select id, row_number() over (
    partition by room_id order by created_at, id
  ) as rn
  from public.room_furniture
) ranked
where f.id = ranked.id
  and f.z_order is null;

-- New pieces (from any client version) land on top of the room's stack.
create or replace function public.room_furniture_default_z_order()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.z_order is null then
    select coalesce(max(z_order), 0) + 1
    into new.z_order
    from public.room_furniture
    where room_id = new.room_id;
  end if;
  return new;
end;
$$;

drop trigger if exists room_furniture_default_z_order on public.room_furniture;
create trigger room_furniture_default_z_order
before insert on public.room_furniture
for each row execute function public.room_furniture_default_z_order();

create or replace function public.set_room_furniture_layer(
  p_id uuid,
  p_z_order double precision
)
returns public.room_furniture
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_row public.room_furniture%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_id is null
    or p_z_order is null
    or p_z_order = 'NaN'::double precision
    or p_z_order in ('Infinity'::double precision, '-Infinity'::double precision)
  then
    raise exception 'invalid_z_order';
  end if;

  -- RLS (room_furniture_update: active room member) scopes the update.
  update public.room_furniture
  set z_order = p_z_order
  where id = p_id
  returning * into v_row;

  if v_row.id is null then
    raise exception 'not_found';
  end if;

  return v_row;
end;
$$;

-- Floor pieces (rugs) sort behind standing furniture when auto-layered.
update public.items
set metadata = metadata || '{"layer": "floor"}'::jsonb
where sku = 'furniture_carpet'
  and coalesce(metadata->>'layer', '') <> 'floor';

revoke all on function public.set_room_furniture_layer(uuid, double precision)
  from public, anon;
grant execute on function public.set_room_furniture_layer(uuid, double precision)
  to authenticated;

commit;
