create or replace function public.tick_pet_state_as_system(
  p_pet_id uuid,
  p_now timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
begin
  select rm.user_id
  into v_actor_id
  from public.pets p
  join public.room_members rm
    on rm.room_id = p.room_id
   and rm.is_active = true
  where p.id = p_pet_id
  order by case when rm.role = 'owner' then 0 else 1 end,
           rm.joined_at asc
  limit 1;

  if v_actor_id is null then
    return;
  end if;

  perform set_config('request.jwt.claim.sub', v_actor_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform public.tick_pet_state(p_pet_id, p_now);
end;
$$;

revoke all on function public.tick_pet_state_as_system(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.tick_pet_state_as_system(uuid, timestamptz)
  to service_role;
