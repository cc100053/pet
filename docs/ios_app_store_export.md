# iOS App Store Export

Use this workflow when uploading an already-created Xcode archive to App Store
Connect from this repo.

## Why

Xcode Organizer can log non-fatal `Upload Symbols Failed` messages during
`IDEDistributionSymbolsStep` when `uploadSymbols=true`. The archive still
contains dSYMs and App Store Connect can still accept the build, but the warning
is noisy and has repeated during release exports.

The repo-tracked export options plist disables only Apple's immediate symbol
upload step:

- `ios/ExportOptions.app-store-nosymbols.plist`
- `uploadSymbols=false`

This does not disable dSYM generation. Keep the `.xcarchive` so dSYMs can be
uploaded to Crashlytics or Apple later if either service reports missing symbols.

## Export And Upload

Create the archive from Xcode or `flutter build ipa` / `xcodebuild archive`,
then upload the archive with:

```sh
scripts/export_ios_appstore_no_apple_symbols.sh "/path/to/Runner.xcarchive"
```

Optional output directory:

```sh
scripts/export_ios_appstore_no_apple_symbols.sh "/path/to/Runner.xcarchive" "/tmp/PetTomoExport"
```

## Verification

After upload, wait for App Store Connect processing and confirm the build is
`VALID` with no missing-symbol warning.

If Crashlytics later reports missing dSYMs, upload from the archive:

```sh
ios/Pods/FirebaseCrashlytics/upload-symbols \
  -gsp ios/Runner/GoogleService-Info.plist \
  -p ios \
  "/path/to/Runner.xcarchive/dSYMs"
```
