-- Pet names: one server-side length rule, applied on every naming path.
--
-- Two gaps this closes:
--   1. `update_pet_name` capped names at 20 while the client caps at 12, so the
--      server was not actually the authority it looked like.
--   2. Naming a pet right after room creation wrote `pets.name` straight from
--      the client, bypassing the RPC entirely — that path had no server-side
--      validation at all.
--
-- The limit lives in `pet_name_max_length()` rather than being repeated in each
-- function, so the RPCs cannot drift apart the way the client's four hard-coded
-- 20s did. Client-side the same number lives in `kPetNameMaxLength`.

create or replace function public.pet_name_max_length()
returns int
language sql
immutable
as $function$
  select 12
$function$;

-- Trims and validates, returning the value to store. Every write path calls
-- this instead of spelling out its own rules.
create or replace function public.validate_pet_name(p_name text)
returns text
language plpgsql
immutable
as $function$
declare
  v_trimmed text;
begin
  v_trimmed := trim(coalesce(p_name, ''));

  if v_trimmed = '' then
    raise exception 'invalid_name';
  end if;

  if char_length(v_trimmed) > public.pet_name_max_length() then
    raise exception 'name_too_long';
  end if;

  return v_trimmed;
end;
$function$;

-- Renaming an already-named pet. Unchanged except that the length rule now
-- comes from `validate_pet_name` (12) instead of a local literal (20).
create or replace function public.update_pet_name(p_pet_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_room_id uuid;
  v_trimmed text;
  v_nickname text;
  v_old_name text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id, name into v_room_id, v_old_name from pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  v_trimmed := public.validate_pet_name(p_name);

  update pets
  set name = v_trimmed
  where id = p_pet_id;

  select nickname into v_nickname from profiles where user_id = auth.uid();

  if v_old_name is null or trim(v_old_name) = '' then
    v_old_name := 'Unnamed';
  else
    v_old_name := trim(v_old_name);
  end if;

  insert into messages (room_id, sender_id, type, body, coins_awarded)
  values (
    v_room_id,
    null,
    'system',
    coalesce(v_nickname, 'Someone') || ' renamed the pet from ' || v_old_name ||
      ' to ' || v_trimmed || '.',
    0
  );
end;
$function$;

-- Naming a pet for the first time, straight after `create_room` (which inserts
-- the pet with a null name).
--
-- Deliberately NOT `update_pet_name`: that one posts a "renamed the pet from
-- Unnamed to X" system message, which is noise for a pet nobody had named yet.
-- Restricting this to unnamed pets is what keeps the two apart — it cannot be
-- used as a quiet rename that skips the system message.
--
-- Re-sending the same name is a no-op rather than an error, so a retry after a
-- dropped response does not surface a failure to the user.
create or replace function public.set_initial_pet_name(p_pet_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_room_id uuid;
  v_existing text;
  v_trimmed text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select room_id, name into v_room_id, v_existing from pets where id = p_pet_id;
  if v_room_id is null then
    raise exception 'pet_not_found';
  end if;

  if not public.is_room_member(v_room_id) then
    raise exception 'not_room_member';
  end if;

  v_trimmed := public.validate_pet_name(p_name);

  if v_existing is not null and trim(v_existing) <> '' then
    if trim(v_existing) = v_trimmed then
      return;
    end if;
    raise exception 'pet_already_named';
  end if;

  update pets
  set name = v_trimmed
  where id = p_pet_id;
end;
$function$;

revoke all on function public.pet_name_max_length() from public;
revoke all on function public.validate_pet_name(text) from public;
revoke all on function public.set_initial_pet_name(uuid, text) from public;

grant execute on function public.pet_name_max_length() to authenticated;
grant execute on function public.validate_pet_name(text) to authenticated;
grant execute on function public.set_initial_pet_name(uuid, text) to authenticated;
