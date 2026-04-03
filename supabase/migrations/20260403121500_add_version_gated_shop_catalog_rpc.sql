begin;

create or replace function public.app_version_compare(
  p_left text,
  p_right text
)
returns integer
language plpgsql
immutable
as $$
declare
  v_left_parts text[];
  v_right_parts text[];
  v_max_len integer;
  v_index integer;
  v_left_value integer;
  v_right_value integer;
begin
  v_left_parts := string_to_array(split_part(coalesce(p_left, ''), '+', 1), '.');
  v_right_parts := string_to_array(split_part(coalesce(p_right, ''), '+', 1), '.');
  v_max_len := greatest(
    coalesce(array_length(v_left_parts, 1), 0),
    coalesce(array_length(v_right_parts, 1), 0)
  );

  if v_max_len = 0 then
    return 0;
  end if;

  for v_index in 1..v_max_len loop
    v_left_value := coalesce(
      nullif(
        regexp_replace(coalesce(v_left_parts[v_index], '0'), '[^0-9].*$', '', 'g'),
        ''
      )::integer,
      0
    );
    v_right_value := coalesce(
      nullif(
        regexp_replace(coalesce(v_right_parts[v_index], '0'), '[^0-9].*$', '', 'g'),
        ''
      )::integer,
      0
    );

    if v_left_value < v_right_value then
      return -1;
    end if;
    if v_left_value > v_right_value then
      return 1;
    end if;
  end loop;

  return 0;
end;
$$;

create or replace function public.get_visible_shop_items(
  p_app_version text
)
returns setof public.items
language sql
stable
security invoker
as $$
  select i.*
  from public.items i
  where (
    coalesce(i.is_active, false) = true
    and coalesce(i.metadata->>'visibility_mode', 'public') = 'public'
  )
  or (
    coalesce(i.metadata->>'visibility_mode', 'public') = 'version_gated'
    and public.app_version_compare(
      coalesce(p_app_version, ''),
      coalesce(i.metadata->>'min_app_version', '0.0.0')
    ) >= 0
  );
$$;

grant execute on function public.app_version_compare(text, text) to authenticated;
grant execute on function public.get_visible_shop_items(text) to authenticated;

commit;
