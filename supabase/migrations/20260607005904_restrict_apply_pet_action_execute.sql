-- Keep apply_pet_action callable only by signed-in clients. The function also
-- checks auth.uid(), but explicit grants keep the Data API surface aligned with
-- intent and avoid anon SECURITY DEFINER exposure.

revoke all on function public.apply_pet_action(uuid, text)
  from public, anon, authenticated;
grant execute on function public.apply_pet_action(uuid, text)
  to authenticated;
