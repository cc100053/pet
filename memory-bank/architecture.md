# Architecture

Active memory files are intentionally compact because agents must read them
before non-trivial work. Full snapshots: `memory-bank/archive/architecture_20260418_pre_compaction.md`
and older `memory-bank/archive/architecture_20260411_pre_compaction.md`.

## Source Of Truth
- Flutter app and tests: `lib/`, `test/`
- Supabase schema/RPCs/functions: `supabase/migrations/`, `supabase/functions/`
- Longer product/workflow notes: `docs/`
- Current operational state: this file plus `memory-bank/database-schema.md`

For exact behavior, inspect current code, the latest migration that rewrites the
object, and live Supabase state. Memory-bank text is a map, not canonical source.

## App Shape
- `lib/features/home/`: signed-in shell, room switching, pet HUD, decor, unread
  badges, room invite code/link sharing, feed/gallery previews, shared-item
  compatibility prompts, and the shared-pet dress-up overlay/inventory flow.
- `lib/features/chat/`: active route is `ChatRoomViewV2`; it owns bounded
  message windows, Hive cache refresh, realtime, replies/reactions, keyboard
  behavior, and photo/chat actions.
- `lib/features/feed/`: capture plus durable Hive/Riverpod upload queue;
  `FeedCaptureView` enqueues jobs and Home/Chat reconcile results.
- `lib/features/shop/`: backgrounds, furniture, consumables, RevenueCat products,
  floating purchase notices, repeatable furniture purchase, and decor return flow.
- `lib/features/profile/`, `gallery/`, `pet/`, `ads/`: profile/avatar/account
  deletion, Memory photos, version-gated pets/leveling, ATT-aware AdMob.
- `lib/services/` and `lib/shared/`: Supabase/FCM/IAP/config/crash/profile/chat
  services, shared UI, force update, What's New, image wrappers, and debug tools.

## Current Decisions
- Home/Profile share `ProfileBootstrapService` for profile creation and timezone sync.
- Shared room content must be mixed-version safe: version-gate new decor/pets,
  fall back unsupported backgrounds/pets, hide unsupported furniture, and reuse
  the one-shot room compatibility prompt. The pure
  `SharedDecorCompatibility` Module owns shared app-version support, render
  eligibility, and prompt-state/key decisions used by Shop items, PetCatalog,
  Home background/furniture rendering, and room compatibility prompts.
- Pet dress-up uses widget-layer equipment overlays on top of rendered pet
  animation frames. Equipment ownership and equip state are room-scoped:
  Shop buys equipment through room equipment purchase RPCs,
  Home loads available equipment through `get_room_equipment_inventory`, and
  equipped slots are fetched with both `p_pet_id` and `p_room_id`.
  Socket coordinates live in Dart (`PetSocketCatalog`), equipment assets
  and optional per-pet/per-state fit overrides live in `EquipmentCatalog`, and shared
  placement math keeps Home overlays and the admin fit tool aligned without
  legacy previews while production rendering moves to PNG sequences. App pet
  visuals now resolve source GIF asset ids through `PetAnimationFrames` and
  `PetAnimationFrameBuilder`, so Home, room selection, chat menu avatars,
  inventory previews, and pet selection render bundled PNG frame sequences for
  every current pet/state. GIFs remain bundled as source/fallback assets during
  the migration and should not be deleted until the follow-up cleanup is
  explicitly approved. Overlays can sample optional per-pet/per-state motion
  tracks derived from source PNG frames so equipment anchors follow sprite drift
  inside a fixed canvas. Motion lookup is slot-aware, so a pet can mix manually
  authored tracks for calibrated slots with static sockets for unfinished slots
  during rollout. Tracks and frame sequences sample by cumulative per-frame
  duration through the shared `PetAnimationTimeline` Module, matching variable
  GIF frame timing where needed. Equipment catalog sizes can use source-image
  aspect-preserving sizing, and equipment definitions can override anchor/size
  by pet and animation state so Godot-authored straw-hat previews map to
  Flutter without `BoxFit.contain` letterbox padding shifting the anchor.
- Shop/Home furniture supports metadata PNG assets with emoji fallback. Shared
  counts come from `get_room_furniture_inventory`; buyer-attributed
  `room_item_inventories` remains for compatibility.
- Shop economy RPC names, params, and result parsing are concentrated behind
  `EconomyPurchaseAdapter`; typed purchase-result and IAP grant balance deltas
  are applied by `ShopEconomyState`. `ShopPurchaseNotifier` owns best-effort
  `notify_friend` delivery for store purchase messages. `ShopView` still owns
  UI notices, analytics, IAP orchestration, and when notification delivery is
  requested.
- Furniture transform persistence prefers additive RPCs:
  `update_room_furniture_transform(...)` and `update_room_furniture_flip(...)`,
  with legacy transform fallbacks where needed.
- Chat opens on the latest 20 messages, loads older pages in 20-message chunks,
  caps visible history at 80, buffers realtime while browsing history, and stores
  only the newest 20 canonical messages per room in Hive.
- Chat listens to `messages` updates so feed double-reward badge changes refresh
  in place. Reactions use separate long-press action and reaction-detail surfaces.
- Feed uploads are queue-owned; Home owns global completion/failure side effects,
  while Chat observes queue events only for local optimistic row reconciliation.
- Force-update and What's New are sequenced: hard updates block What's New, then
  eligible upgraded versions show bundled release notes once.
- Room invites use reusable active codes for normal share/copy. Flutter builds
  hosted links at `https://pet-app-702be.web.app/invite?invite_code=...`, handles
  app/universal links through `AppInviteLinkService`, persists pending codes for
  signed-out opens, and joins with live `join_room_by_code` after Home bootstrap.
  Avoid using a bare `code` query param in invite links because Supabase Auth
  treats it as a PKCE callback parameter on mobile.

## Backend And Platform
- Supabase Auth supports Apple/Google. Postgres is room-scoped with strict RLS;
  use RPCs for gameplay, economy, ownership, and shared-room invariants.
- Cloudflare R2 stores feed/avatar media. Realtime powers chat/system events,
  reaction refresh, and shared furniture inventory revision signals.
- Edge Functions:
  `notify_friend/feed_validate`, `notify_friend`, `hunger_tick_dispatch`,
  `avatar_upload`, and `delete_account`.
- Edge Functions with gateway `verify_jwt=true` require HS256 Supabase Auth JWTs;
  ES256/asymmetric tokens are rejected at the gateway. `notify_friend` currently
  uses `verify_jwt=false` with function-level auth checks.
- Android notifications use native room-thread `MessagingStyle`; iOS uses
  `PetTomoNotificationServiceExtension`. `ios/Runner/AppDelegate.swift` also
  bridges native iOS memory warnings into Flutter so the existing
  Crashlytics/memory diagnostics pipeline can record low-memory context before a
  possible jetsam kill. Crashlytics dSYM upload runs through
  `ios/scripts/upload_crashlytics_symbols.sh`.
- Firebase Hosting serves the invite fallback page plus `.well-known`
  association files for App Links/Universal Links. Production release still
  needs verified platform entitlement/signing setup.
- ML Kit binary frameworks do not support iOS Simulator on Xcode 26+; see
  `memory-bank/tech-stack.md` for the pubspec toggle.

## Read More
- Exact DB/RPC/policy shape: Supabase MCP plus `supabase/migrations/`.
- Historical architecture: `memory-bank/archive/architecture_20260418_pre_compaction.md`.
- Older logs: `memory-bank/archive/progress_archive.md`.
