-- Run via Supabase MCP execute_sql as postgres. Every probe is rolled back.
-- Uses existing rooms/levels; never changes pet state or membership.
begin;
do $$
declare
  v_room uuid;
  v_member uuid;
  v_partner uuid;
  v_style text;
  v_level integer;
  v_allowed boolean;
  v_before timestamptz;
  v_after timestamptz;
begin
  if has_table_privilege('anon', 'public.room_frame_state', 'select')
    or has_table_privilege('authenticated', 'public.room_frame_state', 'delete')
    or has_column_privilege('authenticated', 'public.room_frame_state', 'updated_at', 'update') then
    raise exception 'unexpected frame privileges';
  end if;
  for v_style, v_level, v_allowed in
    select * from (values
      ('original', 1, true), ('polaroid_classic', 1, true),
      ('corkboard', 2, false), ('corkboard', 3, true),
      ('gold_leaf', 4, false), ('gold_leaf', 5, true),
      ('night_glow', 7, false), ('night_glow', 8, true)
    ) as boundaries(style, level, allowed)
  loop
    select ps.room_id, rm.user_id into v_room, v_member
      from public.room_pet_state ps join public.room_members rm on rm.room_id=ps.room_id
      where ps.level=v_level and rm.is_active limit 1;
    if v_room is null then raise exception 'missing room fixture at level %', v_level; end if;
    delete from public.room_frame_state where room_id=v_room;
    perform set_config('request.jwt.claim.sub', v_member::text, true);
    execute 'set local role authenticated';
    begin
      insert into public.room_frame_state(room_id,style) values(v_room,v_style)
        on conflict(room_id) do update set style=excluded.style;
      if not v_allowed then raise exception 'locked frame accepted: % at %', v_style,v_level; end if;
    exception when insufficient_privilege then
      if v_allowed then raise; end if;
    end;
    execute 'reset role';
  end loop;

  select ps.room_id, rm.user_id into v_room, v_member
    from public.room_pet_state ps join public.room_members rm on rm.room_id=ps.room_id
    where ps.level=1 and rm.is_active
      and (select count(*) from public.room_members x where x.room_id=ps.room_id and x.is_active)>1 limit 1;
  if v_room is null then raise exception 'missing shared room fixture'; end if;
  select user_id into v_partner from public.room_members
    where room_id=v_room and is_active and user_id<>v_member limit 1;
  delete from public.room_frame_state where room_id=v_room;
  -- Simulate a previously equipped casing surviving a future ladder change.
  alter table public.room_frame_state disable trigger validate_room_frame_state;
  insert into public.room_frame_state(room_id,style) values(v_room,'night_glow');
  alter table public.room_frame_state enable trigger validate_room_frame_state;
  perform set_config('request.jwt.claim.sub',v_member::text,true);
  execute 'set local role authenticated';
  insert into public.room_frame_state(room_id,style) values(v_room,'night_glow')
    on conflict(room_id) do update set room_id=excluded.room_id,style=excluded.style;
  select updated_at into v_before from public.room_frame_state where room_id=v_room;
  perform set_config('request.jwt.claim.sub',v_partner::text,true);
  if (select style from public.room_frame_state where room_id=v_room) is distinct from 'night_glow' then
    raise exception 'partner cannot read shared frame';
  end if;
  insert into public.room_frame_state(room_id,style) values(v_room,'original')
    on conflict(room_id) do update set room_id=excluded.room_id,style=excluded.style;
  select updated_at into v_after from public.room_frame_state where room_id=v_room;
  if v_after <= v_before then raise exception 'server timestamp did not advance'; end if;
  begin
    insert into public.room_frame_state(room_id,style) values(v_room,'future_frame')
      on conflict(room_id) do update set style=excluded.style;
    raise exception 'unknown frame accepted';
  exception when check_violation then null;
  end;
  perform set_config('request.jwt.claim.sub',v_member::text,true);
  if (select style from public.room_frame_state where room_id=v_room) is distinct from 'original' then
    raise exception 'member cannot see partner change';
  end if;
  perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
  if exists(select 1 from public.room_frame_state where room_id=v_room) then
    raise exception 'nonmember can read frame';
  end if;
  begin
    insert into public.room_frame_state(room_id,style) values(v_room,'original')
      on conflict(room_id) do update set style=excluded.style;
    raise exception 'nonmember can write frame';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claim.sub','',true);
  if exists(select 1 from public.room_frame_state where room_id=v_room) then
    raise exception 'missing session can read frame';
  end if;
  execute 'reset role';
end;
$$;
rollback;
