-- Notification payload upgrade: pet avatar source + per-device locale

alter table if exists public.pets
  add column if not exists avatar_url text;

alter table if exists public.device_tokens
  add column if not exists device_locale text;

-- Backfill pet avatar URLs by pet type.
update public.pets
set avatar_url = case lower(coalesce(color_dna ->> 'pet_type', 'ghost'))
  when 'cat' then 'https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/cat_stay.gif'
  when 'fish' then 'https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/fish_stay.gif'
  else 'https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/ghost_stay.gif'
end
where avatar_url is null or btrim(avatar_url) = '';
