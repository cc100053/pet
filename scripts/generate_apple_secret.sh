#!/usr/bin/env bash
set -euo pipefail

# Load .env if it exists
if [ -f .env ]; then
  # Read variables while ignoring comments and empty lines
  export $(grep -v '^#' .env | xargs)
fi

# Default values from environment variables
TEAM_ID="${APPLE_TEAM_ID:-}"
CLIENT_ID="${APPLE_CLIENT_ID:-}"
KEY_ID="${APPLE_KEY_ID:-}"
P8_PATH="${APPLE_P8_PATH:-}"

# If arguments are provided, they will be passed directly to the node script 
# and will override the behavior if the node script handles duplicate flags, 
# but here we prioritize .env if no args are given.

if [ $# -eq 0 ]; then
  if [[ -z "$TEAM_ID" || -z "$CLIENT_ID" || -z "$KEY_ID" || -z "$P8_PATH" ]]; then
    echo "❌ Error: Missing required Apple credentials in .env or as arguments."
    echo "Please set APPLE_TEAM_ID, APPLE_CLIENT_ID, APPLE_KEY_ID, and APPLE_P8_PATH in your .env file,"
    echo "or pass them as arguments:"
    echo "  $0 --team-id <ID> --client-id <ID> --key-id <ID> --p8 <PATH>"
    exit 1
  fi
  
  echo "Reading credentials from .env..."
  node scripts/generate_apple_client_secret.mjs \
    --team-id "$TEAM_ID" \
    --client-id "$CLIENT_ID" \
    --key-id "$KEY_ID" \
    --p8 "$P8_PATH"
else
  # Pass all arguments directly if the user provides any
  node scripts/generate_apple_client_secret.mjs "$@"
fi

# If the node script succeeded, update the date file
if [ $? -eq 0 ]; then
  date +%Y-%m-%d > LAST_UPDATED_APPLE_SECRET.txt
  echo "✅ Updated LAST_UPDATED_APPLE_SECRET.txt with today's date."
fi
