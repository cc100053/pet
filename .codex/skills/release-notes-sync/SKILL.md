---
name: release-notes-sync
description: Maintain bundled in-app What's New entries and App Store Connect release notes together without mixing their copy rules. Use when adding a new app-version release note, updating localized What's New text, syncing ASC whatsNew fields, or preparing release-note assets for this repo.
---

# Release Notes Sync

Keep bundled `What's New` copy and App Store Connect `whatsNew` / `promotionalText` copy in sync, but never treat them as the same artifact.

## Source Of Truth In This Repo
- Bundled in-app `What's New`:
  - `lib/shared/whats_new/app_whats_new_catalog.dart`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ja.arb`
  - `lib/l10n/app_ko.arb`
  - `lib/l10n/app_zh_TW.arb`
  - `lib/l10n/app_zh.arb` (Simplified Chinese; maintained bundled locale)
- App Store Connect version metadata:
  - `.asc/version-localizations/en-US.strings`
  - `.asc/version-localizations/ja.strings`
  - `.asc/version-localizations/ko.strings`
  - `.asc/version-localizations/zh-Hant.strings`

## Output Rules
- Bundled `What's New` is concise, product-facing, and rewritten for in-app reading.
- Bundled copy uses:
  - one title
  - up to 3 bullets (concise summary)
  - optional CTA label (e.g., `whatsNewContinueAction`)
- ASC `whatsNew` is verbatim long-form release-note text.
- ASC `promotionalText` is short, SEO-optimized marketing copy (max 170 chars).
- ASC `description` must retain a functional `Terms of Use / EULA` URL footer.
  This app has auto-renewable subscriptions; do not upload version metadata
  where `.asc/version-localizations/*.strings` descriptions omit `EULA` and the
  direct Apple Standard EULA URL.
- Never upload shortened bundled bullets to ASC `whatsNew`.
- Never copy long-form ASC prose directly into bundled bullets without rewriting.
- Never fabricate missing translations.
- Never delete older bundled version entries; append new ones.

## Version + Locale Rules
- Version keys are the public app version string from `pubspec.yaml` / `PackageInfo.version`.
- ARB key suffix removes dots from the semantic version:
  - `1.2.1` -> `121`
  - `1.0.5` -> `105`
- Locale mapping for this repo:
  - bundle `en` -> ASC `en-US`
  - bundle `ja` -> ASC `ja`
  - bundle `ko` -> ASC `ko`
  - bundle `zh_TW` -> ASC `zh-Hant`
  - bundle `zh` (Simplified) has no ASC locale counterpart in this repo; keep it
    bundled-only and do not invent an ASC `zh-Hans` file.
- If the user supplies locales that are not present in repo assets, stop and report the gap instead of inventing text.

## Repo Update Workflow

### Phase 0: Drafting (Input Processing)
When the user provides a version and a summary (e.g., in Cantonese like "v1.0.5 呢個更新主要係一個安全性更新..."):
1. **Translate & Draft:** Generate localized drafts for all supported locales (`en-US`, `ja`, `ko`, `zh-Hant`).
2. **Review Formatting:** Ensure the ASC `whatsNew` follows the "Ver X.X.X Update Details" header format used in this repo.
3. **Present for Approval:** Display the drafts clearly. **Explain that approving these drafts (e.g., "proceed", "OK") will trigger the full release-notes flow: local file updates, App Store Connect metadata sync, App Store IPA build, Crashlytics dSYM upload plus archive preservation, IPA upload, build processing wait/check, and build attachment. App Store Review submission still requires an explicit submission request.**

### Phase 1: Execution (After Approval)
Once the user approves the drafts, perform the following steps autonomously:
1. **Extract Version:** Identify the target public version (e.g., `1.0.6`).
2. **Update Bundled Assets:**
   - Append/update the entry in `lib/shared/whats_new/app_whats_new_catalog.dart`.
   - Add/update matching ARB keys in `lib/l10n/app_*.arb`.
3. **Update ASC Assets:**
   - Write localized `whatsNew` and `promotionalText` to `.asc/version-localizations/*.strings`.
4. **App Store Connect Sync:**
   - Check if the version (e.g., `1.0.6`) exists in ASC via `asc versions list`.
   - If missing, create it via `asc versions create --copy-metadata-from <PREVIOUS_VERSION>`.
   - Upload the local `.strings` files using `asc localizations upload`.
   - If `asc versions create`, `asc versions view`, or
     `asc localizations upload` returns App Store Connect `-50`, treat it as a
     known `asc` wrapper failure for this repo. Do **not** rename an existing
     approved version and do not upload new release notes into the previous
     version. Use the direct API fallback instead:
     ```bash
     ASC_KEY_ID="..." ASC_ISSUER_ID="..." ASC_PRIVATE_KEY_PATH="..." \
       /Users/fatboy/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
       scripts/asc_version_localization_sync.py \
       --app 6757725650 \
       --version <VERSION> \
       --localizations-dir .asc/version-localizations
     ```
   - Verify a fallback run with `asc versions list --app 6757725650 --output table`
     and/or the script's final read-back output. The script refuses to sync
     descriptions that do not include the direct Apple Standard EULA URL.
