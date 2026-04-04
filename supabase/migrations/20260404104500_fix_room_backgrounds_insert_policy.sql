begin;

drop policy if exists room_backgrounds_insert on public.room_backgrounds;

create policy room_backgrounds_insert on public.room_backgrounds
for insert
with check (
  public.is_room_member(room_id)
  and acquired_by = auth.uid()
  and exists (
    select 1
    from public.items
    where items.id = room_backgrounds.item_id
      and (items.metadata->>'category') = 'background'
      and coalesce(items.metadata->>'shop_visibility', '') <> 'hidden'
      and (
        coalesce(items.is_active, false) = true
        or coalesce(items.metadata->>'visibility_mode', 'public') = 'version_gated'
      )
  )
);

commit;
