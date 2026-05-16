# AGENTS.md (PicPet)

This file is for agentic coding agents working in this repo.

## Core workflow (non-negotiable)
- Read all `memory-bank/*.md` (excluding `archive/`) before making non-trivial code changes; update them if your work changes current behavior/decisions.
- Optional: `memory-bank/archive/progress_archive.md` (Archive) contains historical development logs for deeper context when needed.
- After changes, run: `flutter analyze` and `flutter test`.
- When instructions require a website/dashboard step, mark it as `[USER ACTION REQUIRED]`.
- If you touch Supabase schema/functions, prefer the Supabase MCP workflow first (see "Supabase" section).
- UI should refresh automatically after any action that causes a state transition.
- Backward-compatibility rule: If a parameter change can affect behavior of old app versions, ask for user approval before implementing/releasing it.
- Backward-compatibility rule: Before proceeding with such a change, propose alternatives that avoid impacting old versions (e.g., version-gated flags, backward-compatible defaults, new optional params, phased rollout), then wait for approval.
- Keep active `memory-bank/*.md` files compact and current-state focused; move long historical detail or full snapshots to `memory-bank/archive/` so mandatory reads stay cheap.
- For repo-specific workflows, read the matching local skill before editing:
  - Crashlytics triage: `.codex/skills/firebase-crashlytics-triage/SKILL.md`
  - Release notes / App Store Connect metadata: `.codex/skills/release-notes-sync/SKILL.md`
  - Shared room items (backgrounds, furniture, pets): `.codex/skills/shared-item-rollout/SKILL.md`
  - UI/UX implementation or review: `.codex/skills/ui-ux-pro-max/SKILL.md`
- For pet PNG sequence / socket / equipment-preview work, read `docs/godot-png-sequence-socket-workflow.md` before editing `assets/pet_sequences/`, `lib/features/pet/`, or related equipment placement code.

# Agent Workflows & Core Principles

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Prefer Mature Reuse**: If a mature, well-maintained package or library can solve the problem cleanly, use that first. Avoid building generic components from scratch unless there is a clear product-specific reason not to reuse an existing solution.

## Repo layout
- `lib/`: Flutter app (features, shared UI, services, app entry points).
- `test/`: Flutter tests (`*_test.dart`).
- `supabase/`: migrations, seed, edge functions.
- `docs/`: project notes (see `docs/testing.md`).
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`: Flutter-managed platform folders.

## Cursor/Copilot rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found in this repo.

## Commands

### Install / bootstrap
- Install deps: `flutter pub get`
- Run app: `flutter run`

### Lint / typecheck
- Analyzer (required before shipping): `flutter analyze`

### Format
- Format whole repo: `dart format .`
- Format a folder: `dart format lib test`
- Format a single file: `dart format lib/path/to/file.dart`

### Tests
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Run a single test by name: `flutter test test/widget_test.dart --plain-name "Sign-in view renders"`
- Run with more logs: `flutter test -r expanded`

### Localization (gen-l10n)
- ARB files live in `lib/l10n/` (see `l10n.yaml`).
- After editing ARB files, regenerate via build (usually automatic) or run: `flutter gen-l10n`.

### Asset bundle verification
- When adding nested asset folders or debugging missing Flutter assets, run: `flutter build bundle`
- Then verify `build/flutter_assets/AssetManifest.bin` and copied files under `build/flutter_assets/assets/...`.

### Scripts
- Notify webhook test: `scripts/test_notify_friend.sh` (see env vars in `docs/testing.md`).
- Firebase Crashlytics MCP wrapper: `./scripts/start_firebase_mcp_crashlytics.sh --generate-tool-list`
- Apple client secret (Sign in with Apple):
  - Generate and update reminder: `./tool/generate_secret.sh` (Reads `APPLE_*` vars from `.env`)
  - Manual override: `./tool/generate_secret.sh --team-id ... --client-id ... --key-id ... --p8 path/to/AuthKey_XXXX.p8`
  - Raw JWT generator: `node scripts/generate_apple_client_secret.mjs --team-id ... --client-id ... --key-id ... --p8 path/to/AuthKey_XXXX.p8`
  - Reminder system: `.github/workflows/apple_key_reminder.yml` checks `LAST_UPDATED_APPLE_SECRET.txt` monthly and alerts if expiry (< 60 days) is near.
  - Never commit `.p8` files or generated secrets.

### App Store Connect metadata
- List versions: `asc versions list --app 6757725650`
- Upload localized version metadata from `.strings`: `asc localizations upload --version <VERSION_ID> --locale ja --path .asc/version-localizations/ja.strings`
- Verify localized metadata: `asc localizations list --version <VERSION_ID> --output table`

### Build
- Debug builds are usually done via `flutter run`.
- Release builds (examples):
  - Android APK: `flutter build apk --release`
  - iOS (Xcode signing required): `flutter build ios --release`
  - Web: `flutter build web --release`

### iOS clean build (when CocoaPods/Xcode gets flaky)
```sh
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Supabase

