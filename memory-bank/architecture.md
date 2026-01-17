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
- `lib/features/profile/`: Profile read/write stub.
- `lib/features/gallery/memory_calendar_view.dart`: Memory calendar view UI.
- `lib/features/gallery/`: Memory calendar view for feed images.
- `lib/features/store/`: Store UI with coin purchases.
- `lib/services/iap/revenuecat_service.dart`: RevenueCat setup and purchase helpers.
- `lib/services/`: Environment loader and shared service setup.
- `lib/services/label_mapping/`: Label mapping normalization and matching utilities.

Planned:
- `lib/features/rooms/`: Room creation, invite codes, multi-room limits.
- `lib/features/pet/`: Pet state machine (hunger, mood, hygiene, sleep), night mode protection, and growth.
- `lib/features/ads/`: Optional rewarded ads (double coins) and ad gating.
- `lib/features/gallery/`: Calendar view for image memories.
- `lib/features/store/`: Cosmetics, subscription, consumables.
- `lib/shared/`: UI components, theme, utilities.

## Backend (Supabase)
- Auth: Apple/Google sign-in only.
- Postgres: Users, rooms, pets, messages, inventories, config.
- Realtime: Chat and system events.
- RPC (Postgres): Create room, join room, apply pet actions, claim rewards, tick pet state.
- Edge Functions: Feed validation + upload, then write messages/rewards.
- Webhooks: Trigger friend notifications on feed events.
- Storage: Cloudflare R2 for images.
- Security: Enforced RLS policies for room-scoped access.
- Ownership: Triggered owner transfer when the active owner leaves.
- Note: Edge Functions with `verify_jwt` require HS256 JWT signing in Supabase Auth settings (ES256/asymmetric will be rejected).
