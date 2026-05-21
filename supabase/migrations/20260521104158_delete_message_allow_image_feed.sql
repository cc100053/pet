-- Recall sent photo: allow the sender to soft-delete their own image_feed
-- message in addition to text. For image_feed we also null image_url + caption
-- so the photo and its caption disappear (privacy); coins_awarded is kept (no
-- claw-back) and the pet's feeding is not reversed. edit_message stays
-- text-only. Old clients never call delete on image_feed, so this is additive.
create or replace function public.delete_message(
  p_room_id uuid,
  p_message_id uuid
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
begin
  if v_user_id is null then
    raise exception 'auth_required' using errcode = '28000';
  end if;

  return query
  update public.messages m
  set
    body = null,
    image_url = case when m.type = 'image_feed' then null else m.image_url end,
    caption = case when m.type = 'image_feed' then null else m.caption end,
    deleted_at = now(),
    deleted_by = v_user_id
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
    raise exception 'message_not_deletable' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.delete_message(uuid, uuid) from public;
grant execute on function public.delete_message(uuid, uuid) to authenticated;
