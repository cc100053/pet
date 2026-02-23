create or replace function public.process_feed_event(
  p_room_id uuid,
  p_image_url text,
  p_caption text,
  p_labels jsonb,
  p_client_created_at timestamptz default null
)
returns table(
  message_id uuid,
  message_created_at timestamptz,
  base_reward int,
  reward_status text,
  last_fed_at timestamptz,
  next_eligible_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_pet_id uuid;
  v_message_id uuid;
  v_message_created_at timestamptz;
  v_base_reward int := 0;
  v_last_fed_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_room_id is null then
    raise exception 'room_id_required';
  end if;

  if nullif(trim(coalesce(p_image_url, '')), '') is null then
    raise exception 'image_url_required';
  end if;

  if not public.is_room_member(p_room_id) then
    raise exception 'not_room_member';
  end if;

  select id
  into v_pet_id
  from public.pets
  where room_id = p_room_id;

  if v_pet_id is null then
    raise exception 'pet_not_found';
  end if;

  perform public.apply_pet_action(v_pet_id, 'feed');

  v_base_reward := coalesce(public.claim_action_reward('feed', p_room_id), 0);

  insert into public.messages (
    room_id,
    sender_id,
    type,
    body,
    image_url,
    caption,
    labels,
    coins_awarded,
    mood_delta,
    client_created_at
  )
  values (
    p_room_id,
    auth.uid(),
    'image_feed',
    null,
    p_image_url,
    p_caption,
    coalesce(p_labels, '[]'::jsonb),
    v_base_reward,
    0,
    p_client_created_at
  )
  returning id, created_at into v_message_id, v_message_created_at;

  select ac.last_reward_at
  into v_last_fed_at
  from public.action_cooldowns ac
  where ac.user_id = auth.uid()
    and ac.room_id = p_room_id
    and ac.action_type = 'feed';

  message_id := v_message_id;
  message_created_at := v_message_created_at;
  base_reward := v_base_reward;
  reward_status := case when v_base_reward > 0 then 'granted' else 'cooldown' end;
  last_fed_at := v_last_fed_at;
  next_eligible_at := case
    when v_last_fed_at is null then null
    else v_last_fed_at + interval '10 minutes'
  end;

  return next;
end;
$$;

revoke all on function public.process_feed_event(uuid, text, text, jsonb, timestamptz) from public;
grant execute on function public.process_feed_event(uuid, text, text, jsonb, timestamptz) to authenticated;
