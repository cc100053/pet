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
- `supabase/migrations/20260216233000_rebalance_mood_decay_and_feed_gain.sql`: Remove `low` mood tier, retune hunger decay (`mid=3`, `sad=4`), and change feed gain to `+20` once per 10-minute burst.
- `supabase/migrations/20260217000000_add_pet_hunger_alerts.sql`: Add one-time hunger alert state (`30/10`), emit hunger system messages on threshold crossings, and reset alert flags when hunger recovers above thresholds.
- `supabase/migrations/20260221103000_add_hunger_alert_50.sql`: Extend hunger alert pipeline with `50` threshold state/message metadata and reset logic so alerts fire once per recovery cycle for `50/30/10`.
- `supabase/migrations/20260217113000_add_unread_tracking_and_badge_rpc.sql`: Add `room_members.last_read_at`, create `mark_room_read` RPC, and add unread-total RPC used for APNs app-icon badge counts.
- `supabase/migrations/20260217143000_add_unread_counts_per_room_rpc.sql`: Add `get_unread_message_counts_for_user` RPC so clients can restore per-room unread badges from server state after app relaunch.
- `supabase/migrations/20260223123000_secure_unread_rpc_user_scope.sql`: Restrict unread RPCs so authenticated callers can query only their own unread state.
- `supabase/migrations/20260223150000_align_unread_rpc_with_block_visibility.sql`: Align unread RPC sender filtering with block-enforced message visibility so badges do not count hidden messages.
- `supabase/migrations/20260225015727_enable_pg_cron_pg_net_for_hunger_tick_dispatch.sql`: Enable `pg_cron` + `pg_net` for server-driven hunger dispatch scheduling.
- `supabase/migrations/20260225015942_add_get_hunger_tick_secret_rpc.sql`: Add vault-backed RPC to fetch scheduler auth secret.
- `supabase/migrations/20260225020133_add_tick_pet_state_as_system_rpc.sql`: Add service-role tick wrapper to run `tick_pet_state` without end-user session context.
- `supabase/migrations/20260225020844_add_hunger_tick_dispatch_cron_schedule.sql`: Create/refresh `hunger_tick_dispatch_every_10m` cron job and seed vault secret if missing.
- `supabase/migrations/20260225023510_add_pet_hunger_tick_schedule_and_20m_cron.sql`: Add due-time hunger tick schedule table/triggers/functions and switch scheduler to `hunger_tick_dispatch_every_20m` (`*/20`).
- `supabase/migrations/20260225024022_add_pet_hunger_tick_schedule_room_id_index.sql`: Add `pet_hunger_tick_schedule.room_id` index to cover FK checks and room-scoped queries.
- `supabase/migrations/20260305231000_add_multi_invite_codes_and_member_generation.sql`: Add room-scoped multi invite-code storage (`room_invite_codes`), member-capable invite-code generation/list/revoke RPCs, and backward-compatible updates to `create_room`, `regenerate_invite_code`, and `join_room_by_code`.
- `supabase/migrations/20260308110504_add_message_reply_support.sql`: Add nullable `messages.reply_to_message_id` self-reference + index so chat can persist quoted replies without breaking older clients.
- `supabase/migrations/20260217100000_room_scoped_furniture_inventory.sql`: Add room-scoped furniture inventory + purchase RPCs and enforce room-scoped quantity checks in furniture placement.
- `supabase/migrations/20260218113000_harden_join_room_membership_ordering.sql`: Preserve original `room_members.joined_at` on invite rejoin reactivation to prevent lock-order manipulation.
- `supabase/migrations/20260218170000_sync_room_timezone_on_owner_transfer.sql`: Sync `rooms.timezone` to the promoted owner's profile timezone when room ownership transfers.
- `supabase/migrations/20260127090000_add_pet_exp_and_leveling.sql`: Add pet EXP and feed-based leveling in reward RPC.
- `supabase/functions/feed_validate/index.ts`: Feed validation edge function.
- `supabase/functions/notify_friend/index.ts`: Partner notification webhook (FCM sender).
- `supabase/functions/hunger_tick_dispatch/index.ts`: Server-side pet ticker + hunger-alert push dispatcher for closed-app delivery.
- `supabase/seed.sql`: Seed data for label mappings and quests.
- `docs/crash_reporting.md`: Crash reporting validation + alerting runbook.
- `docs/onboarding_basic_tutorial_spec.md`: Lightweight first-login onboarding spec draft (create pet, open room, invite friend, feed); current shipped flow has Step 2 (open room onboarding) removed.
- `ios/scripts/upload_crashlytics_symbols.sh`: iOS release dSYM upload script for Crashlytics symbolication.
- `.github/workflows/ci.yml`: Flutter analyze/test workflow.

