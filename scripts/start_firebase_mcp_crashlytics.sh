#!/bin/sh
set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${FIREBASE_MCP_ENV_FILE:-${REPO_ROOT}/.firebase-mcp.env}"
NEEDS_ADC=1

for arg in "$@"; do
  if [ "${arg}" = "--generate-tool-list" ]; then
    NEEDS_ADC=0
    break
  fi
done

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install it first: npm install -g firebase-tools" >&2
  exit 1
fi

if [ -f "${ENV_FILE}" ]; then
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
fi

if [ "${NEEDS_ADC}" -eq 1 ]; then
  if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    echo "GOOGLE_APPLICATION_CREDENTIALS is not set." >&2
    echo "Create ${ENV_FILE} from .firebase-mcp.env.example and point it at your service-account JSON key." >&2
    exit 1
  fi

  if [ ! -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]; then
    echo "GOOGLE_APPLICATION_CREDENTIALS points to a missing file: ${GOOGLE_APPLICATION_CREDENTIALS}" >&2
    exit 1
  fi
fi

exec firebase mcp --dir "${REPO_ROOT}" --only core,crashlytics "$@"
