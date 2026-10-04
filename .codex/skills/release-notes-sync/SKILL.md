---
name: release-notes-sync
description: Report PicPet's current version, suggest a version bump, and draft release notes; after the user replies OK, run the full metadata, build, upload, and attachment runbook.
---

# Release Notes Sync

Bundled What's New and ASC release notes describe the same release but use
separate copy. Keep this skill's existing name for repository workflow routing.

## Two-phase flow

**Phase 1 — on trigger (read-only).** Reply with exactly these, and stop:

1. **Current version**: `pubspec.yaml` `version` (name+build), the last shipped
   baseline in `docs/release_status.md`, and the latest version in
   `asc versions list --app 6757725650` (skip ASC if unavailable; say so).
2. **Suggested bump**: from the shipped baseline, using the commits since it
   (`git log <baseline commit>..HEAD --oneline`): `feat` or user-visible
   content → minor, fixes/perf only → patch, breaking/major redesign → major.
   Give the target version, next free build number, and a one-line reason.
   If `pubspec.yaml` already holds an unshipped target, propose that instead.
3. **Draft notes**: bundled What's New and ASC `whatsNew`/`promotionalText`
   for every locale below, plus the catalog diff and any `new_until` or
   promotional-text proposal (see "Catalog items in this release").

End with: "Reply OK to run the full runbook, or tell me what to change."
Make no file, ASC, or build changes in this phase.

**Phase 2 — on "OK" (or equivalent).** Treat it as approval of the full
flow for the version, build number, and drafts shown, then run
"Approval and execution" end to end without further prompts. If the user
edits the drafts or version first, revise and re-present Phase 1. A narrower
reply ("local only", "metadata only") limits the scope accordingly.

## Copy and locales

- Bundle: `lib/shared/whats_new/app_whats_new_catalog.dart` and
  `lib/l10n/app_*.arb`. Use one title, up to three rows, and an optional CTA.
  Preserve older entries and ARB keys; update an existing version rather than
  duplicating it. Version keys use the public version; ARB suffixes remove
  dots (`1.2.1` → `121`).
- Each bundle row is an icon, a headline, and an optional detail line; the
  centered dialog renders each as a full-width tinted tile, not a sentence.
  A headline must fit one line of the tile on a 320pt phone:
  - `whatsNew<V>BulletN`: headline, a noun phrase with no terminal
    punctuation. Max ja/zh 12 chars, ko 14, en 28.
  - `whatsNew<V>BulletNDetail`: optional, one fact only (e.g. the lead item
    name plus "and more"), never a list of every item. Max ja/zh 16 chars,
    ko 18, en 32.
  - `bulletIcons`: pick from `AppWhatsNewIcon` — `newItem` (furniture,
    equipment, backgrounds), `newPet`, `design` (visual refresh), `feature`
    (new capability), `social` (chat, shared rooms, invites), `fix`
    (bug fixes, stability). Add an enum value only with approval.
  - Title stays short (it is the dialog heading): ja/zh ≤16 chars, ko ≤18, en ≤32.
  - Use shop-visible item names (the localized `ShopItem` name), not
    alternative names from marketing copy.
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

Phase 1 drafts come before any local copy or ASC change. Approval of the full
flow (Phase 2 "OK") authorizes local edits, version bump in `pubspec.yaml`,
ASC metadata sync, IPA build, dSYM upload/archive preservation, IPA upload,
processing verification, build attachment, and the commit/push required by
`AGENTS.md`. Respect draft-only, local-only, or metadata-only scope.
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