5. **Archive, Upload, And Build Processing (Default After Approval):**
   - After the user approves the draft, archive/upload is part of the default
     release-notes-sync execution. Do not stop after ASC metadata sync unless
     the user explicitly asks for metadata-only / draft-only work.
   - Archive with the repo's existing Flutter/Xcode Runner settings; do not add
     iPad support or change device-family settings.
   - Preflight the active iOS target settings before archiving and preserve:
     `TARGETED_DEVICE_FAMILY = 1`, `SUPPORTED_PLATFORMS = iphoneos iphonesimulator`,
     and `SUPPORTS_MACCATALYST = NO`.
   - If building through Flutter, pass the intended public version and build
     number explicitly, e.g.
     `flutter build ipa --release --build-name=<VERSION> --build-number=<BUILD>`.
   - Verify the packaged IPA before upload: `CFBundleShortVersionString`,
     `CFBundleVersion`, `UIDeviceFamily`, `UISupportedInterfaceOrientations`, and
     `UIRequiresFullScreen`.
   - **Mandatory before anything else touches `build/ios/archive`:** upload the
     archive's dSYMs to Crashlytics and preserve the archive.
     ```bash
     ios/scripts/upload_archive_dsyms.sh build/ios/archive/Runner.xcarchive
     ```
     The next `flutter build ipa` overwrites `build/ios/archive/Runner.xcarchive`
     and App Store Connect never holds a usable copy, so skipping this loses the
     symbols permanently — crashes for that build arrive at Crashlytics but can
     never be symbolicated. 2.3.1 (14), 2.3.2 (15) and 2.4.0 (19) were all lost
     this way. Treat a non-zero exit as a release blocker, not a warning; the
     command also copies the archive to
     `~/Library/Developer/Xcode/Archives/shipped/Runner <VERSION> (<BUILD>).xcarchive`
     and prints the uploaded UUIDs. Record those UUIDs for step 7.
   - Creating an archive/IPA is not enough. Upload the IPA with
     `asc builds upload --app 6757725650 --ipa <IPA_PATH>`.
   - After upload, wait for App Store Connect processing with a 10-minute
     timeout because ASC build discovery/processing can take several minutes:
     `asc builds wait --app 6757725650 --build-number <BUILD> --version <VERSION> --platform IOS --timeout 10m --poll-interval 30s`.
   - If the build is not discoverable immediately after upload, check
     `asc builds uploads list --app 6757725650 --output table`; an upload row in
     `PROCESSING` means Apple accepted the IPA but has not exposed the build
     entity yet. Keep polling until `VALID`, `FAILED`, or timeout.
   - If `asc builds wait` times out while resolving the build selector, do not
     assume upload failure. Check:
     ```bash
     asc builds uploads list --app 6757725650 --output table
     asc builds info --latest --app 6757725650 --platform IOS --output table
     ```
     If the target version/build is `VALID`, attach it to the ASC version with
     `asc versions attach-build --version-id <VERSION_ID> --build <BUILD_ID>`.
   - Attaching the processed build is part of the default approved
     release-notes-sync flow. Submitting for App Review is not; only submit when
     the user explicitly asks for submission/review.
