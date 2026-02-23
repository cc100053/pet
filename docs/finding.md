# Findings 3-6

## 3. [High] `notify_friend` can fail open when webhook secret is unset
- Risk:
  - If `NOTIFY_WEBHOOK_SECRET` is empty, payloads with `sender_id` + `recipient_ids` can be treated as webhook requests without auth checks.
  - Message validation can be skipped when `body`/`caption`/`image_url` is supplied, allowing spoofed push traffic attempts.
- Evidence:
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:305`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:308`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:309`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:311`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:337`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/index.ts:328`

## 4. [High] `delete_account` edge function likely crashes at runtime
- Risk:
  - `serve(...)` is called but not imported in this function file, which can break account deletion in production.
- Evidence:
  - `/Users/fatboy/pet/supabase/functions/delete_account/index.ts:1`
  - `/Users/fatboy/pet/supabase/functions/delete_account/index.ts:25`

## 5. [Medium][UX + stability] Image upload path has no size controls
- Risk:
  - Client sends original image bytes as base64 (no compression/size cap), and edge functions decode/upload without byte limits.
  - Large images can cause slow uploads, failures, and resource pressure.
- Evidence:
  - `/Users/fatboy/pet/lib/features/feed/feed_capture_view.dart:250`
  - `/Users/fatboy/pet/lib/features/feed/feed_capture_view.dart:272`
  - `/Users/fatboy/pet/supabase/functions/notify_friend/feed_validate/index.ts:145`
  - `/Users/fatboy/pet/supabase/functions/avatar_upload/index.ts:42`

## 6. [Medium][UX design] Unread badges can disagree with visible chat after blocking
- Risk:
  - Message visibility policy excludes blocked users, but unread RPC calculations do not apply equivalent block filtering.
  - Users can see unread badges for messages they cannot actually view.
- Evidence:
  - `/Users/fatboy/pet/supabase/migrations/20260118000000_block_enforcement.sql:4`
  - `/Users/fatboy/pet/supabase/migrations/20260217113000_add_unread_tracking_and_badge_rpc.sql:50`
  - `/Users/fatboy/pet/supabase/migrations/20260217143000_add_unread_counts_per_room_rpc.sql:7`
