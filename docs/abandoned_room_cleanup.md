# Abandoned Room Photo Cleanup (R2)

Human-in-the-loop system that reclaims Cloudflare R2 storage by deleting photos
from rooms that are no longer used. Detection is automatic; **deletion only
happens for rooms you explicitly approve** in Supabase Studio.

## Why human review

Room storage cost is currently small and photo deletion is irreversible. A room
that has been quiet for weeks is not necessarily abandoned — couples/close
relationships often go dormant then return. So the cron only *flags* candidates;
a human approves before anything is deleted.

## How photos are stored

Room photos are uploaded by the `feed_validate` edge function under the R2 key
prefix:

```
rooms/<room_id>/<yyyy>/<mm>/<dd>/<uuid>.<ext>
```

Cleanup therefore lists/deletes everything under `rooms/<room_id>/`. (Avatars
use a separate `avatars/<user_id>/...` prefix and are never touched here.)

## Data model

`rooms` lifecycle columns (added by migration `20260602120000`):

| Column | Meaning |
| --- | --- |
| `last_activity_at` | Kept fresh by triggers on `messages` insert and `room_members` join/activation. The abandonment signal. |
| `status` | `active` (default) or `abandoned` (set after purge). |
| `abandoned_at` / `photos_purged_at` / `photos_purged_count` | Stamped when a room is purged. |

Triggers (`touch_room_last_activity`) also "revive" a room (back to `active`) if
it somehow receives activity after being marked abandoned.

Review queue (migration `20260602120500`):

- `room_cleanup_candidates` — one row per flagged room: R2 photo snapshot
  (`photo_count`, `photo_bytes`), `review_status`
  (`pending` / `approved` / `rejected` / `purged`), timestamps, `note`.
- `room_cleanup_review` — admin-only view joining the snapshot with live
  evidence. **Not exposed to anon/authenticated** (view it in Studio):
  - `all_members_left` — hard proof everyone explicitly left
    (`room_members.is_active`).
  - `members` (JSON) — per user `nickname / is_active / left_at / last_action_at`.
    `last_action_at` = that user's most recent message — the best available
    proxy for "last online" (presence is not persisted).
  - `photo_count`, `size_mb`, `last_activity_at`, `inactive_days`.

## Edge function: `cleanup_abandoned_rooms`

Deployed with `verify_jwt = false`. Authenticated by a Vault secret
(`cleanup_rooms_secret`), verified via `get_cleanup_rooms_secret()` — same
pattern as `hunger_tick_dispatch`. Reuses the existing `aws4fetch` R2 client and
`R2_*` secrets (no new credentials).

Request body:

| Field | Default | Notes |
| --- | --- | --- |
| `mode` | `scan` | `scan` = flag candidates (no delete). `purge` = delete approved rooms' photos. |
| `inactive_days` | `30` | (scan) rooms with `last_activity_at` older than this are flagged. |
| `room_limit` | `200` | (scan) max rooms per run. |
| `dry_run` | `true` | (purge) list only; never deletes unless explicitly `false`. |

- **scan** queries `rooms` where `status='active'` and
  `last_activity_at < now() - inactive_days`, lists each room's R2 objects, and
  upserts a candidate via `record_room_cleanup_candidate()` (preserves any
  existing `review_status`).
- **purge** selects candidates with `review_status='approved'`, batch-deletes
  their R2 objects (`DeleteObjects`, 1000/batch), then marks the room
  `abandoned` and the candidate `purged`. If any object fails to delete the room
  stays approved and is retried next run.

## Scheduling

pg_cron jobs (migration `20260602121000`):

| Job | Cron (UTC) | Body |
| --- | --- | --- |
| `cleanup_abandoned_rooms_scan_daily` | `0 3 * * *` | `{mode:scan, inactive_days:30, room_limit:200}` |
| `cleanup_abandoned_rooms_purge_daily` | `30 3 * * *` | `{mode:purge, dry_run:false}` |

Purge runs on a schedule but only ever touches `approved` rows, so it is safe.

## Operator workflow

1. Open Supabase Studio → Table Editor → `room_cleanup_review` (sorted
   pending-first).
2. Review evidence per room (`all_members_left`, `members`, `photo_count`,
   `inactive_days`).
3. Set `review_status = 'approved'` to delete, or `'rejected'` to keep.
   `reviewed_at` is stamped automatically.
4. The next purge run (or a manual purge call) deletes approved rooms.

## Manual invocation

```bash
URL='https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/cleanup_abandoned_rooms'
# Vault secret: select decrypted_secret from vault.decrypted_secrets
#               where name='cleanup_rooms_secret';
SECRET='<cleanup_rooms_secret>'

# Flag candidates (no delete)
curl -s -X POST "$URL" -H "Authorization: Bearer $SECRET" \
  -H 'Content-Type: application/json' -d '{"mode":"scan","inactive_days":30}'

# Preview what an approved purge would delete (no delete)
curl -s -X POST "$URL" -H "Authorization: Bearer $SECRET" \
  -H 'Content-Type: application/json' -d '{"mode":"purge","dry_run":true}'

# Actually delete approved rooms' photos
curl -s -X POST "$URL" -H "Authorization: Bearer $SECRET" \
  -H 'Content-Type: application/json' -d '{"mode":"purge","dry_run":false}'
```

## Tuning

- Change the inactivity window by editing `inactive_days` in the scan cron body
  (migration `20260602121000`) or per manual call. 30 days is the conservative
  default chosen because deletion is irreversible.
- Secrets reused: `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`,
  `R2_BUCKET` (already set for `feed_validate`/`avatar_upload`).