6. **Validation & Verification:**
   - Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`.
   - Confirm `test/app_store_metadata_terms_test.dart` passes before ASC upload.
   - Confirm the ASC update via `asc localizations list`.
   - Confirm the preserved archive exists at
     `~/Library/Developer/Xcode/Archives/shipped/Runner <VERSION> (<BUILD>).xcarchive`.
     Its absence means the dSYM step never ran.
   - `[USER ACTION REQUIRED]` Check Crashlytics → Settings → Missing dSYMs and
     confirm none of the UUIDs printed in step 5 is listed. This is the only
     check that catches a failed upload; do not report the release as complete
     without it.
7. **Release Ledger Completion Rule:**
   - After the whole approved release-notes-sync flow is complete for a target
     version (local metadata, ASC localization sync, archive/upload, dSYM upload
     and archive preservation, build processing verification, build attachment,
     and any requested submission steps), update `docs/release_status.md`,
     `memory-bank/progress.md`, and `tasks/todo.md` as if that target version is
     the live public version for repo workflow purposes.
   - Move the target version into the Current Public Release / current-state
     wording, move the previous current version into historical context if
     needed, and make the next action "monitor review/store outcome" only as an
     operational note.
   - Record the dSYM outcome in `docs/release_status.md`: the preserved archive
     path, the uploaded `Runner`/`App.framework` UUIDs, and the result of the
     Missing dSYMs check. A release row without this is not complete.
   - Do not leave the completed target version tracked as merely "next release
     candidate" solely because App Store Connect still says
     `WAITING_FOR_REVIEW`, `PENDING_DEVELOPER_RELEASE`, or another post-submit
     state. Record the exact ASC state and IDs, but treat the completed target
     version as the repo's current release baseline.
8. **Preserve History:** Never delete older bundled version entries or ARB keys.

## Static Metadata URL Rules
- **Marketing URL**: Always use `https://pet-app-702be.web.app/`.
- **Support URL**: Refer to the localized URLs in `README.md`:
  - English (en-US): `https://pet-app-702be.web.app/support.html`
  - Japanese (ja): `https://pet-app-702be.web.app/support_ja.html`
  - Korean (ko): `https://pet-app-702be.web.app/support_ko.html`
  - Traditional Chinese (zh-Hant): `https://pet-app-702be.web.app/support_zh_TW.html`
- **Privacy Policy URL**:
  - English (en-US): `https://pet-app-702be.web.app/privacy_policy.html`
  - Japanese (ja): `https://pet-app-702be.web.app/privacy_policy_ja.html`
  - Korean (ko): `https://pet-app-702be.web.app/privacy_policy_ko.html`
  - Traditional Chinese (zh-Hant): `https://pet-app-702be.web.app/privacy_policy_zh_TW.html`
- **Terms of Use / EULA URL footer in version descriptions**:
  - English (en-US): `Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  - Japanese (ja): `利用規約（Terms of Use / EULA）: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  - Korean (ko): `이용약관(Terms of Use / EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  - Traditional Chinese (zh-Hant): `使用條款（Terms of Use / EULA）：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

## ASC CLI Workflow
Do not guess subcommands from memory. **Always refer to `asc-metadata-sync` and `asc-cli-usage` for detailed flags and formatting rules.**

1. Find the app ID and active version ID:
```bash
asc apps list
asc versions list --app 6757725650
```
2. **Mandatory: Use .strings file upload for correct formatting.** Do not use direct string updates via `--whats-new` or `--promotional-text` flags if the content contains newlines or complex characters, as this can result in literal `\n` characters in the App Store.
3. Upload the local `.strings` asset:
```bash
asc localizations upload --version <VERSION_ID> --locale ja --path .asc/version-localizations/ja.strings
```
4. Verify the upload:
```bash
asc localizations list --version <VERSION_ID> --output table
```

### Direct API Fallback For ASC `-50`
The `asc` CLI wrappers can return Apple's generic `-50` error even when the
same operation succeeds through the public App Store Connect API. This repo has
a checked-in fallback:

```bash
ASC_KEY_ID="..." ASC_ISSUER_ID="..." ASC_PRIVATE_KEY_PATH="..." \
  /Users/fatboy/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/asc_version_localization_sync.py \
  --app 6757725650 \
  --version <VERSION> \
  --localizations-dir .asc/version-localizations
```

Use `--dry-run` first when diagnosing. The fallback is idempotent: it reuses an
existing version if present, creates the version if missing, creates or patches
the locale records from `.asc/version-localizations/*.strings`, and reads back
the result to confirm `promotionalText`, `whatsNew`, and the direct EULA footer
are present. Use the bundled Codex Python shown above because the system
`python3` available to elevated network commands may not include
`cryptography`.

## Content Guardrails
- Bundled bullets must stay user-facing.
- Avoid internal engineering details, migration notes, schema changes, or config-only changes unless users directly notice them.
- Cap bundled bullets at 3 even if the supplied notes are longer.
- If the supplied ASC release notes contain more detail, keep that detail in `.asc/version-localizations/*.strings`.
- **Promotional Text SEO:** Ensure `promotionalText` includes high-intent keywords relevant to the current release (e.g., "AI scanning", "best price", "discount tracking").

## Expected Agent Behavior
- If the version already exists in the bundled catalog, update that version’s localized keys instead of duplicating the entry.
- If the ASC locale file is missing, create it with only the fields being managed.
- If asked to sync multiple locales later, add only the locales the user actually provides.
- **File Integrity:** For small `.strings` or `.arb` files, prefer `write_file` over `replace` to avoid partial string remnants or unclosed quotes.
- **ASC Format:** Always ensure `.strings` files end exactly after the last semicolon; trailing content from previous `replace` calls will cause ASC upload errors.
