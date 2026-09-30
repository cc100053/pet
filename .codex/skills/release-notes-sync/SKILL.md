---
name: release-notes-sync
description: Draft PicPet release notes and execute the approved metadata, build, upload, and attachment flow.
---

# Release Notes Sync

Bundled What's New and ASC release notes describe the same release but use
separate copy. Keep this skill's existing name for repository workflow routing.

## Copy and locales

- Bundle: `lib/shared/whats_new/app_whats_new_catalog.dart` and
  `lib/l10n/app_*.arb`. Use one title, up to three user-facing bullets, and an
  optional CTA. Preserve older entries and ARB keys; update an existing version
  rather than duplicating it. Version keys use the public version; ARB suffixes
  remove dots (`1.2.1` → `121`).
- ASC: `.asc/version-localizations/*.strings`. Preserve approved long-form
  `whatsNew` (the repo uses `Ver X.X.X Update Details` headers). Never replace it
  with abbreviated bundle bullets. `promotionalText` describes relevant,
  verified PicPet features and stays within 170 characters.
- Existing bundle locales are `en`, `ja`, `ko`, `zh_TW`, `zh`; ASC counterparts
  are `en-US`, `ja`, `ko`, `zh-Hant`. Simplified Chinese stays bundled-only.
  Draft translations for these existing locales and present them as drafts;
  do not invent release facts or add supported locales without authorization.
- Preserve unmanaged metadata and valid ARB/.strings syntax. ASC descriptions
  must retain their localized Terms of Use / EULA footer and the direct
  `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` URL.
- Marketing URL remains `https://pet-app-702be.web.app/`. Preserve existing
  localized support/privacy URLs from the `.strings` assets and `README.md`.

## Catalog items in this release

Version-gated shop items (`metadata.min_app_version`) go live with the build,
not with their migration. Before drafting copy for version `V`:

- Diff `get_visible_shop_items('V')` against the last shipped version's result
  on the verified project. Every newly visible item's asset must be in this
  build: run `flutter build bundle` and check `AssetManifest.bin` plus
  `build/flutter_assets/assets/`. A gate set for a version that was later
  renumbered (e.g. `3.3.1` shipping as `4.0.0`) still has to resolve to this
  build and no earlier one.
- Name the newly visible items (at least a seasonal drop) in the bundled
  What's New and ASC `whatsNew`. What's New is the first dialog on a new
  version; the in-room new-items popup waits for it to close.
- Compare each newly visible item's `new_until` with the expected on-sale date.
  If the NEW window would be mostly spent before players have the build, draft
  an extension migration for approval (rules: `AGENTS.md` migration bullet).
- Seasonal `promotionalText` gets an end date recorded in
  `docs/release_status.md`; refresh stale promotional copy (e.g. an old version
  number) on every release. `promotionalText` can change without a build.

## Approval and execution

Present localized drafts before applying local copy or ASC changes. Explain
that approval of the full flow authorizes local edits, ASC metadata sync, IPA
build, dSYM upload/archive preservation, IPA upload, processing verification,
and build attachment. Respect draft-only, local-only, or metadata-only scope.
App Review submission always requires an explicit submission request.

For approved execution, read [release-execution.md](references/release-execution.md).
Include the catalog diff and any `new_until` or promotional-text proposal in the
drafts you present.
Before release operations, read/update
[release_status.md](../../../docs/release_status.md). Pass local generation and
required validation before metadata upload or release build. Immediately after
building, upload dSYMs and preserve the archive before anything overwrites it;
a non-zero upload-helper exit blocks release.

Completion means the approved operations are verified, their exact results and
pending human checks are recorded, and the root repository completion rules are
satisfied. A completed build can be the current repository release baseline;
public availability is a separate verified state. Do not call an attached or
submitted build publicly released without evidence.
