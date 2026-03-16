---
name: firebase-crashlytics-triage
description: Investigate Firebase Crashlytics issues for this PicPet repo through Firebase MCP. Use when the user asks to inspect the top/latest Crashlytics issue, fetch sample events or stack traces, diagnose a crash or non-fatal, compare issue impact by app version/device, or map Crashlytics evidence back to this codebase.
---

# Firebase Crashlytics Triage

Use Firebase MCP first. This repo already targets Firebase project `pet-app-702be`.

## Repo-Specific Defaults
- Prefer the iOS app ID unless the user explicitly asks for Android:
  - iOS: `1:69520994244:ios:d6fc14579fda1a1ca33e91`
  - Android: `1:69520994244:android:c686a4d86c55fa1ca33e91`
- The repo-local MCP wrapper and setup doc are:
  - `scripts/start_firebase_mcp_crashlytics.sh`
  - `docs/firebase_crashlytics_mcp_workflow.md`
- Current repo version lives in `pubspec.yaml`.

## Fast Workflow
1. Call `firebase_get_environment` once and confirm the active Firebase project is `pet-app-702be`.
2. Read only the Firebase guides you need:
   - Always read `firebase://guides/crashlytics/reports` before `crashlytics_get_report`.
   - Read `firebase://guides/crashlytics/issues` when prioritizing.
   - Read `firebase://guides/crashlytics/investigations` when diagnosing root cause.
3. Start with `crashlytics_get_report(report: "topIssues")`.
4. If the user says "top crash", filter `issueErrorTypes: ["FATAL"]`.
5. If the user says "top issue" without specifying crash vs non-fatal, do not force a fatal-only filter.
6. Fetch `topVersions` for the same app ID so you can tell whether the issue affects the newest shipped app version.
7. For the chosen issue:
   - `crashlytics_get_issue`
   - `crashlytics_batch_get_events` for the sample event from the issue
   - `crashlytics_list_events` with `issueId` to get a few recent examples
   - optional: `topAppleDevices`, `topOperatingSystems`, or `topVariants` filtered by `issueId`
8. Map the crashing path into the repo with `rg`, `sed`, `nl`, and when needed `git blame` / `git log`.
9. Before concluding the repo is still broken, check whether the current code already contains the likely fix and whether Crashlytics is dominated by older app versions.
10. If you make code changes, update `memory-bank/*.md` as needed, update `tasks/todo.md`, then run `flutter analyze` and `flutter test`.

## Efficient Investigation Pattern
- Use parallel reads:
  - Crashlytics reports/issues/events in parallel where filters allow it.
  - Repo searches and file reads in parallel.
- Prefer this question order:
  1. Which platform/app ID actually has data?
  2. What is the top issue by event volume?
  3. Does it affect the newest shipped version?
  4. What exact request/frame/error repeats in sample events?
  5. Is the problem current code, old shipped code, or external/transient noise?

## PicPet-Specific Heuristics
- Force-update / app-config noise:
  - Search for `force_update_check`, `AppConfigService`, `minimum_required_version`, `latest_available_version`, `soft_update_message`, and `app_config`.
  - Check whether failures are transient network errors reported from the update gate rather than user-visible crashes.
  - Compare Crashlytics-affected versions with the current `pubspec.yaml` version and recent git history for `lib/services/app_config/`.
- Crash reporting context:
  - Search `lib/services/crash/crash_reporting_service.dart` and `lib/main.dart` for how exceptions are recorded and tagged.
  - Use Crashlytics custom keys like `feature`, `last_action`, `last_error_source`, `route`, and `room_id` to narrow the feature area quickly.
- Unsymbolicated iOS crashes:
  - If stacks are poor, inspect dSYM upload flow before spending time on app logic.
- Chat/Home issues:
  - Search the exact method or file name from the Crashlytics title first, then expand to the owning feature module.

## Output Expectations
- Report:
  - issue ID
  - title/subtitle
  - event count / impacted users
  - affected versions
  - one or more sample event timestamps
  - the key stack path
- Then state:
  - most likely root cause
  - whether it is still present in the current repo or already fixed
  - the exact local files/lines supporting that conclusion
- If the repo already contains the likely fix, say so explicitly and cite the relevant commit or progress note.

## Guardrails
- Do not assume Android has usable Crashlytics data; verify. In this repo it may return `404`.
- Do not infer live behavior from the first historical commit you find; check the current file, then use git history only to explain when the behavior changed.
- Do not claim a fix from one sample event alone when multiple recent events show different error modes; look for the common failing path.
- If there is not enough stack or event detail to identify a plausible root cause, say that instead of guessing.
