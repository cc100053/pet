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
  - `lib/l10n/app_zh.arb` (Simplified Chinese, only if provided)
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
- If the user supplies locales that are not present in repo assets, stop and report the gap instead of inventing text.

## Repo Update Workflow
1. Extract the target public version.
2. Read the provided localized release-note input.
3. Update bundled assets:
   - append a new entry in `app_whats_new_catalog.dart`
   - add matching ARB keys in the relevant `lib/l10n/app_*.arb` files.
4. Update ASC assets:
   - write the verbatim locale-specific `whatsNew` text and SEO-optimized `promotionalText` to `.asc/version-localizations/*.strings`.
5. Preserve every older bundled version entry and ARB key.
6. Run `flutter gen-l10n`, `flutter analyze` and `flutter test`.
7. **Sync to App Store Connect:** Activate and refer to `asc-metadata-sync` and `asc-cli-usage` for best output practices. Use the `.strings` file upload workflow below to ensure multi-line formatting (newlines) is correctly rendered in App Store Connect.

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
