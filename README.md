# PicPet

## Setup
1. Install/use Flutter `3.44.0` stable with Dart `3.12.0` (the default
   `flutter` binary should match `.fvmrc`).
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
- Repo target project: `ilxzpszgirhwxpeocygs`.
- For schema/RPC/policy work, use the Supabase MCP workflow described in
  `AGENTS.md`; do not rely on manually running SQL from README.

## Firebase Crashlytics MCP
- Repo Firebase project: `pet-app-702be`
- Crash triage workflow: [docs/firebase_crashlytics_mcp_workflow.md](/Users/fatboy/pet/docs/firebase_crashlytics_mcp_workflow.md)
- Local MCP wrapper: `./scripts/start_firebase_mcp_crashlytics.sh`
- Local ADC env template: `.firebase-mcp.env.example`

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

## Current Docs
- Agent workflow and repo rules: `AGENTS.md`
- AI collaboration / compatibility workflow: `docs/ai_collaboration_workflow.md`
- Release and backend deployment status: `docs/release_status.md`
- Current architecture/state map: `memory-bank/*.md`
- Testing helpers: `docs/testing.md`
- Feed upload/reward pipeline: `docs/feed_upload_pipeline.md`
- Pet PNG sequence/socket workflow: `docs/godot-png-sequence-socket-workflow.md`
- Hunger tick cron/runbook: `docs/hunger_tick_schedule_report.md`
- Crashlytics MCP setup: `docs/firebase_crashlytics_mcp_workflow.md`
- Label mapping seed notes: `docs/label-mapping.md`

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

## Firebase Hosting / GEO Marketing Pages

PetTomo's live HTML pages are served from Firebase Hosting, but this Flutter app
repo is no longer the website source of truth. Static marketing pages, legal /
support pages, invite fallback pages, `.well-known` files, GEOFlow guides, and
the Firebase Hosting config now live in:

```text
/Users/fatboy/geo-marketing/projects/pettomo
```

Do not recreate or deploy `html/`, `.firebase/`, `.firebaserc`, or
`firebase.json` from this repo. To update or deploy those pages, use the
geo-marketing workspace workflow.

Live pages include:

- Privacy Policy: https://pet-app-702be.web.app/privacy_policy.html
- Terms of Use: https://pet-app-702be.web.app/terms_of_use.html
- Support: https://pet-app-702be.web.app/support.html
- Guides: https://pet-app-702be.web.app/guides/
