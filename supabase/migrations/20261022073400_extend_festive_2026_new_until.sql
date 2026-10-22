-- Festive 2026 drop: extend the NEW window past the Halloween drop's so,
-- on clients with the latest-drop rule, it takes over the NEW badge.
update public.items
set metadata = metadata || jsonb_build_object('new_until', '2026-11-22T00:00:00Z')
where sku in (
  'furniture_candle',
  'furniture_candy_cane',
  'furniture_sunflower',
  'furniture_gift',
  'furniture_christmas_tree'
);
