#!/bin/sh
set -e

# Convenience fallback only. ios/scripts/upload_archive_dsyms.sh is the
# authoritative upload; this phase exists so local Release builds are covered
# too. Every skip below is announced as an Xcode `warning:` rather than exiting
# quietly: 2.3.1 (14), 2.3.2 (15) and 2.4.0 (19) each shipped unsymbolicatable
# because a silent skip here left no trace in the build log.

if [ "${CONFIGURATION}" = "Debug" ]; then
  exit 0
fi

if [ -z "${DWARF_DSYM_FOLDER_PATH}" ] || [ ! -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
  echo "warning: dSYM folder not found. Skipping Crashlytics symbol upload."
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
  echo "warning: Crashlytics upload-symbols script not found. Skipping."
  exit 0
fi

if [ ! -f "${GOOGLE_SERVICE_INFO}" ]; then
  echo "warning: GoogleService-Info.plist not found. Skipping Crashlytics symbol upload."
  exit 0
fi

# `find | while` runs the loop in a subshell, so a failed upload used to be
# swallowed and the build still succeeded. Track failures and fail the build.
FAILED=0
for dsym in "${DWARF_DSYM_FOLDER_PATH}"/*.dSYM
do
  if [ ! -d "${dsym}" ]; then
    echo "warning: no dSYMs in ${DWARF_DSYM_FOLDER_PATH}. Nothing uploaded to Crashlytics."
    break
  fi
  echo "Uploading dSYM: ${dsym}"
  if ! "${UPLOAD_SCRIPT}" -gsp "${GOOGLE_SERVICE_INFO}" -p ios "${dsym}"; then
    echo "error: Crashlytics symbol upload failed for ${dsym}"
    FAILED=1
  fi
done

exit "${FAILED}"
