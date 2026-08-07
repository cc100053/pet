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

This does not disable dSYM generation, but it does mean App Store Connect never
receives a copy: **the `.xcarchive` is the only place the dSYMs will ever exist.**
A build shipped without its symbols reaching Crashlytics produces crash reports
that can never be symbolicated afterwards, so the export script preserves the
archive and uploads its dSYMs automatically (see below).

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

After exporting, the script also:

1. Copies the archive to
   `~/Library/Developer/Xcode/Archives/shipped/Runner <version> (<build>).xcarchive`,
   because `build/ios/archive/Runner.xcarchive` is overwritten by the next
   `flutter build ipa`.
2. Uploads every dSYM in the archive to Crashlytics via
   `ios/scripts/upload_archive_dsyms.sh`.

## dSYMs And Crashlytics

Two things upload symbols, and only the second is reliable:

- The **`Upload Crashlytics dSYMs` build phase** runs inside the Xcode build
  graph. It declares `$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)` as an
  input so it is ordered after `dsymutil` produces `Runner.app.dSYM`. Without
  that input Xcode ran the phase first, and every release shipped with the app
  binary's own dSYM missing while the framework dSYMs uploaded fine — which is
  what blocked 2.3.1 (14) and 2.3.2 (15) from ever being symbolicated.
- The **archive upload** run by the export script. The archive is complete by
  definition, so this is the authoritative path.

A missing dSYM does not stop Crashlytics from *receiving* a crash, but it does
stop it from being processed and displayed. The Crashlytics "Missing dSYM" table
shows an event count per UUID: those events appear once the dSYM lands.

To re-upload from any preserved archive:

```sh
ios/scripts/upload_archive_dsyms.sh "/path/to/Runner.xcarchive"
```

## Verification

After upload, wait for App Store Connect processing and confirm the build is
`VALID` with no missing-symbol warning.

Then check Crashlytics → Settings → Missing dSYMs and confirm the new build's
`Runner` UUID is not listed. Compare against the archive with:

```sh
dwarfdump --uuid "/path/to/Runner.xcarchive/dSYMs/Runner.app.dSYM"
```
