-- Keep feed at 10 minutes, touch at 1 hour, clean/ad_reward at no cooldown.
create or replace function public.claim_action_reward(
  p_action_type text,
  p_room_id uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last timestamptz;
  v_reward int;
  v_pet_id uuid;
  v_pet_level int;
  v_pet_exp int;
  v_exp_gain int := 10;
  v_new_level int;
  v_new_exp int;
  v_exp_required int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_action_type not in ('feed', 'touch', 'clean', 'ad_reward') then
    raise exception 'invalid_action';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  -- Lock the cooldown row to prevent double-grant races.
  insert into action_cooldowns (user_id, action_type, room_id, last_reward_at)
  values (auth.uid(), p_action_type, p_room_id, null)
  on conflict (user_id, action_type, room_id) do nothing;

  select last_reward_at
  into v_last
  from action_cooldowns
  where user_id = auth.uid()
    and action_type = p_action_type
    and room_id = p_room_id
  for update;

  -- Cooldowns by action:
  -- - feed: 10 minutes
  -- - touch: 1 hour
  -- - clean/ad_reward: no cooldown
  if p_action_type = 'feed'
    and v_last is not null
    and v_last > now() - interval '10 minutes' then
    return 0;
  end if;

  if p_action_type = 'touch'
    and v_last is not null
    and v_last > now() - interval '1 hour' then
    return 0;
  end if;

  v_reward := case p_action_type
    when 'feed' then 10
    when 'clean' then 5
    when 'touch' then 1
    when 'ad_reward' then 10
    else 0
  end;

  update action_cooldowns
  set last_reward_at = now()
  where user_id = auth.uid()
    and action_type = p_action_type
    and room_id = p_room_id;

  update profiles
  set coins = coins + v_reward
  where user_id = auth.uid();

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (auth.uid(), p_room_id, p_action_type, v_reward, '{}'::jsonb);

  if p_action_type = 'feed' and v_reward > 0 then
    select id, level, exp
    into v_pet_id, v_pet_level, v_pet_exp
    from pets
    where room_id = p_room_id
    for update;

    if v_pet_id is null then
      raise exception 'pet_not_found';
    end if;

    v_new_level := v_pet_level;
    v_new_exp := v_pet_exp + v_exp_gain;

    while v_new_level < 999 loop
      v_exp_required := 50 * v_new_level;
      exit when v_new_exp < v_exp_required;
      v_new_exp := v_new_exp - v_exp_required;
      v_new_level := v_new_level + 1;
    end loop;

    update pets
    set level = v_new_level,
        exp = v_new_exp
    where id = v_pet_id;
  end if;

  return v_reward;
end;
$$;

grant execute on function public.claim_action_reward(text, uuid) to authenticated;
