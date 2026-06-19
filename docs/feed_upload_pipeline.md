# Feed Upload Pipeline

This runbook covers the photo-feed path from Flutter upload through Supabase
Edge Functions, DB reward writes, push notification dispatch, and client
reconciliation.

Before changing this pipeline, read `docs/ai_collaboration_workflow.md`.
Feed upload touches server response contracts, old installed clients, local
durable queue state, rewards, hunger, and push notifications.

## Runtime Flow

1. Flutter enqueues a `FeedUploadJob` in the durable Hive/Riverpod queue.
2. Home shows the optimistic feed image and increments the reward-pending UI.
3. `SupabaseFeedUploadClient` compresses the image and calls
   `feed_validate` with the user's Supabase Auth JWT.
4. `feed_validate` validates membership/image data, uploads to R2 when needed,
   maps labels, and calls `process_feed_event`.
5. `process_feed_event` writes the feed message and applies server-authoritative
   coins/hunger updates in one DB path.
6. `feed_validate` returns the reward response to the app.
7. Home consumes the queue completion event, applies local coin feedback,
   reconciles pet/profile state, and clears the reward-pending UI.
8. Partner push delivery runs separately through `notify_friend`.

## Edge Function Contract

`feed_validate` is deployed with `verify_jwt=true` and still validates the user
inside the function via `auth.getUser()` using the `Authorization` header.

The response fields consumed by clients are:

- `ok`
- `message_id`
- `image_url`
- `coins_awarded`
- `reward_status`
- `cooldown.is_active`
- `cooldown.last_fed_at`
- `cooldown.next_eligible_at`
- `pet_state` (optional, v21+): authoritative committed post-feed state read from
  `room_pet_state` — `hunger`, `mood`, `hygiene`, `last_decay_at`,
  `last_feed_at`, `last_overfed_at`, `poop_at`, `poop_count`, `poop_positions`.
- `overfed` (optional, v21+): true when the feed added no hunger (fed again
  inside the 10-minute burst window).

`pet_state`/`overfed` exist because the reward path historically returned no
hunger, so the satiety bar depended on a realtime event / refetch that could
race and lose on slow uploads (intermittent "fed but hunger didn't move"). The
client now applies `pet_state` directly. They are additive and optional: old
clients ignore them. New clients also keep a `last_decay_at` freshness guard so
a stale pre-feed snapshot can never regress a fresher value, plus an optimistic
+25 prediction on enqueue that the authoritative value reconciles.

Compatibility fields should stay stable for old clients and debug tools:

- `webhook_skipped` remains a boolean. When notification dispatch is queued in
  the background, return `false` rather than `null`.
- `webhook_status` and `webhook_error` can be `null` when dispatch is async.
- New fields, such as `webhook_queued`, must be optional from the client point
  of view.

Do not remove or change the type of existing response fields without planning a
version-gated rollout.

## Notification Dispatch

Photo-feed push notification is intentionally not on the reward response path.
`feed_validate` queues `notify_friend` with `EdgeRuntime.waitUntil(...)` after
the feed message/reward work has completed.

This avoids a slow or degraded push path keeping the sender stuck on the
reward-pending UI. Production logs previously showed `feed_validate` v16 taking
28.7s while the nested `notify_friend` call took 16.8s. The v17/v18 behavior is
for the sender to receive the reward response first, while partner notification
delivery continues in the background.

If push delivery fails, it should be handled as notification telemetry/retry
work. It should not turn a successful feed reward into an upload failure.

## Existing-User Queue Handling

The app persists feed jobs locally so uploads can survive restarts. A user can
therefore have an old failed job saved from a previous timeout or server error.

Current handling:

- Pending/uploading jobs reload as pending and are resumed.
- Failed jobs persisted from a previous app run reload as pending too.
- Before re-uploading, the queue calls `findCompletedUpload(...)` using
  `client_created_at` tolerance to find an already-written message.
- If the message is found, the job completes as reconciled without uploading
  again or replaying the old error.
- Only a fresh terminal failure after the retry budget is exhausted should show
  the user-facing feed upload error.

This prevents existing users from seeing stale error snackbars after a feed
that already succeeded in the backend.

## Production Diagnosis

Use Supabase logs first:

- Edge Function logs: compare `feed_validate` and `notify_friend`
  `execution_time_ms`.
- Postgres logs: check for `statement timeout` around `process_feed_event`.
- API logs: check RPC status for `/rest/v1/rpc/process_feed_event`.

Expected healthy behavior after v18:

- `feed_validate` returns 200 without waiting for `notify_friend` to complete.
- `notify_friend` may appear shortly after the `feed_validate` response.
- `feed_validate` logs `response_ready` with `duration_ms` and
  `process_feed_duration_ms`.
- `notify_partner_complete` logs the background notification duration.

If `feed_validate` is still slow but `notify_friend` is not, focus on:

- R2 upload duration or image size.
- `process_feed_event` DB latency/timeouts.
- Quest reward RPC/update latency.
- Room/member/profile refresh after completion on the client.

## Verification

Focused tests:

```sh
flutter test test/feed_validate_function_test.dart
flutter test test/features/feed/feed_upload_queue_test.dart
```

Full checks before shipping:

```sh
flutter analyze
flutter test
```

Live integration test, when env vars are available:

```sh
flutter test test/feed_flow_integration_test.dart
```

Required env vars for the live test are documented in `docs/testing.md`.
