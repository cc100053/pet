-- Mark a specific user as admin via Supabase auth app metadata.
update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'is_admin', true,
    'admin', true,
    'role', 'admin'
  )
where id = '1964870f-c0e9-4c72-8c54-6360a6dd605d'::uuid;
