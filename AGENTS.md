# Repository Guidelines

## Important:
# Read all md inside memory-bank before writing any code
# Update all md inside memory-bank after completing any task if needed.
# run flutter analyze after completing any task.
# run flutter test after completing any task.

## Project Structure & Module Organization
- `lib/`: Flutter app source (features, services, app entry points).
- `test/`: Flutter tests (e.g., `test/widget_test.dart`).
- `supabase/`: database migrations, seed data, and edge functions.
  - `supabase/migrations/`: SQL migrations in timestamped files.
  - `supabase/functions/`: edge function code (e.g., `feed_validate`).
  - `supabase/seed.sql`: seed data for initial lookup tables.
- `docs/`: project notes like `docs/testing.md`.
- Platform folders (`android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`) are generated/managed by Flutter.

## Build, Test, and Development Commands
- `flutter pub get`: install Dart/Flutter dependencies.
- `flutter run`: launch the app on a connected device/simulator.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run the test suite in `test/`.
- `flutter build <apk|ios|web>`: build release artifacts when needed.

Supabase setup: run migrations from `supabase/migrations/` in the Supabase SQL editor, then apply `supabase/seed.sql`. See `README.md` for setup steps.

## Coding Style & Naming Conventions
- Language: Dart (Flutter).
- Indentation: 2 spaces, `dart format` or `flutter format` before PRs.
- Naming: files in `snake_case.dart`, classes in `PascalCase`, variables/functions in `lowerCamelCase`.
- Linting: `analysis_options.yaml` includes `flutter_lints`.

## Testing Guidelines
- Framework: `flutter_test`.
- Naming: keep test files as `*_test.dart` under `test/`.
- Include UI screenshots in PRs when visual changes are made.
- Temporary in-app test helpers are documented in `docs/testing.md`; remove them once the related phase is complete.

## Commit & Pull Request Guidelines
- Commit history is minimal; no strict convention yet. Use concise, imperative summaries (e.g., “Add pet state migration”).
- PRs should include: a short description, tests run (`flutter test`, `flutter analyze`, or manual steps), and screenshots for UI changes.
- Link relevant issues/tasks when available.

## Security & Configuration Tips
- Copy `.env.example` to `.env` and keep secrets out of git.
- Supabase OAuth providers must be configured before auth flows work.
