# Tech Stack

## Core
- Frontend: Flutter (Dart)
- State management: Riverpod
- Animation: Lottie (`lottie`) + asset images (GIF/PNG)
- UI micro-animations: `flutter_animate` (duration extensions, `moveX`/`moveY`)
- SFX playback: `audioplayers` (one-shot local asset effects)
- Local storage/cache: Hive
- Client SDK: `supabase_flutter`
- Env config: `flutter_dotenv`
- Device timezone lookup: `flutter_timezone`

## Backend & Realtime
- Backend: Supabase (Auth, Postgres, Realtime)
- Server logic: Supabase Edge Functions
- DB logic: Postgres RPC (SQL functions)
- Media storage: Cloudflare R2 (S3 compatible)
- Security: Supabase RLS policies (Row Level Security)
- Auth JWT signing: Edge Functions `verify_jwt` expects HS256 (legacy secret); ES256/asymmetric tokens will 401 at the gateway.

## AI & Media
- Image understanding: Google ML Kit
  - Image Labeling
  - Object Detection
  - ⚠️ **Simulator Limitation**: MLKit binary frameworks don't support iOS Simulator on Xcode 26+
  
  ### MLKit Build Toggle (pubspec.yaml)
  | Build Target | Action | Result |
  |-------------|--------|--------|
  | **Simulator** | Comment out `google_mlkit_image_labeling` | Uses mock labels (Food, Pet food, Bowl...) |
  | **Real Device / TestFlight** | Uncomment `google_mlkit_image_labeling` | Real ML image analysis |
  
  > After toggling, run: `flutter clean && flutter pub get && cd ios && pod install`
  
  See `lib/services/image_labeling/` for implementation details.
  
- Label mapping: Client or backend mapping layer for EN -> ZH/JA labels (based on User Preference)
- Mapping data: `label_mappings` + `quests` seed dictionary
- Color DNA extraction: `palette_generator`
- Image delivery: `cached_network_image`
- Media format: WebP on upload (target ~100KB)

## Notifications & Analytics
- Push notifications: Firebase Cloud Messaging (FCM)
- Analytics: Firebase Analytics
- Ratings prompt: Apple In-App Review (`in_app_review`)
- IAP/Subscriptions: RevenueCat (`purchases_flutter`)
- Ads: Google AdMob (`google_mobile_ads`) for iOS banner + rewarded placements

## Tooling
- CI: GitHub Actions (flutter analyze/test)