## App Modules (Phase 0)
Scaffolding is in place; modules will expand as features are implemented.

Implemented:
- `lib/app/`: App bootstrap and theme.
- `lib/features/auth/`: Auth gate and OAuth sign-in view.
- `lib/features/home/`: Signed-in home shell.
  - `lib/features/home/flows/home_onboarding_flow.dart`: Basic onboarding flow state + Step 1 coach card, spotlight focus resolution (create CTA), skip/persistence, debug force-show override, and legacy `open_room` state migration to `invite_friend`.
  - `lib/features/home/providers/home_unread_counts_provider.dart`: Riverpod unread-count state for Home/Room Selection badges and app-icon badge sync.
  - `lib/features/home/providers/home_rooms_provider.dart`: Riverpod state for Home rooms list + current room + selected room in room selection.
  - `lib/features/home/providers/home_pet_state_provider.dart`: Riverpod pet-state snapshot for Home (pet id, current state payload, ready/departed flags).
  - `lib/features/home/providers/home_currency_provider.dart`: Riverpod currency snapshot for Home (coins, diamonds, coin reward amount/event id).
- `lib/features/feed/`: Camera capture, ML Kit labeling, and feed upload flow.
  - Feed uploads now precompute client-side WebP compression right after image pick and reuse it on send; profile selection early-exits on target/cap-safe size to keep reward feedback responsive.
  - On successful `feed_validate` response, Home applies `coins_awarded` immediately in local HUD state, then runs a background profile reconciliation fetch.
  - Home HUD now shows a localized reward-pending indicator during feed reward resolution (server-authoritative coin update remains unchanged).
  - `lib/features/chat/`: Chat stream with text, feed cards, and system events.
    - `lib/features/chat/chat_room_view_v2.dart`: Sole chat-room route used by Home. It keeps Supabase fetch/realtime/cache/moderation/feed-send logic in app code while owning a deterministic timeline, the custom composer shell, reply-jump behavior, reactions, reply previews, and keyboard-dismiss/back-swipe interactions.
    - Chat now supports modern reply/reaction interactions in the active route: all non-system messages expose a long-press action sheet with quick emoji reactions plus ownership-aware `Reply` / `Copy` / moderation actions, any non-system message can also left-swipe into reply with a short immediate trigger (including self-sent messages), replies render as integrated sections inside the existing composer/bubble/card surfaces instead of detached cards, grouped reaction chips render under bubbles/cards with one-reaction-per-user toggle behavior, dark-theme sent text/feed surfaces use a lighter muted teal, and the route adds a left-half right-swipe back gesture that excludes the composer region.
    - `lib/features/chat/adapters/pet_chat_message_adapter.dart`: Maps app `ChatMessage` domain rows into `flutter_chat_core` message types consumed by the active V2 route.
    - Legacy `ChatRoomView` / `ChatMessageList` / `ChatMessageTile` files were removed after the V2 rollout, so there is no longer a parallel legacy chat-room stack in the repo.
  - `lib/features/profile/`: Profile screen (nickname, avatar presets/upload, account deletion).
  - `lib/features/gallery/memory_calendar_view.dart`: Memory calendar view UI.
  - `lib/features/gallery/`: Memory calendar view for feed images.
    - `lib/features/gallery/models/memory_feed.dart`: Memory feed model extracted from calendar view.
    - `lib/features/gallery/services/memory_calendar_data_service.dart`: Calendar data service for blocked users/month feeds/latest feeds/profile hydration.
    - `lib/features/gallery/widgets/`: Calendar subwidgets (`calendar_header.dart`, `calendar_weekday_strip.dart`, `calendar_month_navigator.dart`, `calendar_month_card.dart`, `calendar_day_cell.dart`, `calendar_day_bubble.dart`).
- `lib/features/store/`: Store UI with coin purchases.
  - `lib/features/store/models/store_item.dart`: Store domain model with localized naming/pricing helpers.
  - `lib/features/store/services/store_iap_service.dart`: Extracted Store IAP loading/purchase/restore logic.
  - `lib/features/store/services/store_purchase_handler.dart`: Extracted Store candy/diamond purchase handlers.
  - `lib/features/store/widgets/store_departed_pet_selector.dart`: Extracted departed-pet selection/confirmation dialogs for return-letter purchase.
  - `lib/features/store/widgets/store_item_cards.dart`: Extracted Store card builders for IAP/items/themes.