### Setup
- Repo target Supabase project: `ilxzpszgirhwxpeocygs` (`https://ilxzpszgirhwxpeocygs.supabase.co`)
- Migrations: `supabase/migrations/` (apply through Supabase MCP per the workflow below).
- Seed data: `supabase/seed.sql`.
- Login (for MCP tooling): `codex mcp login supabase`.

### Edge functions
- Functions live in `supabase/functions/`.
- If an edge function uses auth quirks, document it in `docs/testing.md` and keep security tradeoffs explicit.
- Hunger tick scheduling is server-side: see `docs/hunger_tick_schedule_report.md` for the `pg_cron` job, `hunger_tick_dispatch` behavior, and manual verification SQL.
- Function config/secrets are not centralized in a checked-in `supabase/config.toml`; verify deployed `verify_jwt` settings and required env vars before changing or redeploying functions.
- R2-backed functions (`notify_friend/feed_validate`, `avatar_upload`) require `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, and `R2_PUBLIC_BASE_URL`.
- Push/scheduler functions use `NOTIFY_WEBHOOK_SECRET`; `notify_friend` also needs FCM service-account config, and `hunger_tick_dispatch` uses the vault `hunger_tick_secret` or `HUNGER_TICK_SECRET` fallback.

## Repo-specific workflows

### Shared item rollout
- Use `.codex/skills/shared-item-rollout/SKILL.md` for new shared backgrounds, furniture, or pets.
- Do not expose new shared items to old app versions by default; add version-gated visibility plus old-client render fallbacks.
- For shop-backed decor, keep catalog visibility, purchase RPC predicates, and table RLS policies aligned.
- If notification payloads include item-specific names or assets, update the related Edge Function/native notification handling too.

### Release notes and App Store metadata
- Use `.codex/skills/release-notes-sync/SKILL.md` when adding bundled What's New entries or syncing App Store Connect release notes.
- Keep bundled in-app What's New copy separate from ASC `whatsNew` / `promotionalText`; do not upload shortened in-app bullets as ASC release notes.
- Present localized drafts for approval before applying local release-note files and ASC metadata changes.

### Firebase Crashlytics triage
- Use `.codex/skills/firebase-crashlytics-triage/SKILL.md` and Firebase MCP for crash/non-fatal investigation.
- Repo Firebase project: `pet-app-702be`; prefer the iOS app ID unless Android is explicitly requested.
- Setup and wrapper details live in `docs/firebase_crashlytics_mcp_workflow.md` and `scripts/start_firebase_mcp_crashlytics.sh`.
- Copy `.firebase-mcp.env.example` to the gitignored `.firebase-mcp.env` and point it at the local service-account JSON key before using the wrapper.
- Prefer ADC via the local `.firebase-mcp.env` service-account path over `firebase login` for long-lived MCP access.
- If Crashlytics stacks are unsymbolicated, inspect `ios/scripts/upload_crashlytics_symbols.sh` before debugging app logic.

### Firebase Hosting / GEO marketing
- Static marketing, GEOFlow guides, support/legal pages, invite fallback pages, and app/universal-link files live outside this Flutter app repo in `/Users/fatboy/geo-marketing`.
- Do not recreate `html/`, `.firebase/`, `.firebaserc`, or `firebase.json` here for GEO/hosting work; use `/Users/fatboy/geo-marketing/projects/pettomo`.
- Keep this repo focused on the Flutter app and its runtime/backend integration docs.

### Pet PNG sequence / socket workflow
- Use `docs/godot-png-sequence-socket-workflow.md` for the current Godot-to-Flutter authoring flow.
- Keep GIF asset paths as stable source/fallback ids until explicit cleanup approval; runtime PNG sequence playback should stay wired through `PetAnimationFrames`, `PetAnimationFrameBuilder`, and `PetAnimatedImage`.
- When sequence assets or nested animation folders change, verify them with `flutter build bundle` before treating the rollout as complete.

## Testing notes

### Integration test: feed -> edge -> db -> chat
- File: `test/feed_flow_integration_test.dart`
- Requires env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_TEST_REFRESH_TOKEN`
- Run: `flutter test test/feed_flow_integration_test.dart`

