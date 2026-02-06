begin;

update public.items
set is_active = false
where sku in (
  'consumable_snack_pack',
  'consumable_clean_kit',
  'cosmetic_room_cozy',
  'cosmetic_room_sky',
  'background_test'
);

commit;
