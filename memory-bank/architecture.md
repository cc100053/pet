# Architecture

## Current Files
- `memory-bank/game-design-document.md`: GDD master plan and requirements.
- `memory-bank/tech-stack.md`: Technology stack choices and key packages.
- `memory-bank/implementation-plan.md`: Phased delivery plan and milestones.
- `memory-bank/database-schema.md`: Draft schema + RLS policy notes for Supabase.
- `memory-bank/label-mapping.md`: Seed dictionary for ML Kit label mapping and quests.
- `memory-bank/progress.md`: Running log of completed steps.
- `supabase/migrations/20260101000000_init_schema.sql`: Initial database schema, RLS policies, and RPCs.
- `supabase/migrations/20260101001000_add_leave_room_rpc.sql`: Leave-room RPC with ownership handoff.
- `supabase/migrations/20260101002000_add_regenerate_invite_code_rpc.sql`: Owner-only invite code refresh.
- `supabase/migrations/20260101003000_add_award_quest_reward_rpc.sql`: Daily quest bonus RPC.
- `supabase/migrations/20260101004000_fix_room_members_rls.sql`: RLS recursion fix via helper.
- `supabase/migrations/20260101005000_fix_create_room_rpc.sql`: Create-room invite code fix.
- `supabase/migrations/20260101006000_pet_state_machine.sql`: Pet state machine updates and backfill.
- `supabase/migrations/20260101007000_add_device_tokens.sql`: Device token storage for FCM.
- `supabase/migrations/20260101008000_device_tokens_single_device.sql`: Enforce single-device token per user.
- `supabase/migrations/20260213143000_allow_multi_device_tokens.sql`: Remove per-user token uniqueness to allow concurrent push tokens across multiple devices.
- `supabase/migrations/20260211100000_notification_payload_upgrade.sql`: Add `pets.avatar_url`, `device_tokens.device_locale`, and pet-avatar backfill for push payload shaping.
- `supabase/migrations/20260214223500_add_notification_delivery_logs.sql`: Add push delivery log table for per-token send diagnostics.
- `supabase/migrations/20260127090000_add_pet_exp_and_leveling.sql`: Add pet EXP and feed-based leveling in reward RPC.
- `supabase/functions/feed_validate/index.ts`: Feed validation edge function.
- `supabase/functions/notify_friend/index.ts`: Partner notification webhook (FCM sender).
- `supabase/seed.sql`: Seed data for label mappings and quests.
- `.github/workflows/ci.yml`: Flutter analyze/test workflow.

## App Modules (Phase 0)
Scaffolding is in place; modules will expand as features are implemented.

Implemented:
- `lib/app/`: App bootstrap and theme.
- `lib/features/auth/`: Auth gate and OAuth sign-in view.
- `lib/features/home/`: Signed-in home shell.
- `lib/features/feed/`: Camera capture, ML Kit labeling, and feed upload flow.
  - `lib/features/chat/`: Chat stream with text, feed cards, and system events.
  - `lib/features/profile/`: Profile screen (nickname, avatar presets/upload, account deletion).
  - `lib/features/gallery/memory_calendar_view.dart`: Memory calendar view UI.
  - `lib/features/gallery/`: Memory calendar view for feed images.
  - `lib/features/store/`: Store UI with coin purchases.
  - `lib/features/pet/leveling.dart`: Leveling helpers (EXP progress + level cap).
- `lib/services/iap/revenuecat_service.dart`: RevenueCat setup and purchase helpers.
- `lib/services/review/review_prompt_service.dart`: Feed-milestone driven Apple in-app review trigger service.
- `lib/services/`: Environment loader and shared service setup.
- `lib/services/fcm_service.dart`: FCM token sync + per-device locale sync + iOS foreground fallback; initialization now proceeds for `authorized/provisional/ephemeral` permission states (skips only `denied`).
- `lib/services/label_mapping/`: Label mapping normalization and matching utilities.
- Home “latest photo” UI: `lib/features/home/home_view.dart` fetches latest feed photos per room (max 3) and stores them as `latest_photos` alongside `latest_photo`.
- Latest photo card: `lib/features/home/widgets/home_latest_photo_card.dart` renders 3 separated photo bubbles with subtle X/Y drift and tap-to-preview (fullscreen with zoom).
- Home HUD coin reward animation: `lib/features/home/home_view.dart` emits a monotonic `coinRewardEventId` so repeated rewards retrigger the animation reliably; coin loads are coalesced to avoid racey deltas.

Planned:
- `lib/features/rooms/`: Room creation, invite codes, multi-room limits.
- `lib/features/pet/`: Pet state machine (hunger, mood, hygiene, sleep), night mode protection, growth, and expanded leveling UX.
- `lib/features/ads/`: Optional rewarded ads (double coins) and ad gating.
- `lib/features/gallery/`: Calendar view for image memories.
- `lib/features/store/`: Cosmetics, subscription, consumables.
- `lib/shared/`: UI components, theme, utilities.

## Backend (Supabase)
- Auth: Apple/Google sign-in only.
- Postgres: Users, rooms, pets, messages, inventories, config.
- Realtime: Chat and system events.
- RPC (Postgres): Create room, join room, apply pet actions, claim rewards, tick pet state.
- Edge Functions: Feed validation + upload, avatar upload, and account deletion.
- Webhooks: Trigger friend notifications on feed events.
- Notifications:
  - Android: custom native `FirebaseMessagingService` (`NotificationCompat.MessagingStyle`) using room thread grouping and composed pet-avatar + app-badge large icon.
  - iOS: Notification Service Extension (`PetTomoNotificationServiceExtension`) follows an Apple-default reliable style: fast title/body rewrite + room `thread-id` shaping only (no communication-intent donation and no remote media fetch in the extension), prioritizing consistent delivery/appearance across states.
  - Delivery diagnostics: `notify_friend` persists per-token send outcomes to `public.notification_delivery_logs` and returns non-2xx when all token sends fail.
- Storage: Cloudflare R2 for images.
- Security: Enforced RLS policies for room-scoped access.
- Ownership: Triggered owner transfer when the active owner leaves.
- Note: Edge Functions with `verify_jwt` require HS256 JWT signing in Supabase Auth settings (ES256/asymmetric will be rejected).

### Edge Functions (Repo)
- `supabase/functions/notify_friend/feed_validate/index.ts`: Feed validation + upload + reward logic.
- `supabase/functions/notify_friend/index.ts`: Partner notification webhook (FCM sender).
- Push payload contract (FCM `data`): `room_id`, `message_id`, `message_kind` (with legacy client fallback from `message_type`), `pet_name`, `sender_name`, `pet_type`, `pet_avatar_asset`, `pet_avatar_fallback_url`, `pet_avatar_url`, `image_url`, `caption`, `text_body`, `body_full`, `title_app_name`, `title_full`, and legacy `type`.
- `supabase/functions/avatar_upload/index.ts`: Upload avatar image to R2 and update `profiles.avatar_url`.
- `supabase/functions/delete_account/index.ts`: Delete authenticated user (uses `SUPABASE_SERVICE_ROLE_KEY`).

### Profile Data Notes
- `profiles.avatar_url` supports two forms:
  - Preset: `preset:<id>` (client-rendered gradient/icon)
  - Remote URL: `https://...` (uploaded to R2)
