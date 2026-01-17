# Repository Guidelines

## 1. Core Principles & Workflow
- **Memory Bank**: Read all `.md` files in `memory-bank/` before writing code. Update them after tasks if needed.
- **Quality Checks**: Run `flutter analyze` and `flutter test` after completing any task.
- **External Actions**: Clearly mark manual steps on external websites (e.g., server dashboards, App Store Connect) with `[USER ACTION REQUIRED]`.
- **Supabase**: If adding or editing Supabase-related items, first try implementing with MCP.
- **State Management**: If any in-app action could cause a state transition, the UI should automatically refresh.
- **Naming & Clarifications**: Proactively suggest names for complex sections. Default to user acceptance once given. Explicitly mark transformed fields to prevent data inconsistencies.

## 2. Project Architecture
- `lib/`: Flutter app source (features, services, app entry points).
- `test/`: Flutter tests (e.g., `test/widget_test.dart`).
- `supabase/`: Database migrations, seed data, and edge functions.
  - `migrations/`: SQL migrations in timestamped files.
  - `functions/`: Edge function code (e.g., `feed_validate`).
  - `seed.sql`: Seed data for initial lookup tables.
- `docs/`: Project notes (e.g., `docs/testing.md`).
- **Platforms**: `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` are managed by Flutter.

## 3. Development Standards
### Coding Style
- **Language**: Dart (Flutter).
- **Format**: 2 spaces indentation. Run `dart format` or `flutter format` before PRs.
- **Naming**: `snake_case.dart` for files, `PascalCase` for classes, `lowerCamelCase` for variables/functions.
- **Linting**: Follow `analysis_options.yaml` (includes `flutter_lints`).

### Testing
- **Framework**: `flutter_test`.
- **Files**: Keep as `*_test.dart` under `test/`.
- **Visuals**: Include UI screenshots in PRs when visual changes are made.
- **Helpers**: Temporary in-app test helpers are documented in `docs/testing.md` (remove when done).

### Security & Configuration
- **Secrets**: Copy `.env.example` to `.env` and keep secrets out of git.
- **Auth**: Supabase OAuth providers must be configured before auth flows work.

## 4. Operational Commands
- `flutter pub get`: Install dependencies.
- `flutter run`: Launch app on device/simulator.
- `flutter analyze`: Run static analysis.
- `flutter test`: Run test suite.
- `flutter build <apk|ios|web>`: Build release artifacts.

**Supabase Setup**:
1. Run migrations from `supabase/migrations/` in Supabase SQL editor.
2. Apply `supabase/seed.sql`.
*(See `README.md` for full setup steps)*

## 5. Commit & Pull Request Guidelines
- **Commits**: Concise, imperative summaries (e.g., "Add pet state migration").
- **PRs**: consistent include:
  - Short description.
  - Tests run (`flutter test`, `flutter analyze`, or manual steps).
  - Screenshots for UI changes.
  - Links to relevant issues/tasks.
