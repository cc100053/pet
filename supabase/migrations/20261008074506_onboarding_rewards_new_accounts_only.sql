-- Onboarding rewards are for new accounts only (created on/after
-- 2026-10-08 UTC). Same signature, grants and return contract as
-- 20261008065402; no released client calls it yet.

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

  -- New accounts only: existing players are not paid for the first-day
  -- checklist. Keep in sync with kFirstDayAccountCutoff in
  -- lib/features/onboarding/first_day_checklist.dart.
  if not exists (
    select 1 from auth.users u
    where u.id = v_uid and u.created_at >= timestamptz '2026-10-08 00:00:00+00'
  ) then
    return 0;
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
