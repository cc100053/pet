begin;

-- 2.3.5 never shipped; the four furniture pieces from
-- 20260813120000_add_v235_furniture_catalog bundle with 2.4.0 instead.
-- Re-gate to the release that actually carries the PNGs and flip them live.
update public.items
set
  metadata = metadata || jsonb_build_object('min_app_version', '2.4.0'),
  is_active = true
where sku in (
  'furniture_balloon',
  'furniture_cactus',
  'furniture_carpet',
  'furniture_vinyl'
);

commit;
