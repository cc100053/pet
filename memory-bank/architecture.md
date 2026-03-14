# Architecture

## Current Files
- `memory-bank/game-design-document.md`: GDD master plan and requirements.
- `memory-bank/tech-stack.md`: Technology stack choices and key packages.
- `memory-bank/implementation-plan.md`: Phased delivery plan and milestones.
- `memory-bank/database-schema.md`: Database tables, RLS policies, and RPC signatures.
- `memory-bank/label-mapping.md`: Seed dictionary for ML Kit label mapping and quests.
- `memory-bank/progress.md`: Running log of recent completed steps (see `archive/` for history).
- `supabase/migrations/`: Database schema, policies, and RPC definitions (Note for AI agents: use directory listing tools like `list_directory` or `ls` to view individual migration files as needed; they are not listed here to save tokens).
- `supabase/functions/`: Edge Functions for feed, notifications, and account management.
- `.github/workflows/ci.yml`: Flutter analyze/test workflow.

## App Modules (Phase 0)
Scaffolding is in place; modules will expand as features are implemented.

Implemented:
- `lib/app/`: App bootstrap and theme.
- `lib/features/auth/`: Auth gate and OAuth sign-in view.
- `lib/features/home/`: Signed-in home shell.
  - `lib/features/home/flows/home_onboarding_flow.dart`: Basic onboarding flow state + Step 1 coach card, dual spotlight focus resolution for the existing create-room CTA and header invite-code action, skip/persistence, debug force-show override, and legacy `open_room` state migration to `invite_friend`.
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
    - Chat now supports modern reply/reaction interactions in the active route: all non-system messages expose a long-press action sheet with quick emoji reactions plus ownership-aware `Reply` / `Copy` / moderation actions, any non-system message can also left-swipe into reply with a short immediate trigger (including self-sent messages), replies render as integrated sections inside the existing composer/bubble/card surfaces instead of detached cards, grouped reaction chips render as a tighter under-bubble/card extension with one-reaction-per-user toggle behavior, dark-theme sent text/feed surfaces use a lighter muted teal, and the route adds a left-half right-swipe back gesture that excludes the composer region.
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
  - Successful room furniture/background purchases now emit a structured room `system` chat message from the purchase RPC with the exact purchased item SKU/name context, and the purchase handler best-effort invokes `notify_friend` so those purchase events also send push notifications to the other active room members.
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
- `lib/services/app_config/app_config_service.dart`: Best-effort remote app-config reader for force-update policy. Hard-update thresholds remain Supabase-driven, while iOS latest-version/store-link discovery now also merges live App Store lookup data so soft-update prompts can still appear when backend config is missing or stale.
- `lib/services/app_config/app_store_lookup_service.dart`: Apple lookup client used by `AppConfigService` to resolve the latest iOS App Store version and store URL, with storefront fallbacks and conditional IO/web-safe transport helpers.
- `lib/services/`: Environment loader and shared service setup.
- `lib/services/fcm_service.dart`: FCM token sync + per-device locale sync + iOS foreground fallback; initialization now proceeds for `authorized/provisional/ephemeral` permission states (skips only `denied`).
  - Notification taps now flow through one typed intent pipeline: `onMessageOpenedApp`, `getInitialMessage`, iOS foreground local-notification taps, and an Android `MainActivity` launch-intent bridge all normalize into room-scoped intents (`room_id`, `message_kind` / legacy `message_type`) with dedupe.
  - Intent routing contract: `text` opens the target room chat; `image_feed`, `hunger_alert_*`, and other non-text room notifications switch into the target room and stay on Pet home; stale/missing rooms fall back safely to Room Selection.
- `lib/services/privacy/tracking_consent_service.dart`: Central ATT consent coordinator that waits for app lifecycle `resumed` before requesting authorization.
- `lib/services/label_mapping/`: Label mapping normalization and matching utilities.
- `lib/shared/ui/adaptive_layout.dart`: Shared adaptive width helpers for tablet-safe max-width constraints, plus iOS tablet-display detection to avoid compact-tier misclassification when running in iPhone-compat viewport mode on iPad.
- `lib/shared/ui/keyboard_dismiss_utils.dart`: Shared keyboard-collapse helpers for non-chat inputs (`onTapOutside` unfocus + scroll-surface drag dismiss constant) so text-entry UX now matches chat expectations across dialogs and form screens.
- `lib/shared/ui/full_screen_photo_viewer.dart`: Fullscreen feed/gallery viewer now treats failed remote image loads as a first-class state by supplying `PhotoView` `errorBuilder` fallback UI, so broken debug/test URLs do not crash the viewer route.
- `lib/shared/ui/full_screen_photo_viewer.dart`: Chat-linked fullscreen photos can now show in-viewer `Reply` / `Emoji` actions (Pet Home gallery + chat feed cards only); reply uses the existing `messages.reply_to_message_id` path, emoji uses the existing `message_reactions` path, and local-only optimistic photos keep the actions disabled until a canonical `message_id` exists.
- `lib/services/chat/chat_message_action_service.dart`: Shared chat mutation layer for viewer/chat quick actions, centralizing reply-message insert payloads, reaction toggle writes, and best-effort text-message notification dispatch.
- `lib/shared/ui/cached_network_image_view.dart`: Shared feed/gallery remote-image wrapper now swallows failed aspect-ratio probes and inner `Image` decode errors, leaving the outer `CachedNetworkImage` fallback UI in control when R2 assets return `404`.
- `lib/features/chat/widgets/deterministic_chat_list.dart`: Shared deterministic chat timeline wrapper used by `ChatRoomViewV2`; it preserves manual keyboard-dismiss behavior, forwards per-message long-press actions, and exposes the jump-to-latest visibility threshold used by the restored floating button.
- `lib/features/chat/chat_room_view_v2.dart`: Active chat route now treats post-await controller mutations as route-lifecycle-sensitive work; load/refresh/send/feed callback paths bail once the route is unmounted, and optimistic local feed cards decode file images at card-sized cache dimensions to reduce large-photo memory spikes.
- Home “latest photo” UI: `lib/features/home/home_view.dart` fetches latest feed photos per room (max 10) and stores them as `latest_photos` alongside `latest_photo`; compact summary cards still locally cap their preview at 3.
- Home feed gallery state now uses shared helpers in `lib/features/home/home_gallery_feed_utils.dart` to normalize snapshot hydration, prepend/truncate to 10, and reconcile optimistic local feed images with canonical realtime/uploaded records.
- `lib/features/home/widgets/pet_photo_gallery.dart` now reserves a dedicated single-line caption band with ellipsis overflow and bottom-safe padding so slightly lowered captions do not clip on compact layouts.
- `lib/features/home/widgets/pet_photo_gallery.dart` now carries room/message linkage into fullscreen viewer items and hydrates current-user emoji selection best-effort from `message_reactions`, allowing expanded Pet Home photos to link directly back to the chat message they came from.
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
  - Store purchase pushes now accept client-authenticated `store_purchase` payloads for `system` messages, validate the structured purchase JSON body against the calling buyer, localize the purchased item name by recipient locale, and emit `message_kind=store_purchase` so notification taps stay on Pet Home instead of jumping into chat.
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
