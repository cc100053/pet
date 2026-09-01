-- Edit sent photo: allow the sender to edit their own image_feed message's
-- caption, in addition to editing text message bodies. For image_feed the
-- edited text lands in `caption` (the photo itself is never touched); for text
-- it still lands in `body`. Old clients only ever call this for text rows, so
-- this is additive.
create or replace function public.edit_message(
  p_room_id uuid,
  p_message_id uuid,
  p_body text
)
returns table (
  id uuid,
  room_id uuid,
  sender_id uuid,
  type text,
  body text,
  image_url text,
  caption text,
  coins_awarded int,
  created_at timestamptz,
  client_created_at timestamptz,
  labels jsonb,
  reply_to_message_id uuid,
  edited_at timestamptz,
  deleted_at timestamptz,
  deleted_by uuid
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_body text := btrim(coalesce(p_body, ''));
begin
  if v_user_id is null then
    raise exception 'auth_required' using errcode = '28000';
  end if;

  if v_body = '' then
    raise exception 'message_body_required' using errcode = '22023';
  end if;

  return query
  update public.messages m
  set
    body = case when m.type = 'image_feed' then m.body else v_body end,
    caption = case when m.type = 'image_feed' then v_body else m.caption end,
    edited_at = now()
  where m.id = p_message_id
    and m.room_id = p_room_id
    and m.sender_id = v_user_id
    and m.type in ('text', 'image_feed')
    and m.deleted_at is null
    and exists (
      select 1
      from public.room_members rm
      where rm.room_id = p_room_id
        and rm.user_id = v_user_id
        and rm.is_active
    )
  returning
    m.id,
    m.room_id,
    m.sender_id,
    m.type,
    m.body,
    m.image_url,
    m.caption,
    m.coins_awarded,
    m.created_at,
    m.client_created_at,
    m.labels,
    m.reply_to_message_id,
    m.edited_at,
    m.deleted_at,
    m.deleted_by;

  if not found then
    raise exception 'message_not_editable' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.edit_message(uuid, uuid, text) from public;
grant execute on function public.edit_message(uuid, uuid, text) to authenticated;
