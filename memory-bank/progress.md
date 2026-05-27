# Progress

Active progress stays current-state focused. Full snapshots live in
`memory-bank/archive/`; latest:
`memory-bank/archive/progress_20260523_pre_compaction.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; avatar uploads
  use the deployed `avatar_upload` Edge Function and shared framing editor.
- Shared room content is mixed-version aware. New backgrounds, furniture, and
  pets need version-gated visibility, old-client fallback, and the existing
  compatibility prompt. Use `.codex/skills/shared-item-rollout/SKILL.md`.
- Multi-pet v2.0.0 is live with a backward-compatible split: `pets` remains
  one row per room for legacy `.maybeSingle()` clients, while additional pets
  live in `room_extra_pets` and surface through v2.0.0 room-pet RPCs.
  `rooms.main_pet_id` identifies the canonical main pet and
  `set_room_main_pet` swaps rows across the two pet tables.
- Hunger, mood, level, and exp are room-shared through `room_pet_state`.
  `tick_pet_state` and `apply_pet_action` both mirror into it, and triggers
  keep `pets`/`room_extra_pets` level and exp aligned. New pets inherit the
  room's current level.
- Naming model B is the current contract: `rooms.name` mirrors the main pet's
  name, while each pet keeps its own name. There is no separate room rename
  flow for multi-pet rooms.
- Home renders every room pet with independent wandering, dragging, tap name
  tags, shared food convergence, and matching walk/sleep/stay animation state.
  Pets may overlap freely.
- Pet equipment is room-scoped and per-pet. The equipment panel has a persistent
  target selector for multi-pet rooms, each pet renders its own gear across Home
  and picker surfaces, and room equipment inventory is quantity-aware so one
  owned copy can only be worn by one pet at a time.
- Debug admins can freeze hunger decay per room through
  `set_room_hunger_decay_paused(...)`; the override is expiring, room-scoped,
  advances `last_decay_at` while frozen, and parks the server schedule until
  expiry.
- Room-selection previews use each room's `main_pet_id` when loading equipped
  gear, so previews track main-pet switches rather than mixing all pets' gear.
- Pet tickets are v2.0.0-gated, cost 150 diamonds, cap rooms at 5 pets, allow
  duplicate pet types, and use `purchase_and_use_pet_ticket(...)` for atomic
  buy-and-add flows.
- Chat is on `ChatRoomViewV2`; feed uploads run through the durable queue.
  Sender photo recall is implemented as a soft-delete of `image_feed`, leaving
  reward/feeding state intact and removing the photo from Home/gallery views.
  Chat history scrolling is memory-tuned: the reversed list keeps a small
  `cacheExtent` (600) so few full-size image bubbles stay decoded at once, and
  the global image cache is capped at 64MB/80 entries (`lib/main.dart`).
  Scrolling back to the newest end while in history mode (or with buffered live
  messages) auto-rejoins the latest window via `shouldRejoinLatestOnScroll` in
  `_handleChatScroll`, so users no longer need the jump-to-latest button to see
  recent messages.
- Image decodes are size-bounded to curb OOM: chat bubbles, Home food photo
  (`photo_food.dart`), and the feed capture preview (`feed_capture_view.dart`)
  all pass cacheWidth/cacheHeight. Known remaining risk: the full-screen
  `photo_view` gallery decodes full-res across live pages (left as-is to
  preserve zoom quality).
- `ForceUpdateGate` shows the What's New sheet at most once per app session:
  `_checkForUpdate` is re-entrancy guarded and `_whatsNewShownThisSession`
  blocks a duplicate sheet when `AppLifecycleState.resumed` re-fires before
  `markShown` persists (e.g. an ATT/push prompt right after a fresh update).
- Home first paint is latency-tuned: key room/profile reads run concurrently,
  warm room switches skip the loading overlay, and hunger alert dispatch is
  unawaited after the state read.
- Shop purchases and IAP grants flow through `EconomyPurchaseAdapter` and
  `ShopEconomyState`; store purchase messages use best-effort `notify_friend`.
- Pet rendering prefers bundled PNG sequences while preserving GIF asset ids.
  Godot remains the socket/equipment authoring path.
- GEOFlow, multilingual SEO/GEO guides, Firebase Hosting static pages, invite
  fallbacks, app/universal-link files, and related automation live in
  `/Users/fatboy/geo-marketing`, not this Flutter app repo.
- App Store metadata for auto-renewable subscriptions must retain the direct
  Apple Standard EULA footer in every `.asc/version-localizations/*.strings`
  description; `test/app_store_metadata_terms_test.dart` locks this.

## Workflow Notes
- Run `flutter build bundle` after adding nested asset folders or new PNG
  sequence directories, then confirm the bundle contains the assets.
- Read `docs/godot-png-sequence-socket-workflow.md` before editing pet PNG
  sequences, sockets, equipment preview metadata, or related placement code.
- Use `docs/firebase_crashlytics_mcp_workflow.md` plus
  `scripts/start_firebase_mcp_crashlytics.sh` for Crashlytics MCP setup/triage;
  prefer ADC via `.firebase-mcp.env`, not `firebase login`.
- If Crashlytics stacks are unsymbolicated, inspect
  `ios/scripts/upload_crashlytics_symbols.sh` before app-side debugging.
- Use `docs/ios_app_store_export.md` and
  `scripts/export_ios_appstore_no_apple_symbols.sh` when uploading an existing
  iOS archive while avoiding Apple's immediate symbol-upload warning.
- For GEOFlow/SEO/Firebase Hosting work, use `/Users/fatboy/geo-marketing`;
  PetTomo-specific publishing lives under `projects/pettomo`.
- Edge Function `verify_jwt` settings are not in a checked-in
  `supabase/config.toml`; verify live config before redeploying.

## Open Items
- Ensure Supabase secrets/config are set for `delete_account` and
  `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs.

## Read More
- Historical snapshots: `memory-bank/archive/`
- Current architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
