# Tech Stack

Active summary only. See source files, `pubspec.yaml`, and archived snapshots
for exact historical versions. Latest snapshot:
`memory-bank/archive/tech_stack_20260523_pre_compaction.md`.

## Core App
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
- Edge Function gateway `verify_jwt=true` expects HS256 Supabase Auth JWTs; old
  `notify_friend` webhook compatibility still relies on `verify_jwt=false` plus
  function-level auth checks.
- Flutter SPM integration is enabled for iOS/macOS; checked-in
  `Package.resolved` files are part of the Apple dependency flow.
- iOS Runner points Xcode's `FlutterGeneratedPluginSwiftPackage` reference at
  tracked `ios/Flutter/GeneratedPluginSwiftPackage` so Flutter SPM plugins
  resolve with the repo minimum iOS 15.0; Flutter still generates plugin
  symlinks under ignored `ios/Flutter/ephemeral/Packages/.packages/`.
