-- Fix: equipping gear onto a non-main (extra) pet failed with RLS error 42501.
--
-- pet_equipment.pet_id may reference either public.pets (main pet) or
-- public.room_extra_pets (additional pets). The equip_pet_item RPC is
-- SECURITY INVOKER and validates the pet against BOTH tables, but the
-- pet_equipment INSERT/UPDATE policies' WITH CHECK only validated against
-- public.pets. Equipping onto an extra pet therefore failed the WITH CHECK.
-- Allow the pet to exist in either table.

drop policy if exists pet_equipment_insert on public.pet_equipment;
create policy pet_equipment_insert
  on public.pet_equipment
  for insert
  to authenticated
  with check (
    public.is_room_member(room_id)
    and equipped_by = auth.uid()
    and (
      exists (
        select 1
        from public.pets
        where pets.id = pet_equipment.pet_id
          and pets.room_id = pet_equipment.room_id
      )
      or exists (
        select 1
        from public.room_extra_pets rep
        where rep.id = pet_equipment.pet_id
          and rep.room_id = pet_equipment.room_id
      )
    )
    and exists (
      select 1
      from public.items
      where items.id = pet_equipment.item_id
        and items.metadata->>'category' = 'equipment'
        and items.metadata->>'equipment_slot' = pet_equipment.slot
    )
  );

drop policy if exists pet_equipment_update on public.pet_equipment;
create policy pet_equipment_update
  on public.pet_equipment
  for update
  to authenticated
  using (public.is_room_member(room_id))
  with check (
    public.is_room_member(room_id)
    and equipped_by = auth.uid()
    and (
      exists (
        select 1
        from public.pets
        where pets.id = pet_equipment.pet_id
          and pets.room_id = pet_equipment.room_id
      )
      or exists (
        select 1
        from public.room_extra_pets rep
        where rep.id = pet_equipment.pet_id
          and rep.room_id = pet_equipment.room_id
      )
    )
    and exists (
      select 1
      from public.items
      where items.id = pet_equipment.item_id
        and items.metadata->>'category' = 'equipment'
        and items.metadata->>'equipment_slot' = pet_equipment.slot
    )
  );
