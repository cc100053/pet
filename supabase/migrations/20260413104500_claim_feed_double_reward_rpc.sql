create index if not exists coin_ledger_feed_double_reward_claim_idx
on public.coin_ledger (
  user_id,
  room_id,
  ((metadata->>'feed_message_id'))
)
where source = 'ad_reward'
  and metadata->>'kind' = 'feed_double_reward';

create or replace function public.claim_feed_double_reward(
  p_room_id uuid,
  p_message_id uuid
)
returns table (
  extra_reward int,
  total_reward int,
  already_claimed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_reward int;
  v_extra_reward int;
  v_total_reward int;
  v_already_claimed boolean;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_room_id is null then
    raise exception 'room_id_required';
  end if;

  if p_message_id is null then
    raise exception 'message_id_required';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select m.coins_awarded
  into v_current_reward
  from public.messages m
  where m.id = p_message_id
    and m.room_id = p_room_id
    and m.sender_id = v_user_id
    and m.type = 'image_feed'
  for update;

  if not found then
    raise exception 'feed_message_not_found';
  end if;

  if coalesce(v_current_reward, 0) <= 0 then
    raise exception 'feed_reward_required';
  end if;

  select exists (
    select 1
    from public.coin_ledger cl
    where cl.user_id = v_user_id
      and cl.room_id = p_room_id
      and cl.source = 'ad_reward'
      and cl.metadata->>'kind' = 'feed_double_reward'
      and cl.metadata->>'feed_message_id' = p_message_id::text
  )
  into v_already_claimed;

  if v_already_claimed then
    extra_reward := 0;
    total_reward := v_current_reward;
    already_claimed := true;
    return next;
    return;
  end if;

  v_extra_reward := v_current_reward;
  v_total_reward := v_current_reward + v_extra_reward;

  update public.profiles
  set coins = coins + v_extra_reward
  where user_id = v_user_id;

  if not found then
    raise exception 'profile_not_found';
  end if;

  insert into public.coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    v_user_id,
    p_room_id,
    'ad_reward',
    v_extra_reward,
    jsonb_build_object(
      'kind', 'feed_double_reward',
      'feed_message_id', p_message_id,
      'base_reward', v_current_reward,
      'total_reward', v_total_reward
    )
  );

  update public.messages
  set coins_awarded = v_total_reward
  where id = p_message_id
    and room_id = p_room_id
    and sender_id = v_user_id
    and type = 'image_feed';

  extra_reward := v_extra_reward;
  total_reward := v_total_reward;
  already_claimed := false;
  return next;
end;
$$;

revoke all on function public.claim_feed_double_reward(uuid, uuid) from public;
grant execute on function public.claim_feed_double_reward(uuid, uuid) to authenticated;
