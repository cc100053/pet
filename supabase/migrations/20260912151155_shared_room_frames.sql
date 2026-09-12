-- Additive: old clients keep their local room_frame_styles and existing RPCs.
create table public.room_frame_state (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  style text not null check (style in ('original', 'polaroid_classic', 'corkboard', 'gold_leaf', 'night_glow')),
  updated_at timestamptz not null default now()
);

alter table public.room_frame_state enable row level security;
revoke all on public.room_frame_state from public, anon, authenticated;
grant select on public.room_frame_state to authenticated;
grant insert (room_id, style), update (room_id, style) on public.room_frame_state to authenticated;
grant all on public.room_frame_state to service_role;

create policy room_frame_state_select on public.room_frame_state
for select to authenticated using (
  exists (select 1 from public.room_members rm
    where rm.room_id = room_frame_state.room_id
      and rm.user_id = (select auth.uid()) and rm.is_active)
);
create policy room_frame_state_insert on public.room_frame_state
for insert to authenticated with check (
  exists (select 1 from public.room_members rm
    where rm.room_id = room_frame_state.room_id
      and rm.user_id = (select auth.uid()) and rm.is_active)
);
create policy room_frame_state_update on public.room_frame_state
for update to authenticated using (
  exists (select 1 from public.room_members rm
    where rm.room_id = room_frame_state.room_id
      and rm.user_id = (select auth.uid()) and rm.is_active)
) with check (
  exists (select 1 from public.room_members rm
    where rm.room_id = room_frame_state.room_id
      and rm.user_id = (select auth.uid()) and rm.is_active)
);

create function public.validate_room_frame_state() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare
  v_required_level integer;
  v_room_level integer;
  v_equipped_style text;
begin
  if tg_op = 'UPDATE' and new.room_id <> old.room_id then
    raise exception 'room_frame_room_id_immutable' using errcode = '22023';
  end if;
  -- Match the picker: an already equipped shared casing is grandfathered.
  if tg_op = 'UPDATE' then
    v_equipped_style := old.style;
  else
    -- INSERT triggers also run on PostgREST upserts before conflict handling.
    select style into v_equipped_style from public.room_frame_state where room_id = new.room_id;
  end if;
  if new.style is distinct from v_equipped_style then
    v_required_level := case new.style
      when 'corkboard' then 3 when 'gold_leaf' then 5 when 'night_glow' then 8
      else 1 end;
    select coalesce((select level from public.room_pet_state where room_id = new.room_id), 1)
      into v_room_level;
    if v_room_level < v_required_level then
      raise exception 'room_frame_level_required' using errcode = '42501';
    end if;
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
revoke all on function public.validate_room_frame_state() from public, anon, authenticated;

create trigger validate_room_frame_state before insert or update on public.room_frame_state
for each row execute function public.validate_room_frame_state();

alter publication supabase_realtime add table public.room_frame_state;
