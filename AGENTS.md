# AGENTS.md (PicPet)

This file is for agentic coding agents working in this repo.

## Core workflow (non-negotiable)
- Read all `memory-bank/*.md` before making non-trivial code changes; update them if your work changes current behavior/decisions.
- After changes, run: `flutter analyze` and `flutter test`.
- When instructions require a website/dashboard step, mark it as `[USER ACTION REQUIRED]`.
- If you touch Supabase schema/functions, prefer the Supabase MCP workflow first (see "Supabase" section).
- UI should refresh automatically after any action that causes a state transition.

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

### Scripts
- Notify webhook test: `scripts/test_notify_friend.sh` (see env vars in `docs/testing.md`).
- Apple client secret (Sign in with Apple):
  - Generate: `node scripts/generate_apple_client_secret.mjs --team-id ... --client-id ... --key-id ... --p8 path/to/AuthKey_XXXX.p8`
  - Never commit `.p8` files or generated secrets.

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
- Migrations: `supabase/migrations/` (run in Supabase SQL editor).
- Seed data: `supabase/seed.sql`.
- Login (for MCP tooling): `codex mcp login supabase`.

### Edge functions
- Functions live in `supabase/functions/`.
- If an edge function uses auth quirks, document it in `docs/testing.md` and keep security tradeoffs explicit.

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

### Supabase patterns
- Prefer explicit `select(...)` column lists for performance-sensitive queries.
- Treat database rows as `Map<String, dynamic>` only at the boundary; map to typed models early when logic grows.
- Realtime: unsubscribe channels when replacing them; avoid duplicate subscriptions.
- RPC calls: include parameter names (`p_*`) explicitly and surface errors to UI.

### Testing style
- Name tests descriptively; keep widget tests deterministic (`pumpAndSettle` with bounded animations).
- For integration tests requiring network/env, use `skip:` with a clear reason (see `test/feed_flow_integration_test.dart`).

### Localization
- Use `AppLocalizations.of(context)!` for user-facing strings.
- Avoid hard-coded strings in UI (tests can assert on visible text, but production UI should be localized).

### Assets
- If adding assets, ensure they are referenced in `pubspec.yaml` (this repo includes `assets/lottie/`).

## PR/commit hygiene
- Do not commit secrets (no `.env`, tokens, credentials).
- Commits: concise, imperative ("Add ...", "Fix ...").
- PRs should include: what changed, why, how tested (`flutter analyze`, `flutter test`), and screenshots for UI changes.
