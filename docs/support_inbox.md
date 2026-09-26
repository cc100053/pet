# Support Inbox Runbook

The in-app support thread (Profile → Send Feedback → `SupportView`) replaces
the external support web form. Contract: `support_messages` in
`memory-bank/database-schema.md`.

## Flow

1. User sends a message. The row is inserted with `sender = 'user'` and
   `meta` (app_version, platform, os_version, device_model, locale).
2. An AFTER INSERT trigger sends `{id}` through pg_net to `support_notify`.
3. `support_notify` emails the message plus meta to `SUPPORT_EMAIL` via Resend.
   The email includes a ready-made reply SQL statement.
4. You reply by inserting a row with `sender = 'admin'` (SQL below). The same
   trigger fires, and `support_notify` pushes the reply to the user's devices.
   The user sees it the next time they open the support screen.

## Replying

Run in the SQL editor
(`https://supabase.com/dashboard/project/ilxzpszgirhwxpeocygs/sql/new`):

```sql
insert into public.support_messages (user_id, sender, body)
values ('<user_id>', 'admin', 'Your reply');

-- full thread
select sender, body, meta, created_at from public.support_messages
where user_id = '<user_id>' order by created_at;
```

## Configuration

| Where | Name | Notes |
| --- | --- | --- |
| Edge Function secret | `SUPPORT_NOTIFY_SECRET` | Must equal the vault secret below |
| Vault | `support_notify_secret` | Read by the trigger function |
| Edge Function secret | `RESEND_API_KEY` | Resend key with sending access |
| Edge Function secret | `SUPPORT_EMAIL` | Inbox that receives user messages |
| Edge Function secret | `SUPPORT_EMAIL_FROM` | Optional; defaults to `onboarding@resend.dev` |

Until a domain is verified in Resend, `onboarding@resend.dev` only delivers to
the Resend account owner's address, so `SUPPORT_EMAIL` must be that address.

The FCM push reuses the `GOOGLE_SERVICE_ACCOUNT` or `FCM_*` secrets from
`notify_friend`.

Rotating the shared secret: set the new value in both places.

```sql
select vault.update_secret(
  (select id from vault.secrets where name = 'support_notify_secret'),
  '<new value>'
);
```

## Troubleshooting

Check the latest trigger calls:

```sql
select id, status_code, content, error_msg, created
from net._http_response order by created desc limit 10;
```

- `401 unauthorized`: `SUPPORT_NOTIFY_SECRET` is missing or does not match the
  vault secret.
- `500 email_config_missing` / `502 email_failed`: Resend key or
  `SUPPORT_EMAIL` is wrong; `content` carries Resend's error.
- `200 no_device_tokens_found`: the user has no registered device, so no push
  was sent.

To re-send a missed notification without a new row:

```sql
select net.http_post(
  url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/support_notify',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer ' || (select decrypted_secret
      from vault.decrypted_secrets where name = 'support_notify_secret')
  ),
  body := jsonb_build_object('id', '<support_messages.id>')
);
```

## Known Limits

- Tapping a reply push only opens the app; it does not route to the support
  screen.
- There is no unread badge, no attachments, and no ticket status.
- Builds released before this screen still open the web support pages, so keep
  them hosted.
