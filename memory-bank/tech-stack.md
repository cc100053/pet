# Tech Stack

## Core
- Frontend: Flutter (Dart)
- State management: Riverpod
- Animation: Rive (`rive`)
- Local storage/cache: Hive
- Client SDK: `supabase_flutter`
- Env config: `flutter_dotenv`

## Backend & Realtime
- Backend: Supabase (Auth, Postgres, Realtime)
- Server logic: Supabase Edge Functions
- DB logic: Postgres RPC (SQL functions)
- Media storage: Cloudflare R2 (S3 compatible)
- Security: Supabase RLS policies (Row Level Security)

## AI & Media
- Image understanding: Google ML Kit
  - Image Labeling
  - Object Detection
- Label mapping: Client or backend mapping layer for EN -> ZH/JA labels
- Mapping data: `label_mappings` + `quests` seed dictionary
- Color DNA extraction: `palette_generator`
- Image delivery: `cached_network_image`
- Media format: WebP on upload (target ~100KB)

## Notifications & Analytics
- Push notifications: Firebase Cloud Messaging (FCM)
- Analytics: Firebase Analytics

## Tooling
- CI: GitHub Actions (flutter analyze/test)
