#!/bin/sh
set -e

if [ "${CONFIGURATION}" = "Debug" ]; then
  exit 0
fi

if [ -z "${DWARF_DSYM_FOLDER_PATH}" ] || [ ! -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
  echo "dSYM folder not found. Skipping Crashlytics symbol upload."
  exit 0
fi

if [ -z "${PODS_ROOT}" ]; then
  echo "PODS_ROOT is not set. Skipping Crashlytics symbol upload."
  exit 0
fi

UPLOAD_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"
GOOGLE_SERVICE_INFO="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ ! -x "${UPLOAD_SCRIPT}" ]; then
  echo "Crashlytics upload-symbols script not found. Skipping."
  exit 0
fi

if [ ! -f "${GOOGLE_SERVICE_INFO}" ]; then
  echo "GoogleService-Info.plist not found. Skipping Crashlytics symbol upload."
  exit 0
fi

find "${DWARF_DSYM_FOLDER_PATH}" -name "*.dSYM" -print0 | while IFS= read -r -d '' dsym
do
  echo "Uploading dSYM: ${dsym}"
  "${UPLOAD_SCRIPT}" -gsp "${GOOGLE_SERVICE_INFO}" -p ios "${dsym}"
done