### Webhook test helper
- Script: `scripts/test_notify_friend.sh`
- Requires env vars (see `docs/testing.md`): `NOTIFY_WEBHOOK_URL`, `NOTIFY_WEBHOOK_SECRET`, `RECIPIENT_ID`, `ROOM_ID`, `SENDER_ID`, `MESSAGE_ID`

## Code style guidelines (Dart/Flutter)

### Formatting
- Use `dart format` (2-space indentation enforced by formatter).
- Keep lines readable; let the formatter wrap; avoid manual alignment.

### Imports
- Prefer this ordering with blank lines between groups:
  1) `dart:`
  2) `package:`
  3) relative (`../` or `./`)
- Avoid unused imports; keep imports minimal.

### Naming
- Files: `snake_case.dart`.
- Types (classes/enums/typedefs): `PascalCase`.
- Members/locals/functions: `lowerCamelCase`.
- Constants: `lowerCamelCase` (use `static const` for widget constants); avoid `ALL_CAPS`.

### Types and null-safety
- Prefer explicit types at boundaries: public APIs, service returns, providers, and JSON/parsing.
- Avoid `dynamic` unless you are at a JSON boundary; convert to typed values ASAP.
- Do not suppress type errors (`as any`, `// ignore:`, etc.) unless there is a documented, narrow reason.

### Error handling and logging
- No empty `catch` blocks. If intentionally ignored, use `catch (_) { /* reason */ }`.
- Surface actionable errors to the UI where appropriate (this app often stores a `*_error` string in state).
- Prefer structured error messages; include context (feature, RPC name, ids) but never secrets.

### Flutter UI/state
- Avoid side effects in `build`; do async work in `initState` / callbacks.
- When an action changes state (Supabase write, RPC, purchase, etc.), refresh the relevant UI state automatically.
- Prefer `mounted` checks before calling `setState` after `await`.
- Use `withValues(alpha: ...)` instead of deprecated `withOpacity(...)`.

### Riverpod
- Prefer `ref.watch(...)` in `build` and `ref.read(...)` in callbacks.
- Keep providers pure; do I/O in services/repositories.
- Avoid creating providers in widgets; define them at file/library scope.

### Supabase Postgres Best Practices

> **MCP-First**: Always use Supabase MCP tools for schema/function/policy changes.
> **Execute immediately** — do NOT just write or display SQL; apply it directly via MCP tools (`execute_sql` / `apply_migration`).
> Never ask user to open dashboard or run SQL manually.
> **Current-state rule**: When tracing a DB behavior implemented through migrations/RPCs, never infer the live rule from the first/oldest matching migration. Identify the latest migration actually applied on the target project that rewrites the relevant function/object, and cross-check with the current schema/memory docs before proposing or applying a change.

