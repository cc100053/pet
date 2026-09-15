# Tech Stack

Active summary only. See source files, `pubspec.yaml`, and archived snapshots
for exact historical versions. Latest snapshot:
`memory-bank/archive/tech_stack_20260704_pre_compaction.md`.

## Core App
- iOS-only product. Android has never been released: the `android/` tree and its
  Firebase registration exist because Flutter generates them, so the Android
  Crashlytics app holds no data and Android-only plugin behavior is unverified.
  Treat any Android finding as untested, not as a regression.
- Flutter/Dart
- Riverpod state management
- Hive local cache
- `supabase_flutter` client SDK
- `flutter_dotenv` env loading
- `flutter_timezone` timezone lookup

## Media And UI
- Lottie + image assets (GIF/PNG sequence runtime)
- `flutter_animate` micro-animations
- `audioplayers` for local SFX
- `cached_network_image` for remote media
- `palette_generator` for color extraction

## Backend And Platform
- Supabase Auth, Postgres, Realtime, Edge Functions
- Cloudflare R2 for feed/avatar media
- Firebase Cloud Messaging, Analytics, Crashlytics
- RevenueCat for IAP/subscriptions
- Google AdMob 8.x for iOS banner/rewarded ads

## Repo-Specific Notes
- `.fvmrc` pins Flutter `3.44.0` / Dart `3.12.0`; the default/global
  `flutter` binary should match that pin; use bare `flutter ...` for normal
  get/analyze/test/build/run commands.
- Edge Function gateway `verify_jwt=true` expects HS256 Supabase Auth JWTs; old
  `notify_friend` webhook compatibility still relies on `verify_jwt=false` plus
  function-level auth checks.
- Flutter SPM integration is enabled for iOS/macOS. Keep checked-in
  `Package.resolved` files and `ios/Flutter/GeneratedPluginSwiftPackage`
  aligned with Flutter 3.44.0.
