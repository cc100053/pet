-- Fix create_room invite_code ambiguity by qualifying column reference.

create or replace function public.create_room(p_name text)
returns table (room_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_room_id uuid;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    v_attempts := v_attempts + 1;
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (
      select 1 from rooms r where r.invite_code = v_code
    );
    if v_attempts >= 20 then
      raise exception 'invite_code_exhausted';
    end if;
  end loop;

  insert into rooms (name, invite_code, invite_expires_at, created_by)
  values (p_name, v_code, now() + interval '60 minutes', auth.uid())
  returning id into v_room_id;

  insert into room_members (room_id, user_id, role, joined_at, is_active)
  values (v_room_id, auth.uid(), 'owner', now(), true);

  return query select v_room_id, v_code;
end;
$$;
