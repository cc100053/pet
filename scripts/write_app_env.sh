#!/usr/bin/env bash
# Writes .env.app: the only env file bundled into the app (pubspec assets).
# Everything in it ships to every user in plain text, so it holds just the
# public client keys lib/services/env.dart reads. Server secrets stay in .env.
# Run after creating or changing .env, before flutter run/test/build.
set -euo pipefail
cd "$(dirname "$0")/.."

# Keep in sync with lib/services/env.dart (test/app_env_allowlist_test.dart).
ALLOWED_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  REVENUECAT_API_KEY_IOS
  REVENUECAT_API_KEY_ANDROID
  ADMOB_IOS_BANNER_AD_UNIT_ID
  ADMOB_IOS_REWARDED_AD_UNIT_ID
  ADMOB_ENABLE_DEBUG_BANNER_VIEWS
  ADMOB_TEST_DEVICE_IDS
  AD_REWARD_COINS
  PRIVACY_POLICY_URL
  TERMS_OF_USE_URL
)

[[ -f .env ]] || { echo "missing .env (copy .env.example)" >&2; exit 1; }

out=$(mktemp)
for key in "${ALLOWED_KEYS[@]}"; do
  grep -E "^${key}=" .env >>"$out" || true
done
for key in SUPABASE_URL SUPABASE_ANON_KEY PRIVACY_POLICY_URL; do
  grep -qE "^${key}=." "$out" || { rm -f "$out"; echo "missing $key in .env" >&2; exit 1; }
done
mv "$out" .env.app
echo "wrote .env.app ($(wc -l <.env.app | tr -d ' ') keys)"
