# PicPet

## Setup
1. Install Flutter (stable channel recommended).
2. Copy `.env.example` to `.env` and fill in Supabase values.
3. Run dependencies:
   ```sh
   flutter pub get
   ```
4. Launch:
   ```sh
   flutter run
   ```

## Supabase
- Migrations live in `supabase/migrations/`.
- Seed data lives in `supabase/seed.sql`.
- Run the SQL in the Supabase SQL editor before first app launch.
- Run `codex mcp login supabase` to login to Supabase.

## iOS Clean Build
If iOS builds act up or pods are out of sync, run:
```sh
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```
If `pod install` fails with cache permission errors, clear the CocoaPods cache
or run it with elevated permissions.

## Notes
- OAuth providers (Google/Apple) must be configured in Supabase.
- The current UI is a Phase 0 scaffold: auth gate + profile stub.
- Testing helpers: see `docs/testing.md`.

## App Update Prompt (Soft/Hard)

The app checks version early in startup via `ForceUpdateGate`:
- **Hard Update (must update):** `current_version < minimum_required_version`
- **Soft Update (optional):** `current_version < latest_available_version` and current is not below minimum

### Remote config keys (`app_config` table)
Update these keys in Supabase `app_config`:

1. `minimum_required_version` (fallback key: `min_version`)
2. `latest_available_version` (fallback key: `latest_version`)
3. `store_url`
4. `hard_update_message` (optional, fallback key: `force_update_message`)
5. `soft_update_message` (optional)

Each `value` can be either:
- a plain string, e.g. `"1.2.3"`
- a platform map, e.g. `{"ios":"1.2.3","android":"1.2.4","default":"1.2.3"}`

### How to set behavior
- **Force everyone to update now:** set `minimum_required_version` higher than currently installed app versions.
- **Show optional update only:** keep `minimum_required_version` at or below current version, and set `latest_available_version` higher.
- **Disable soft update prompt:** set `latest_available_version` to the same as current app version (or below).

### Debug tool (in app)
- Open drawer -> `Debug Tools`
- Use:
  - `Test Soft Update Prompt`
  - `Test Hard Update Prompt`

These debug actions trigger the same modern dialogs used by production logic, without changing server config.

## HTML pages are now live on Firebase Hosting.

- Privacy Policy (Canonical URL with language switch/auto-detect): https://pet-app-702be.web.app/privacy_policy.html
- Support (Canonical URL with language switch/auto-detect): https://pet-app-702be.web.app/support.html
- Privacy Policy (Traditional Chinese): https://pet-app-702be.web.app/privacy_policy_zh_TW.html
- Support (Traditional Chinese): https://pet-app-702be.web.app/support_zh_TW.html
- Privacy Policy (Japanese): https://pet-app-702be.web.app/privacy_policy_ja.html
- Support (Japanese): https://pet-app-702be.web.app/support_ja.html

## Deploying Web Pages
To update the HTML pages (privacy policy, support), run:
```bash
firebase deploy --only hosting
```
