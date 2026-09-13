---
name: firebase-crashlytics-triage
description: Triage PicPet Firebase Crashlytics crashes and non-fatals against shipped versions and current code.
---

# Firebase Crashlytics Triage

Use Firebase MCP and confirm project `pet-app-702be` with `firebase_get_environment`.
Default to iOS (`1:69520994244:ios:d6fc14579fda1a1ca33e91`); use Android
(`1:69520994244:android:c686a4d86c55fa1ca33e91`) when requested and verify it has
data rather than assuming a `404` means the issue is absent.

For access/setup problems, use `scripts/start_firebase_mcp_crashlytics.sh` and
[the MCP runbook](../../../docs/firebase_crashlytics_mcp_workflow.md). Prefer its
service-account ADC setup; keep credentials outside version control.

## Evidence

- For a named issue, fetch that issue directly. For rankings, use `topIssues`;
  filter `issueErrorTypes: ["FATAL"]` only when the user asks for crashes.
- Read `firebase://guides/crashlytics/reports` before `crashlytics_get_report`.
  Read the issues or investigations guides when prioritizing or diagnosing.
- Use issue metadata and enough recent sample events to establish impact,
  affected versions, and the repeated failing path. Device/OS/variant reports
  are conditional on the question, not a mandatory report bundle.
- Compare affected versions with verified release state in
  [release_status.md](../../../docs/release_status.md). `pubspec.yaml` identifies
  the local version, not proof of public availability. Check current source
  before using history to date a fix; follow the root code-discovery guidance.
- If stacks are unsymbolicated, inspect
  `ios/scripts/upload_crashlytics_symbols.sh` and the
  [dSYM runbook](../../../docs/ios_app_store_export.md) before diagnosing app logic.
- For update-gate errors, inspect `AppConfigService`, `force_update_check`, and
  `app_config`; distinguish transient network reports from user-visible crashes.
  Reporting context lives in `lib/services/crash/crash_reporting_service.dart`
  and `lib/main.dart`; keys such as `feature`, `last_action`,
  `last_error_source`, `route`, and `room_id` help identify the failing surface.

## Result and scope

Report issue ID/title, impact counts, affected versions, sample timestamps,
key stack path, and source evidence. State whether a defect remains in current
code, was already fixed (cite its commit or note), or is still uncertain.
Do not claim a root cause from one event when recent events show different modes.
Explain whether action is needed, its urgency and remaining uncertainty, and
concrete next steps.

For investigation-only requests, ask before implementing a fix. If a fix is
already requested, complete the authorized change and the root validation
requirements. Changing issue state, adding external notes, deploying, or making
compatibility changes still requires the applicable authorization; triage alone
does not grant it.
