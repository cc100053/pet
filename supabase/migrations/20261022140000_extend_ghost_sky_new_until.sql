-- Ghost Sky (Pro-only, 6.0.0) ships with the festive 2026 drop: align its NEW
-- window with the festive furniture so the build is not mostly past NEW on arrival.
update public.items
set metadata = metadata || jsonb_build_object('new_until', '2026-11-22T00:00:00Z')
where sku = 'background_ghost_sky';
