# Release Status

This file is the repo source of truth for app release state and backend
deployment status. Update it whenever an app build, App Store Connect state,
server hotfix, Supabase migration, force-update config, or compatibility
decision changes.

Do not use git commit messages as the release-status source of truth. Commits
explain code history; this file records the operational state. Use git tags as
immutable snapshots only after a release is actually shipped or a deployment is
worth pinning.

## Current Public Release

Verify live store state before relying on these values for release decisions.

| Platform | Public version | Build | Store status | Verified at | Source | Git tag |
| --- | --- | --- | --- | --- | --- | --- |
| iOS | Unknown from current repo snapshot | Unknown | Verify in App Store Connect or App Store lookup | Not freshly verified | App Store Connect / storefront | none |
| Android | Not tracked in current repo snapshot | - | Not tracked | - | - | none |

## Last Repo-Known Public Release

This section is a historical repo hint, not a live-store guarantee.

| Platform | Version | Build | Status note | Evidence | Git tag |
| --- | --- | --- | --- | --- | --- |
| iOS | 2.0.2 | 4 | Previously recorded as public in archived release notes; verify before using as current truth | Commit `ce4c85e` (`chore(release): bump to 2.0.2+4 with localized What's New`) | none |

## Next Release Candidate

| Platform | Version | Build | Local source | Store status | Store IDs | Next action | Git reference | Git tag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iOS | 2.1.0 | 5 | `pubspec.yaml` `2.1.0+5` | ASC version is `PREPARE_FOR_SUBMISSION`; uploaded build is `VALID` and encryption `exempt` | ASC version `37897d26-cc47-492c-867f-c7bc3ee4d44b`; build `67f39308-02eb-4a9a-9d32-64698ea4d99b` | Attach build to ASC version, run submission preflight, then submit | `0f07f7f` metadata sync commit | none |

## Backend Deployments

| Date | System | Target | Status | Compatibility note | Verification |
| --- | --- | --- | --- | --- | --- |
| 2026-06-07 | Supabase Edge Function + migration | `cleanup_abandoned_rooms` v2 and `20260607135307_guard_cleanup_purge_activity` on project `ilxzpszgirhwxpeocygs` | Active / Applied | Keeps `verify_jwt=false` custom bearer-secret auth; purge now fails closed unless approved candidates still match the stale room/R2 scan snapshot, and new room activity resets approved cleanup candidates to pending | MCP confirmed function v2/config, migration history, trigger/function permissions, active cleanup cron jobs, and cleanup queue `pending=88`, `purged=63`, `approved=0`; focused cleanup safety test; Supabase advisors checked; `flutter analyze`; `flutter test` |
| 2026-06-07 | Supabase Edge Function | `feed_validate` v18 on project `ilxzpszgirhwxpeocygs` | Active | Keeps the old response field `webhook_skipped: false`; moves partner push delivery off the feed response path via `EdgeRuntime.waitUntil` | MCP confirmed active function/config; focused function tests; `flutter analyze`; `flutter test` |
| 2026-06-07 | Supabase migration | `20260607005751_anchor_decay_after_pet_action.sql` | Applied | Existing clients keep using the same feed action contract; successful feed rewards now anchor hunger decay at feed time | MCP SQL verification; `test/feed_hunger_action_migration_test.dart`; full Flutter checks |
| 2026-06-07 | Supabase migration | `20260607005904_restrict_apply_pet_action_execute.sql` | Applied | Keeps `apply_pet_action` Data API execution authenticated-only | MCP SQL verification; full Flutter checks |

## Tracking Rules

- `pubspec.yaml` records the local app candidate version/build, not live store
  state.
- App Store Connect and storefront lookups are the authority for submitted,
  approved, and public iOS release status.
- This file records the repo's current operational understanding of release
  state, backend deployments, and compatibility decisions.
- `memory-bank/progress.md` should stay compact and point to this file for
  release details.
- `tasks/todo.md` should track active follow-ups, not long release history.
- Git commits are useful evidence, but they are not enough to know what is live.
- After a public app release, create a tag such as `ios/v2.1.0+5` and record it
  in the tables above.

## Update Checklist

Before uploading or submitting an app build:

- Update `pubspec.yaml` and bundled What's New / ASC metadata as needed.
- Add or update the candidate row in "Next Release Candidate".
- Record ASC version IDs, build IDs, upload time, and processing status.
- Record compatibility notes for old app versions.

After App Store/TestFlight state changes:

- Update the candidate status and next action.
- When the build becomes public, move it to "Current Public Release".
- Add the release git tag after the shipped state is verified.

After backend deployment or migration:

- Add a "Backend Deployments" row with date, target, status, compatibility
  note, and verification.
- Update related docs and `memory-bank/progress.md` if current behavior changed.
- Confirm whether app-version gating, force-update config, or old-client
  defaults need to change.