- `lib/features/ads/`: iOS AdMob rewarded + banner ad UI components and service wiring.
  - `lib/services/ads/admob_startup_service.dart`: ATT-aware lazy AdMob startup gate shared by rewarded/banner placements; denied ATT falls back to non-personalized ad requests instead of blocking ad load.
  - `lib/features/pet/leveling.dart`: Leveling helpers (EXP progress + level cap).
- `lib/services/iap/revenuecat_service.dart`: RevenueCat setup and purchase helpers.
- `lib/services/review/review_prompt_service.dart`: Feed-milestone driven Apple in-app review trigger service.
- `lib/services/crash/crash_reporting_service.dart`: Central Crashlytics wrapper (fatal/non-fatal reporting, custom keys, breadcrumb logging, and navigator route observer).
- `lib/services/audio/app_sfx.dart`: Shared one-shot gameplay SFX player for Home interactions; eating and coin/candy reward sounds now respect the device silent-mode setting.
- `lib/services/profile/profile_cache_service.dart`: Shared profile summary cache/service used by Home, Chat, and Memory Calendar sender resolution.
- `lib/services/profile/device_timezone_service.dart`: Device timezone lookup service used to keep `profiles.timezone` aligned with host location.
- `lib/services/`: Environment loader and shared service setup.
- `lib/services/fcm_service.dart`: FCM token sync + per-device locale sync + iOS foreground fallback; initialization now proceeds for `authorized/provisional/ephemeral` permission states (skips only `denied`).
  - Notification taps now flow through one typed intent pipeline: `onMessageOpenedApp`, `getInitialMessage`, iOS foreground local-notification taps, and an Android `MainActivity` launch-intent bridge all normalize into room-scoped intents (`room_id`, `message_kind` / legacy `message_type`) with dedupe.
  - Intent routing contract: `text` opens the target room chat; `image_feed`, `hunger_alert_*`, and other non-text room notifications switch into the target room and stay on Pet home; stale/missing rooms fall back safely to Room Selection.
- `lib/services/privacy/tracking_consent_service.dart`: Central ATT consent coordinator that waits for app lifecycle `resumed` before requesting authorization.
- `lib/services/label_mapping/`: Label mapping normalization and matching utilities.
- `lib/shared/ui/adaptive_layout.dart`: Shared adaptive width helpers for tablet-safe max-width constraints, plus iOS tablet-display detection to avoid compact-tier misclassification when running in iPhone-compat viewport mode on iPad.
- `lib/features/chat/widgets/deterministic_chat_list.dart`: Shared deterministic chat timeline wrapper used by `ChatRoomViewV2`; it preserves manual keyboard-dismiss behavior, forwards per-message long-press actions, and exposes the jump-to-latest visibility threshold used by the restored floating button.
- Home “latest photo” UI: `lib/features/home/home_view.dart` fetches latest feed photos per room (max 3) and stores them as `latest_photos` alongside `latest_photo`.
- Latest photo card: `lib/features/home/widgets/home_latest_photo_card.dart` renders 3 separated photo bubbles with subtle X/Y drift and tap-to-preview (fullscreen with zoom).
- Home HUD coin reward animation: `lib/features/home/home_view.dart` emits a monotonic `coinRewardEventId` so repeated rewards retrigger the animation reliably; coin loads are coalesced to avoid racey deltas.

Planned:
- `lib/features/rooms/`: Room creation, invite codes, multi-room limits.
- `lib/features/pet/`: Pet state machine (hunger, mood, hygiene, sleep), night mode protection, growth, and expanded leveling UX.
- `lib/features/gallery/`: Calendar view for image memories.
- `lib/features/store/`: Cosmetics, subscription, consumables.
- `lib/shared/`: UI components, theme, utilities.

