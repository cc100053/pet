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
- `device_info_plus` / `package_info_plus` for device and app-version meta on
  support messages

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
- Resend (email) for support-inbox alerts from `support_notify`
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
- `ios/Flutter/GeneratedPluginSwiftPackage/Package.swift` hardcodes each SPM
  plugin's resolved version in its `../ephemeral/Packages/.packages/<name>-<version>`
  path. `flutter pub get`/`flutter build` do NOT rewrite this checked-in file
  when a plugin version bumps in `pubspec.yaml` — only `.flutter-plugins-dependencies`
  and the ephemeral packages dir get regenerated, so the path goes stale and
  `xcodebuild` fails with "package ... cannot be accessed". After bumping any
  iOS-native plugin version (e.g. `purchases_flutter`), manually update its
  path(s) in this file to match the new resolved version.
