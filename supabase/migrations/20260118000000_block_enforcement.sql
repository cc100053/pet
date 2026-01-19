-- Enforce block relationships when reading messages
drop policy if exists messages_select on messages;

create policy messages_select on messages
for select using (
  exists (
    select 1 from room_members rm
    where rm.room_id = messages.room_id
      and rm.user_id = auth.uid()
      and rm.is_active
  )
  and not exists (
    select 1
    from blocks b
    where (
      b.blocker_id = auth.uid()
      and b.blocked_user_id = messages.sender_id
    ) or (
      b.blocker_id = messages.sender_id
      and b.blocked_user_id = auth.uid()
    )
  )
);
