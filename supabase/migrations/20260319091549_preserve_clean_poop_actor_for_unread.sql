create or replace function public.clean_poop(
  p_pet_id uuid,
  p_poop_index int default null
)
returns table (poop_count int, coins_awarded int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_positions jsonb;
  v_new_positions jsonb;
  v_poop_count int;
  v_poop_at timestamptz;
  v_nickname text;
  v_reward int := 0;
  v_index int;
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

  select ps.poop_positions, ps.poop_count, ps.poop_at
  into v_positions, v_poop_count, v_poop_at
  from pet_state ps
  where ps.pet_id = p_pet_id
  for update;

  v_positions := coalesce(v_positions, '[]'::jsonb);
  v_poop_count := coalesce(v_poop_count, 0);

  if v_poop_count <= 0 then
    return query select 0, 0;
  end if;

  perform public.apply_pet_action(p_pet_id, 'clean');

  if p_poop_index is null or p_poop_index < 0 or p_poop_index >= v_poop_count then
    v_index := 0;
  else
    v_index := p_poop_index;
  end if;

  select coalesce(jsonb_agg(value order by idx), '[]'::jsonb)
  into v_new_positions
  from (
    select value, idx
    from jsonb_array_elements(v_positions) with ordinality as t(value, idx)
    where idx <> v_index + 1
    order by idx
  ) s;

  v_poop_count := greatest(0, v_poop_count - 1);
  if v_poop_count = 0 then
    v_poop_at := null;
  end if;

  update pet_state
  set poop_positions = v_new_positions,
      poop_count = v_poop_count,
      poop_at = v_poop_at,
      last_poop_spawn_at = now()
  where pet_id = p_pet_id;

  v_reward := public.claim_action_reward('clean', v_room_id);

  select nickname into v_nickname from profiles where user_id = auth.uid();

  insert into messages (room_id, sender_id, type, body, coins_awarded)
  values (
    v_room_id,
    auth.uid(),
    'system',
    coalesce(v_nickname, 'Someone') || ' cleaned the poop: +'
      || v_reward::text || ' Coins.',
    v_reward
  );

  return query select v_poop_count, v_reward;
end;
$$;
