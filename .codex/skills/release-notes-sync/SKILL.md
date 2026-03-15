---
name: release-notes-sync
description: Update PetTomo release notes in two places from localized user input: (1) simplify and ship user-facing What's New copy in the app bundle, and (2) upload the full per-locale release notes to App Store Connect with the asc CLI. Use when the user asks to update bundled What's New copy, release notes, version-localized App Store text, or App Store Connect What's New content.
---

# Release Notes Sync

Use this skill when the user gives localized release-note text for a new app version and wants both:

1. A short user-facing `What's New` entry bundled inside the app.
2. The full localized `What's New` text uploaded to App Store Connect via `asc`.

Keep these two outputs separate. The bundle copy is short and simplified. The App Store Connect copy stays verbatim.

## Inputs

Expect input blocks like:

- `日本語 (Japanese)`
- `繁體中文 (Traditional Chinese)`
- `英文 (English)`
- `韓文 (Korean)`

Each block usually includes a version header like `【Ver 1.0.4 更新内容】` and a long-form body.

Parse and normalize:

- Version: `1.0.4`
- Locale map:
  - English -> `en` bundle, `en-US` ASC
  - Japanese -> `ja` bundle, `ja` ASC
  - Korean -> `ko` bundle, `ko` ASC
  - Traditional Chinese -> `zh_TW` bundle, `zh-Hant` ASC

Current repo note:

- The Flutter bundle also has `lib/l10n/app_zh.arb` (Simplified Chinese). Do not invent that translation. If the task requires updating every supported in-app locale and the user did not provide Simplified Chinese copy, stop and ask for it.

## Source Of Truth

### Bundle copy

Update these files:

- `lib/shared/whats_new/app_whats_new_catalog.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`
- `lib/l10n/app_zh_TW.arb`
- `lib/l10n/app_zh.arb` only if the user provided Simplified Chinese or explicitly approved reuse

After ARB changes, run:

```bash
flutter gen-l10n
```

### App Store Connect copy

Local repo source files:

- `.asc/version-localizations/en-US.strings`
- `.asc/version-localizations/ja.strings`
- `.asc/version-localizations/ko.strings`
- `.asc/version-localizations/zh-Hant.strings`

The `whatsNew` field in each file should match the user's provided long-form text verbatim for that locale.

## Bundle Rules

The bundled `What's New` is for end users inside the app, so rewrite the copy into a concise, user-facing summary.

Always do all of the following:

- Write exactly 1 short title and up to 3 bullets per locale.
- Keep the tone user-facing and benefit-oriented.
- Merge overlapping ideas instead of repeating them.
- Prefer concrete visible outcomes over implementation details.
- Preserve the meaning across locales.

Never include:

- Parameter tweaks
- Internal refactors
- Backend-only changes
- Analytics / admin / review notes
- Tooling, migration, or schema changes
- Anything the user cannot directly notice

If the supplied text has more than 3 user-visible ideas:

- Compress them into the strongest 2-3 user-visible points.

## Bundle Editing Pattern

When adding a new version, keep all old entries.

1. Append a new `AppWhatsNewEntry` in `lib/shared/whats_new/app_whats_new_catalog.dart`.
2. Follow the existing key naming pattern:
   - `whatsNew106Title`
   - `whatsNew106Bullet1`
   - `whatsNew106Bullet2`
   - `whatsNew106Bullet3`
3. Point the catalog entry to the new localized getters.
4. Do not remove historical keys or entries.

Use the version digits without dots in the localization key suffix.

Examples:

- `1.0.4` -> `104`
- `1.0.5` -> `105`
- `1.1.0` -> `110`

## ASC Rules

For App Store Connect:

- Do not shorten, paraphrase, or improve the user's text.
- Do not normalize punctuation unless required for file escaping.
- Preserve the provided locale-specific copy as-is.
- Update only the `whatsNew` field unless the user explicitly asked for other metadata changes.

## ASC Workflow

1. Update the local `.asc/version-localizations/*.strings` files first.
2. Discover the current editable App Store version:

```bash
asc versions list --app 6757725650
```

3. Discover localization IDs for that version:

```bash
asc localizations list --version <VERSION_ID>
```

4. Use the installed `asc` CLI to push the updated `whatsNew` values for each locale.

Because `asc` subcommands can change, do not guess blindly. Inspect the available help on the installed CLI and choose the command that updates version-localization metadata for `whatsNew`.

Check in this order:

```bash
asc --help
asc localizations --help
asc version-localizations --help
asc metadata --help
```

Preferred behavior:

- If the CLI supports pushing from the `.asc/version-localizations/` directory, use that.
- Otherwise update each localization record directly with the supported version-localization command.

If the CLI is not authenticated, use the existing repo ASC auth flow before retrying.

## Output Contract

When using this skill, finish with:

1. The version processed.
2. Which bundle files were updated.
3. Which ASC locale files were updated.
4. Whether ASC upload succeeded, and which version/localization IDs were used.
5. Verification run:
   - `flutter gen-l10n`
   - `flutter analyze`
   - `flutter test`

## Guardrails

- Do not fabricate missing locale translations.
- Do not drop older bundle versions.
- Do not upload bundle-shortened text to App Store Connect.
- Do not place internal engineering details into bundled `What's New` bullets.
- Keep the app bundle and ASC text intentionally different when the source text is long.
