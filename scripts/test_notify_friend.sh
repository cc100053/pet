#!/usr/bin/env bash
set -euo pipefail

: "${NOTIFY_WEBHOOK_URL:?Set NOTIFY_WEBHOOK_URL}"
: "${NOTIFY_WEBHOOK_SECRET:?Set NOTIFY_WEBHOOK_SECRET}"
: "${RECIPIENT_ID:?Set RECIPIENT_ID (user id with device_tokens row)}"
: "${ROOM_ID:?Set ROOM_ID}"
: "${SENDER_ID:?Set SENDER_ID}"
: "${MESSAGE_ID:?Set MESSAGE_ID}"

payload=$(cat <<JSON
{
  "type": "feed_event",
  "room_id": "${ROOM_ID}",
  "sender_id": "${SENDER_ID}",
  "recipient_ids": ["${RECIPIENT_ID}"],
  "message_id": "${MESSAGE_ID}",
  "image_url": "https://example.com/test.jpg",
  "caption": "Test notification",
  "canonical_tags": ["beverage.coffee"],
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
)

curl -sS -X POST "$NOTIFY_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $NOTIFY_WEBHOOK_SECRET" \
  -d "$payload"
