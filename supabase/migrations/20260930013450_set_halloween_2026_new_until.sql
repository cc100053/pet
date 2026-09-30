begin;

-- Halloween 2026 drop: one NEW-badge window for all three pieces (shop NEW
-- badge + in-room new-items popup). The pumpkin's value was first set as a
-- one-off write; recorded here so the repo reproduces production.
update public.items
set metadata = metadata || jsonb_build_object('new_until', '2026-11-01T00:00:00Z')
where sku in (
  'furniture_pumpkin_lantern',
  'furniture_candy_cauldron',
  'furniture_bat_armchair'
);

commit;
