-- Add award_quest_reward RPC

create or replace function public.award_quest_reward(
  p_room_id uuid,
  p_daily_quest_id uuid,
  p_amount int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_quest_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    return;
  end if;

  if not exists (
    select 1
    from room_members rm
    where rm.room_id = p_room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  ) then
    raise exception 'not_member';
  end if;

  select quest_id into v_quest_id
  from daily_quests
  where id = p_daily_quest_id
    and room_id = p_room_id
    and status = 'active';

  if v_quest_id is null then
    raise exception 'quest_not_active';
  end if;

  update profiles
  set coins = coins + p_amount
  where user_id = auth.uid();

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    auth.uid(),
    p_room_id,
    'quest',
    p_amount,
    jsonb_build_object(
      'daily_quest_id', p_daily_quest_id,
      'quest_id', v_quest_id
    )
  );

  update daily_quests
  set status = 'claimed'
  where id = p_daily_quest_id;
end;
$$;

grant execute on function public.award_quest_reward(uuid, uuid, int) to authenticated;
