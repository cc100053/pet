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
