# Tech Stack

Active summary only. See source files and `pubspec.yaml` for exact versions.

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
- Google ML Kit image-labeling binaries do not support iOS Simulator on Xcode
  26+; follow the toggle note in the archived/full docs before simulator work.