#### MCP Workflow
- Auth: `codex mcp login supabase` (one-time)
- **If MCP tools fail or are unauthenticated**, run `codex mcp login supabase` directly in the terminal so the user can complete the interactive login, then retry the MCP operation.
- Before any mutating Supabase MCP call (`apply_migration`, `execute_sql`, function deploys), verify the current MCP project URL/ref matches the repo's intended project (`.env`, known project ref, or explicit user confirmation). If they do not match, stop and resolve the target first.
- Use MCP to explore schema, **execute SQL directly** (not just display it), and run migrations
- Save migrations to `supabase/migrations/` with timestamp prefix, commit to Git

#### Schema
- `snake_case` names, plural tables, `uuid` PKs, `timestamptz` for dates
- Add indexes on columns in `WHERE`, `JOIN`, or RLS policies

#### RLS
- Enable on all user tables; use `(select auth.uid())` to cache per query
- Add `TO authenticated` in policies; index policy columns
- Room-scoped: `exists (select 1 from room_members rm where rm.room_id = <table>.room_id and rm.user_id = (select auth.uid()) and rm.is_active)`

#### RPC Functions
- Use `SECURITY INVOKER`; prefix params with `p_`; validate inputs; raise meaningful errors

#### Flutter Queries
- Use explicit `.select('col1, col2')`; convert to typed models at boundary
- Include param names in `.rpc()` calls; surface errors to UI

#### Realtime
- Unsubscribe before re-subscribing; cleanup in `dispose()`

### Testing style
- Name tests descriptively; keep widget tests deterministic (`pumpAndSettle` with bounded animations).
- For integration tests requiring network/env, use `skip:` with a clear reason (see `test/feed_flow_integration_test.dart`).

### Localization
- Use `AppLocalizations.of(context)!` for user-facing strings.
- Avoid hard-coded strings in UI (tests can assert on visible text, but production UI should be localized).

### Assets
- If adding assets, ensure they are referenced in `pubspec.yaml` (this repo includes `assets/lottie/`).

### Juice UI System (Game-style Design)

To maintain the playful, game-like feel of PicPet, follow these UI standards:

- **Bouncy Interactions**: ALWAYS use `JuicyScaleButton` for clickable elements. It triggers the action IMMEDIATELY on release while performing a squish-and-pop animation in the background.
- **Floating Toasts**: Use `showJuiceToast` for blocking alerts, inputs, and confirmations.
    - `JuicePosition.bottom`: Standard feedback/warnings.
    - `JuicePosition.center`: Dialogs, complex inputs (using `body`), and critical confirmations.
    - `JuicePosition.top`: Background task notifications.
- **Non-intrusive Feedback**: Use `showJuiceSnackbar` for success messages or information that should NOT dim the screen or block user interaction. It uses an Overlay and auto-dismisses.
- **Visual Style**:
    - **Borders**: Thick black borders (typically 2px to 3px) for containers and buttons.
    - **Shadows**: Use `BoxShadow` with vertical offsets (depth) and soft transparency (`alpha: 0.15`) instead of solid colored blocks.
    - **Gradients**: Soft gradients (e.g., White to `#FFF7EA`) for card backgrounds.
    - **Typography**: Use `GoogleFonts.mPlusRounded1c` for a friendly, rounded game aesthetic.
- **Validation**: User input in `showJuiceToast` should be validated inside the dialog (using `StatefulBuilder`) to prevent premature closing and provide instant error feedback.

## PR/commit hygiene
- Do not commit secrets (no `.env`, tokens, credentials).
- Commits: concise, imperative ("Add ...", "Fix ...").
- PRs should include: what changed, why, how tested (`flutter analyze`, `flutter test`), and screenshots for UI changes.
