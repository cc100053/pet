with ranked as (
  select id,
         user_id,
         row_number() over (
           partition by user_id
           order by updated_at desc nulls last,
                    last_seen_at desc nulls last,
                    created_at desc nulls last,
                    id
         ) as rn
  from device_tokens
)
delete from device_tokens dt
using ranked r
where dt.id = r.id
  and r.rn > 1;

drop index if exists device_tokens_user_idx;

create unique index if not exists device_tokens_user_unique_idx
  on device_tokens (user_id);
