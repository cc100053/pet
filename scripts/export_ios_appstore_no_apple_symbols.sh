#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 <path-to-archive.xcarchive> [export-output-dir]" >&2
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage
  exit 64
fi

ARCHIVE_PATH=$1
if [ ! -d "${ARCHIVE_PATH}" ]; then
  echo "Archive not found: ${ARCHIVE_PATH}" >&2
  exit 66
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
EXPORT_OPTIONS="${REPO_ROOT}/ios/ExportOptions.app-store-nosymbols.plist"

if [ ! -f "${EXPORT_OPTIONS}" ]; then
  echo "Export options plist not found: ${EXPORT_OPTIONS}" >&2
  exit 66
fi

if [ $# -eq 2 ]; then
  EXPORT_PATH=$2
else
  ARCHIVE_NAME=$(basename "${ARCHIVE_PATH}" .xcarchive)
  EXPORT_PATH="${REPO_ROOT}/build/ios/app-store-upload/${ARCHIVE_NAME}"
fi

mkdir -p "${EXPORT_PATH}"

echo "Exporting and uploading archive:"
echo "  archive: ${ARCHIVE_PATH}"
echo "  output:  ${EXPORT_PATH}"
echo "  options: ${EXPORT_OPTIONS}"

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}"

# uploadSymbols=false means App Store Connect never gets a copy of the dSYMs, so
# this archive is the only one that will ever exist. Preserve it before the next
# `flutter build ipa` overwrites build/ios/archive, and push the symbols to
# Crashlytics now — a build shipped without them produces crash reports that can
# never be symbolicated afterwards.
ARCHIVE_VERSION=$(plutil -extract ApplicationProperties.CFBundleShortVersionString raw "${ARCHIVE_PATH}/Info.plist" 2>/dev/null || echo unknown)
ARCHIVE_BUILD=$(plutil -extract ApplicationProperties.CFBundleVersion raw "${ARCHIVE_PATH}/Info.plist" 2>/dev/null || echo unknown)
ARCHIVE_STORE="${HOME}/Library/Developer/Xcode/Archives/shipped"
PRESERVED="${ARCHIVE_STORE}/Runner ${ARCHIVE_VERSION} (${ARCHIVE_BUILD}).xcarchive"

if [ "$(CDPATH= cd -- "${ARCHIVE_PATH}" && pwd)" != "$(CDPATH= cd -- "${PRESERVED}" 2>/dev/null && pwd || echo '')" ]; then
  mkdir -p "${ARCHIVE_STORE}"
  rm -rf "${PRESERVED}"
  cp -R "${ARCHIVE_PATH}" "${PRESERVED}"
  echo "Preserved archive: ${PRESERVED}"
fi

"${REPO_ROOT}/ios/scripts/upload_archive_dsyms.sh" "${ARCHIVE_PATH}"

echo "Done. Apple immediate symbol upload was disabled by uploadSymbols=false."
echo "dSYMs were uploaded to Crashlytics and the archive was preserved for re-upload."
