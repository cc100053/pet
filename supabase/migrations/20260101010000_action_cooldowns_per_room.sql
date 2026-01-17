-- Scope action cooldowns per room instead of global per user.
alter table action_cooldowns
  add column if not exists room_id uuid references rooms(id) on delete cascade;

-- Clear existing cooldowns to avoid global carry-over.
delete from action_cooldowns;

alter table action_cooldowns
  alter column room_id set not null;

alter table action_cooldowns
  drop constraint if exists action_cooldowns_pkey;

alter table action_cooldowns
  add primary key (user_id, action_type, room_id);

-- RPC: claim action reward (1-hour cooldown per room)
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
  where user_id = auth.uid()
    and action_type = p_action_type
    and room_id = p_room_id;

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

  insert into action_cooldowns (user_id, action_type, room_id, last_reward_at)
  values (auth.uid(), p_action_type, p_room_id, now())
  on conflict (user_id, action_type, room_id)
  do update set last_reward_at = now();

  update profiles
  set coins = coins + v_reward
  where user_id = auth.uid();

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (auth.uid(), p_room_id, p_action_type, v_reward, '{}'::jsonb);

  return v_reward;
end;
$$;

grant execute on function public.claim_action_reward(text, uuid) to authenticated;
