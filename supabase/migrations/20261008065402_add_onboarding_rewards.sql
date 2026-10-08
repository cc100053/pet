-- One-time onboarding checklist rewards (onboarding redesign, phase 1).
-- Additive: new ledger source + new RPC; no existing contract changes.

alter table public.coin_ledger
  drop constraint if exists coin_ledger_source;

alter table public.coin_ledger
  add constraint coin_ledger_source check (
    source in (
      'feed',
      'touch',
      'clean',
      'ad_reward',
      'quest',
      'store_purchase',
      'iap_purchase',
      'diamond_exchange',
      'onboarding'
    )
  );

-- One grant per task per account, across rooms and reinstalls.
create unique index if not exists coin_ledger_onboarding_task_uniq
  on public.coin_ledger (user_id, (metadata ->> 'task'))
  where source = 'onboarding';

-- Returns coins granted: 0 when already claimed or not yet eligible.
-- SECURITY DEFINER because it writes profiles.coins and coin_ledger, which
-- clients cannot write directly (same pattern as award_quest_reward).
create or replace function public.claim_onboarding_reward(
  p_room_id uuid,
  p_task text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_amount integer;
  v_joined_at timestamptz;
  v_eligible boolean;
  v_inserted uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_room_id is null then
    raise exception 'room_required' using errcode = '22023';
  end if;

  v_amount := case p_task
    when 'first_feed' then 20
    when 'co_keeper_joined' then 50
    when 'first_furniture' then 10
    when 'first_chat' then 10
  end;
  if v_amount is null then
    raise exception 'invalid_task' using errcode = '22023';
  end if;

  select rm.joined_at into v_joined_at
  from room_members rm
  where rm.room_id = p_room_id
    and rm.user_id = v_uid
    and rm.is_active;
  if not found then
    raise exception 'not_member' using errcode = '42501';
  end if;

  v_eligible := case p_task
    when 'first_feed' then exists (
      select 1 from messages m
      where m.room_id = p_room_id and m.sender_id = v_uid
        and m.type = 'image_feed'
    )
    when 'first_chat' then exists (
      select 1 from messages m
      where m.room_id = p_room_id and m.sender_id = v_uid
        and m.type = 'text'
    )
    when 'first_furniture' then exists (
      select 1 from room_furniture rf
      where rf.room_id = p_room_id and rf.owner_user_id = v_uid
    )
    -- Someone joined after the caller: the caller brought a co-keeper.
    when 'co_keeper_joined' then exists (
      select 1 from room_members other
      where other.room_id = p_room_id
        and other.user_id <> v_uid
        and other.is_active
        and other.joined_at > v_joined_at
    )
  end;
  if not v_eligible then
    return 0;
  end if;

  insert into coin_ledger (user_id, room_id, source, amount, metadata)
  values (
    v_uid, p_room_id, 'onboarding', v_amount,
    jsonb_build_object('task', p_task)
  )
  on conflict (user_id, (metadata ->> 'task')) where source = 'onboarding'
  do nothing
  returning id into v_inserted;

  if v_inserted is null then
    return 0;
  end if;

  update profiles set coins = coins + v_amount where user_id = v_uid;
  return v_amount;
end;
$$;

revoke all on function public.claim_onboarding_reward(uuid, text)
  from public, anon;
grant execute on function public.claim_onboarding_reward(uuid, text)
  to authenticated;
