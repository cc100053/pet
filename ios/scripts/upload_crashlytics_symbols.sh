#!/bin/sh
set -e

if [ "${CONFIGURATION}" = "Debug" ]; then
  exit 0
fi

if [ -z "${DWARF_DSYM_FOLDER_PATH}" ] || [ ! -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
  echo "dSYM folder not found. Skipping Crashlytics symbol upload."
  exit 0
fi

GOOGLE_SERVICE_INFO="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

UPLOAD_SCRIPT=""

use_upload_script_if_present() {
  if [ -n "$1" ] && [ -x "$1" ]; then
    UPLOAD_SCRIPT="$1"
    return 0
  fi
  return 1
}

use_upload_script_if_present "${PODS_ROOT:-}/FirebaseCrashlytics/upload-symbols" || true
use_upload_script_if_present "${BUILD_DIR%Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" || true
use_upload_script_if_present "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" || true
use_upload_script_if_present "${DERIVED_DATA_DIR:-}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" || true
use_upload_script_if_present "${CI_DERIVED_DATA_PATH:-}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" || true

if [ ! -x "${UPLOAD_SCRIPT}" ]; then
  echo "Crashlytics upload-symbols script not found. Skipping."
  exit 0
fi

if [ ! -f "${GOOGLE_SERVICE_INFO}" ]; then
  echo "GoogleService-Info.plist not found. Skipping Crashlytics symbol upload."
  exit 0
fi

find "${DWARF_DSYM_FOLDER_PATH}" -name "*.dSYM" -type d -print | while IFS= read -r dsym
do
  echo "Uploading dSYM: ${dsym}"
  "${UPLOAD_SCRIPT}" -gsp "${GOOGLE_SERVICE_INFO}" -p ios "${dsym}"
done
