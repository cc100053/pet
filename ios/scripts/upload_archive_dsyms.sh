#!/bin/sh
set -eu

# Uploads every dSYM in an .xcarchive to Crashlytics.
#
# The in-Xcode "Upload Crashlytics dSYMs" build phase is best-effort: it runs
# inside the build graph and can only see what has been written so far. The
# archive, by contrast, is complete by definition — Xcode copies every dSYM
# into it before the archive action finishes. Uploading from here is therefore
# the authoritative path, and the build phase is the convenience fallback.

usage() {
  echo "Usage: $0 <path-to-archive.xcarchive>" >&2
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ $# -ne 1 ]; then
  usage
  exit 64
fi

ARCHIVE_PATH=$1
if [ ! -d "${ARCHIVE_PATH}" ]; then
  echo "Archive not found: ${ARCHIVE_PATH}" >&2
  exit 66
fi

DSYM_DIR="${ARCHIVE_PATH}/dSYMs"
if [ ! -d "${DSYM_DIR}" ]; then
  echo "Archive has no dSYMs directory: ${DSYM_DIR}" >&2
  exit 66
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)
GOOGLE_SERVICE_INFO="${REPO_ROOT}/ios/Runner/GoogleService-Info.plist"

if [ ! -f "${GOOGLE_SERVICE_INFO}" ]; then
  echo "GoogleService-Info.plist not found: ${GOOGLE_SERVICE_INFO}" >&2
  exit 66
fi

# Firebase arrives through the Flutter-generated Swift package, so upload-symbols
# lives in whichever SourcePackages checkout the last build used. CocoaPods is
# checked first in case the integration ever moves back.
UPLOAD_SCRIPT=""
for candidate in \
  "${REPO_ROOT}/ios/Pods/FirebaseCrashlytics/upload-symbols" \
  "${REPO_ROOT}/build/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" \
  "${HOME}"/Library/Developer/Xcode/DerivedData/Runner-*/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols
do
  if [ -x "${candidate}" ]; then
    UPLOAD_SCRIPT="${candidate}"
    break
  fi
done

if [ -z "${UPLOAD_SCRIPT}" ]; then
  echo "Crashlytics upload-symbols not found. Build the iOS app once so the" >&2
  echo "firebase-ios-sdk package is checked out, then re-run." >&2
  exit 69
fi

echo "Uploading dSYMs to Crashlytics:"
echo "  archive: ${ARCHIVE_PATH}"
echo "  tool:    ${UPLOAD_SCRIPT}"

"${UPLOAD_SCRIPT}" -gsp "${GOOGLE_SERVICE_INFO}" -p ios "${DSYM_DIR}"