## Backend (Supabase)
- Auth: Apple/Google sign-in only.
- Postgres: Users, rooms, pets, messages, inventories, config.
- Realtime: Chat and system events.
- RPC (Postgres): Create room, join room, apply pet actions, claim rewards, tick pet state.
- Room invites: `room_invite_codes` supports up to 3 active room codes; members can generate additional codes via RPC while legacy clients continue using `rooms.invite_code` as the current primary code.
- Edge Functions: Feed validation + upload, avatar upload, account deletion, and scheduled hunger-alert dispatch.
- Webhooks: Trigger friend notifications on feed events.
- Notifications:
  - Android: custom native `FirebaseMessagingService` (`NotificationCompat.MessagingStyle`) using room thread grouping and composed pet-avatar + app-badge large icon.
    - Tap routing now forwards `room_id`, `message_id`, and `message_kind` into Flutter through `MainActivity` (`pet/notification_taps`) for both cold-start and `onNewIntent` resume flows.
  - iOS: Notification Service Extension (`PetTomoNotificationServiceExtension`) follows an Apple-default reliable style: fast title/body rewrite + room `thread-id` shaping only (no communication-intent donation and no remote media fetch in the extension), prioritizing consistent delivery/appearance across states.
  - Delivery diagnostics: `notify_friend` persists per-token send outcomes to `public.notification_delivery_logs` and returns non-2xx when all token sends fail.
  - Hunger alert dispatch supports server-driven runs via `hunger_tick_dispatch`, which ticks pets and invokes `notify_friend` webhook delivery without requiring any active client session.
- Storage: Cloudflare R2 for images.
- Security: Enforced RLS policies for room-scoped access.
- Unread badge RPCs (`get_unread_message_total_for_user`, `get_unread_message_counts_for_user`) now apply the same bilateral block filtering as message reads.
- Pet night-mode protection is evaluated against a room-scoped timezone (`rooms.timezone`), keeping behavior consistent for members in different districts/timezones.
- Ownership: Triggered owner transfer when the active owner leaves.
- Note: Edge Functions with `verify_jwt` require HS256 JWT signing in Supabase Auth settings (ES256/asymmetric will be rejected).

### Edge Functions (Repo)
- `supabase/functions/notify_friend/feed_validate/index.ts`: Feed validation + upload + reward logic.
  - Upload requests now enforce a `10MB` decoded-image cap and strict image MIME allow-list (`jpeg/png/webp/heic/heif`) before any R2 upload, message insert, or notification trigger.
- `supabase/functions/notify_friend/index.ts`: Partner notification webhook (FCM sender).
  - Feed sends now trigger notifications by directly invoking this function from `feed_validate` with the user auth token (no separate webhook URL dependency).
  - Webhook-mode requests are accepted with a configured `NOTIFY_WEBHOOK_SECRET` via either `Authorization: Bearer <secret>` or `X-Notify-Webhook-Secret` header; webhook payload message content is canonicalized from DB and recipients are constrained to active room members.
  - Current deployment runs with `verify_jwt=false`; function-level auth checks enforce JWT-backed user mode for client calls and secret-backed webhook mode for scheduler calls.
- `supabase/functions/hunger_tick_dispatch/index.ts`: Scheduled hunger-alert dispatcher.
  - Requires `HUNGER_TICK_SECRET` (or vault `hunger_tick_secret` / `NOTIFY_WEBHOOK_SECRET` fallback) for invocation auth and uses service-role RPC ticks + webhook-mode `notify_friend` dispatch.
  - Pulls only due pets from `public.pet_hunger_tick_schedule` (`next_check_at <= now`) instead of scanning all pets, then uses `tick_pet_state_as_system` to preserve existing pet-state logic.
  - Due-time schedule state is maintained by DB trigger/RPC path (`refresh_pet_hunger_tick_schedule`) and cron currently runs every 20 minutes.
- Push payload contract (FCM `data`): `room_id`, `message_id`, `message_kind` (with legacy client fallback from `message_type`), `pet_name`, `sender_name`, `pet_type`, `pet_avatar_asset`, `pet_avatar_fallback_url`, `pet_avatar_url`, `image_url`, `caption`, `text_body`, `body_full`, `title_app_name`, `title_full`, and legacy `type`.
- `supabase/functions/avatar_upload/index.ts`: Upload avatar image to R2 and update `profiles.avatar_url`.
  - Avatar uploads now enforce the same `10MB` decoded-image cap and MIME allow-list before R2/profile updates.
- `supabase/functions/delete_account/index.ts`: Delete authenticated user (uses `SUPABASE_SERVICE_ROLE_KEY`).

### Profile Data Notes
- `profiles.avatar_url` supports two forms:
  - Preset: `preset:<id>` (client-rendered gradient/icon)
  - Remote URL: `https://...` (uploaded to R2)
