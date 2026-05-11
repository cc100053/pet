# Firebase Crashlytics MCP Workflow

This repo's Crashlytics workflow targets Firebase project `pet-app-702be`.
Firebase Hosting config now lives in `/Users/fatboy/geo-marketing`, so do not
expect `firebase.json` or `.firebaserc` in this Flutter app repo. The preferred
setup for long-lived Crashlytics MCP access is **ADC via a service account**,
not `firebase login`.

## What this gives you
- Ask Codex for the latest crashes or non-fatals in Firebase Crashlytics
- Pull sample events, stack traces, notes, and report summaries through Firebase MCP
- Triage against the local codebase, patch the app, and verify with `flutter analyze` and `flutter test`

## One-time setup

### 1. Create a service account for Crashlytics MCP
[USER ACTION REQUIRED]

Create a service account in the Google Cloud project behind Firebase project `pet-app-702be`, then create a JSON key for it and store the key **outside the repo**.

Recommended least-privilege role:
- `Firebase Crashlytics Viewer` for read-only triage

If you want the agent to add notes or update issue state from MCP, use a stronger role only if needed:
- `Firebase Crashlytics Admin`

Suggested local key path:

```text
~/.config/pet/firebase-crashlytics-sa.json
```

### 2. Create the local ADC env file
[USER ACTION REQUIRED]

Copy the example file and set the real JSON key path:

```sh
cp .firebase-mcp.env.example .firebase-mcp.env
```

Then edit `.firebase-mcp.env` so it exports the real service-account key:

```sh
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/pet/firebase-crashlytics-sa.json"
```

This file is gitignored.

### 3. Add the repo wrapper as a Codex MCP server
[USER ACTION REQUIRED]

Edit `~/.codex/config.toml` and add this block:

```toml
[mcp_servers.firebase-pet]
command = "/Users/fatboy/pet/scripts/start_firebase_mcp_crashlytics.sh"
```

Notes:
- The wrapper loads `.firebase-mcp.env` if present, validates `GOOGLE_APPLICATION_CREDENTIALS`, and then starts `firebase mcp --dir /Users/fatboy/pet --only core,crashlytics`.
- This avoids depending on expiring `firebase login` user credentials.

### 4. Restart Codex
[USER ACTION REQUIRED]

Restart the Codex app/session after editing `~/.codex/config.toml` so the new MCP server is loaded.

## Local verification

You can verify the Firebase MCP tool surface from the terminal without touching Codex config:

```sh
./scripts/start_firebase_mcp_crashlytics.sh --generate-tool-list
```

To verify the ADC file path before using the MCP server:

```sh
test -f "$(grep GOOGLE_APPLICATION_CREDENTIALS .firebase-mcp.env | cut -d'"' -f2)"
```

You should see Firebase core tools plus Crashlytics tools such as:
- `crashlytics_get_issue`
- `crashlytics_list_events`
- `crashlytics_batch_get_events`
- `crashlytics_get_report`

## Recommended Codex workflow

Once the MCP server is loaded, use prompts like:

```text
Use Firebase Crashlytics MCP to find the top open iOS crash and non-fatal issues for the latest app version, fetch sample events and stack traces, identify the most likely root cause in this repo, implement the fix, and run flutter analyze plus flutter test.
```

```text
Use Firebase Crashlytics MCP to inspect issue <ISSUE_ID>, summarize impact, fetch the latest 3 events, map the stack trace to this Flutter/iOS codebase, and propose or implement a fix.
```

## Suggested triage sequence for the agent

1. Read the latest Crashlytics report summary with `crashlytics_get_report`.
2. Pick the highest-impact open issue for the current iOS version.
3. Fetch issue metadata with `crashlytics_get_issue`.
4. Pull recent sample events and stack traces with `crashlytics_list_events` or `crashlytics_batch_get_events`.
5. Correlate the failing frames with local Dart, iOS, or plugin code.
6. Patch the code in this repo.
7. Run `flutter analyze` and `flutter test`.
8. Optionally add a Crashlytics note back onto the issue with the diagnosis or fix summary.

## Boundary conditions

- Firebase MCP is excellent for interactive triage, issue drill-down, and AI-assisted fixing.
- For scheduled reporting across many issues/versions, add Crashlytics BigQuery export later; MCP alone is not the best batch analytics layer.
- If Crashlytics data is unsymbolicated, fix dSYM upload first; MCP can retrieve the issue, but the stack trace quality will still be limited.
- Keep the service-account JSON outside the repo and rotate it if access changes.
