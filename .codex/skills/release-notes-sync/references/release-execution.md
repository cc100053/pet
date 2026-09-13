# Approved release execution

This procedure applies only to the scope approved through `SKILL.md`. Commands
run from the repository root. App ID: `6757725650`.

## Local preflight

Apply approved catalog/ARB/.strings changes, preserving older entries and
unmanaged fields. Generate localizations with `flutter gen-l10n`, then run the
canonical final-tree checks in `docs/testing.md`, in their required order.
`test/app_store_metadata_terms_test.dart` must pass before ASC metadata upload.
Choose the intended version explicitly; choose an available build number only
when a build is within the approved scope.

## Metadata sync

Run this section only when ASC synchronization is approved; skip it for
draft-only or local-only work.

Use `asc versions list --app 6757725650` to resolve the target version. Create
it if missing using the CLI's supported copy-metadata option. Consult
`asc-cli-usage` for unfamiliar syntax and `asc-metadata-sync` only for additional
localization workflow needs; do not guess flags.

Upload `.strings` files to preserve real newlines and complex characters:

```sh
asc localizations upload --version <VERSION_ID> --locale ja --path .asc/version-localizations/ja.strings
asc localizations list --version <VERSION_ID> --output table
```

Do not use inline `--whats-new`/`--promotional-text` for multiline copy. Verify
the exact target version and read-back content.

### ASC wrapper error `-50`

For `asc versions create`, `asc versions view`, or localization upload returning
`-50`, use `scripts/asc_version_localization_sync.py`. Never rename an approved
version or write new notes into the previous version. Discover the bundled
Python via `load_workspace_dependencies`; system Python may lack `cryptography`.
Supply `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY_PATH` through the
existing credential environment without printing secrets.

```sh
<BUNDLED_PYTHON> scripts/asc_version_localization_sync.py --app 6757725650 --version <VERSION> --localizations-dir .asc/version-localizations
```

Use `--dry-run` when diagnosing. The idempotent script creates/reuses the version
and locale records and verifies `whatsNew`, `promotionalText`, and the EULA
footer. Confirm its read-back or `asc versions list` results before continuing.

## Build, preserve, upload

Run this section only when build/upload is approved; skip it for draft-only,
local-only, or metadata-only scope. Preserve Runner device settings:
`TARGETED_DEVICE_FAMILY = 1`,
`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, `SUPPORTS_MACCATALYST = NO`.
Do not add iPad support or change device families as part of release notes.

```sh
flutter build ipa --release --build-name=<VERSION> --build-number=<BUILD>
ios/scripts/upload_archive_dsyms.sh build/ios/archive/Runner.xcarchive
```

The dSYM command must run immediately after building, before anything else
uses/overwrites `build/ios/archive`. A non-zero exit blocks release. It preserves
`~/Library/Developer/Xcode/Archives/shipped/Runner <VERSION> (<BUILD>).xcarchive`
and prints UUIDs to record. Verify the preserved archive exists. For recovery
or alternate export paths, use `docs/ios_app_store_export.md`.

Before uploading, inspect IPA `CFBundleShortVersionString`, `CFBundleVersion`,
`UIDeviceFamily`, `UISupportedInterfaceOrientations`, and `UIRequiresFullScreen`
against the intended version and existing Runner settings.

```sh
asc builds upload --app 6757725650 --ipa <IPA_PATH>
asc builds wait --app 6757725650 --build-number <BUILD> --version <VERSION> --platform IOS --timeout 10m --poll-interval 30s
```

On delayed discovery or selector timeout, inspect:

```sh
asc builds uploads list --app 6757725650 --output table
asc builds info --latest --app 6757725650 --platform IOS --output table
```

`PROCESSING` indicates an accepted upload, not failure. Wait within the
10-minute bound; stop on `FAILED` or timeout and record unresolved state without
uploading duplicates. Confirm the exact version/build, not merely the latest
row. Once `VALID`, attach it:

```sh
asc versions attach-build --version-id <VERSION_ID> --build <BUILD_ID>
```

Do not submit for App Review without an explicit request.

## Verification and ledger

Record metadata read-back, exact ASC state/IDs, build attachment, preserved
archive path, and Runner/App.framework UUIDs in `docs/release_status.md`.
Update relevant current-state progress/task notes under the root workflow.
Track the completed target as the repository release baseline separately from
verified public availability; review/submission status is not public-release
proof.

`[USER ACTION REQUIRED]` Check Crashlytics → Settings → Missing dSYMs and confirm
none of the uploaded UUIDs appears. Record the result; while pending, report
verified automated steps and the outstanding check, not full release completion.
