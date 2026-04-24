# Progress

Active progress stays current-state focused. Full snapshots:
`memory-bank/archive/progress_20260418_pre_compaction.md`,
`memory-bank/archive/progress_20260411_pre_compaction.md`, and older
`memory-bank/archive/progress_archive.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; Home/Profile
  share missing-profile creation and timezone sync.
- Profile photo avatar uploads now use the deployed `avatar_upload` Edge
  Function/R2 path with local UI error handling and shared adjust-before-upload
  framing; they no longer write directly to a Supabase Storage bucket.
- Profile and new-user onboarding avatar uploads share the full-screen fixed
  circle framing editor. It supports bounded drag, pinch zoom, slider zoom, and
  center reset, with a dimmed image preview outside the crop circle; Save
  persists the `avatar_view_v2` fragment, while Cancel leaves the current avatar
  unchanged.
- Debug-admin tools include a one-shot Profile Setup onboarding preview for
  testing the new-user name/photo entry point without rewriting persisted
  onboarding completion state, plus the legacy local Dress-up Fit Tool. Future
  equipment socket/anchor/size calibration is expected to happen in the Godot
  socket authoring tool; the Flutter debug fit tool remains in place for now but
  is no longer the production calibration path.
- Remote Profile photo avatars still support non-destructive framing adjustment
  through the same editor; saving only updates the `avatar_url` fragment.
- Shared room item rollout is version-aware across backgrounds, furniture, and
  pets. Use `.codex/skills/shared-item-rollout/SKILL.md` for future rollouts.
- Pet dress-up MVP is wired end-to-end for app `1.3.0`: the live
  `pet_equipment` table/RPCs + `equip_straw_hat` catalog row exist on the repo
  Supabase project, Home renders equipment overlays on the shared pet and status
  avatar, the room inventory panel has an Equipment tab with preview/equip/remove
  actions, and Shop exposes version-gated equipment items alongside furniture.
  Overlay placement now uses a shared helper with optional local per-pet fit
  overrides so production rendering and the admin preview use identical math.
  Ghost idle equipment anchors now also follow motion data instead of staying
  pinned to a fixed socket; the current production trial applies the Godot
  socket export for ghost `head`, `body`, and `back` base sockets, with the
  `head` slot using a slot-specific motion track while currently static
  `body` / `back` slots use the exported base positions.
  The app-wide pet renderer now uses bundled PNG frame sequences for every
  current pet/state instead of playing the GIFs directly. Home, room selection,
  chat menu avatars, inventory equipment previews, and pet selection all go
  through `PetAnimationFrameBuilder` / `PetAnimatedImage`; GIF paths remain as
  stable source ids and fallback assets until the later cleanup. The straw hat
  catalog mirrors the Godot equipment preview export and uses source-aspect
  sizing, so the app computes anchors against the same rendered item bounds as
  the Godot preview. The Godot socket tool can store per-frame `durationMs`
  values and preview playback with those durations; Flutter PNG sequences and
  socket motion tracks sample by the same cumulative timing for
  variable-duration animations.
- Room invite sharing now reuses the current active room code by default, keeps
  copy-code, adds system share-sheet links, stores pending invite codes from
  app/universal links for signed-out users, and joins through live
  `join_room_by_code` after Home bootstrap. Invite URLs use `invite_code` rather
  than `code` to avoid Supabase Auth PKCE callback collisions.
- Shop-backed version-gated decor uses `get_visible_shop_items(p_app_version)`;
  old clients keep the legacy `is_active = true` path. Hidden compatibility-only
  decor uses `metadata.shop_visibility = 'hidden'`.
- Home furniture editing uses tap-to-select, one-finger drag, bottom scale
  controls (`0.8x..2.0x`), atomic transform persistence, and per-instance
  horizontal flip on `1.1.2+` clients.
- Full-screen photo viewing now waits for clear vertical intent before
  swipe-to-dismiss engages, so left/right gallery paging tolerates small
  up/down drift instead of nudging the image vertically.
- Shop furniture purchases are repeatable, show shared room-owned quantity, and
  refresh Home/Shop counts via `room_item_inventory_revisions` realtime signals.
- Image-backed Toilet (`150` candy), Tub (`300` candy), and 500-candy exchange
  pack (`50` diamonds) are live version-gated rows for app `1.1.2+`.
- Home room furniture inventory merges owned item details missing from visible
  Shop catalog responses, then applies app-version support checks before
  rendering or placing.
- Shop candy exchange feedback triggers SFX from the purchase-success branch and
  uses non-overshooting `TweenSequence` input curves for reward animation.
- Chat uses only `ChatRoomViewV2`: latest 20 open, 20-message older pages,
  80-message visible cap, newest-20 Hive cache, deterministic timeline,
  separate long-press/reaction-detail surfaces, and keyboard/latest regressions
  covered by tests.
- Chat long-press message actions use a Telegram-like focused overlay with
  animated background blur, soft vignette scrim, calmer motion, and measured
  rail/preview/action-card stacking so the options card avoids overlapping the
  selected message preview.
- Chat supports display-only `@Name` mentions for active room members. Messages
  remain plain text; there is no mention notification/schema contract yet.
- Chat senders can edit/delete their own non-deleted text messages anytime.
  Deletes are soft placeholders: `messages.body` is cleared, reactions/actions
  are hidden, and replies render the localized deleted placeholder.
- Chat crash hardening records `chat_room_view_v2` Crashlytics context, removes
  realtime channels with `removeChannel(...)`, guards stale callbacks, restores
  composer state on send failures, and avoids invalid image cache sizes.
- iOS multi-room diagnostics now bridge native memory warnings into Flutter,
  record Crashlytics room/index context on room switches, trim the image cache
  at high-water marks during room changes, and cap the global image cache at
  `120` entries / `128 MB` to reduce low-RAM room-entry crashes.
- Chat text sends replace optimistic temp rows with confirmed server rows in one
  timeline update to avoid latest-view shrink/expand jitter.
- Feed uploads run through a durable Hive/Riverpod queue. Capture only enqueues;
  Home owns global completion/failure refresh, and Chat observes local
  optimistic-row reconciliation.
- Feed double rewards use additive `claim_feed_double_reward(...)`; Home shows
  x2 total-reward feedback and Chat updates badges from `messages.coins_awarded`.
- Crash fallback is a dedicated pet-themed recovery screen, not the force-update
  flow. Hard/soft force updates and What's New remain separately sequenced;
  soft update uses explicit Update/Later actions, and What's New is persisted
  only after the user dismisses it.
- iOS AdMob banner `AdWidget`s are disabled in debug by default to avoid
  `UiKitView` hot-restart/platform-view id collisions; use
  `ADMOB_ENABLE_DEBUG_BANNER_VIEWS=true` only for intentional local banner tests.
- Repo-local workflow skills exist for Crashlytics triage, release-note sync, and
  shared item rollout under `.codex/skills/`.

## Recent High-Signal Work
- Fixed the v1.1.3 Crashlytics fatal Profile avatar upload path by removing the
  direct `app_assets` Supabase Storage write, routing through `avatar_upload`,
  handling failures locally, and bumping the app to `1.1.4+1`.
- Unified Profile and onboarding avatar photo uploads so both pick an image,
  open the shared framing editor immediately, and only upload after Save.
- Added a debug drawer action to open the new-user Profile Setup onboarding
  entry point directly for avatar upload/framing QA.
- Restored the Profile `Adjust current photo` action after the UI refactor left
  it as a no-op; the editor now writes framing metadata without re-uploading.
- Reworked the shared avatar framing editor to use the same transform math as
  final avatar rendering, preventing blank crop gaps and preview/display drift.
- Durable feed upload queue shipped and moved compression/`feed_validate` out of
  `FeedCaptureView`; verified with focused queue/chat tests, `flutter analyze`,
  and `flutter test`.
- Furniture flip, repeatable furniture buying, shared owned/available counts, and
  realtime inventory revision refresh shipped with live Supabase migration.
- Crash fallback copy/UX was split from force-update behavior.
- Local iOS `PlatformException(recreating_view)` was traced to debug AdMob banner
  platform views and gated off in debug.
- `1.1.2` release metadata work covers Bathroom Decor, Furniture Flip, and
  @Mentions across bundled What's New and App Store Connect strings.
- Active memory-bank files were compacted again on 2026-04-18; snapshots are in
  `memory-bank/archive/*_20260418_pre_compaction.md`.
- Chat message edit/delete shipped with live Supabase migration
  `20260419123000_add_chat_message_edit_delete.sql`, localized actions and
  placeholders, optimistic update/revert behavior, cache/realtime support, and
  focused service/model/widget coverage.
- Refined the chat long-press overlay back toward the original Telegram-like
  feel by restoring animated blur-focus background treatment and smoother
  motion for the action surfaces, with focused regression coverage.
- Fixed a follow-up chat long-press layout regression where the options card
  could cover taller selected-message previews by switching the overlay to
  measured child stacking and reserving option-card space in the vertical
  placement clamp.
- Added memory-pressure hardening for the hard-to-reproduce multi-room crash:
  `SystemMemoryPressureService` now records native iOS memory warnings into
  Crashlytics + `MemoryDiagnosticsService`, room switches stamp room-count/index
  custom keys and opportunistically trim the Flutter image cache at high-water
  marks, and startup lowers the image-cache cap to `120` entries / `128 MB`.
- Synced the repo to the already-applied live dress-up backend migration
  `20260422150216_add_pet_equipment`, including the `purchase_item_with_coins`
  version-gated catalog fix, and added focused overlay/socket/catalog tests plus
  the missing local `l10n` generation step.
- Trial-applied the first manually authored ghost `head` socket from the Krita
  JSON template, added slot-aware idle motion lookup so only calibrated slots
  consume authored drift, and kept the Dress-up Fit Tool preview aligned with
  production overlay behavior.
- Applied the first Godot socket-authoring export
  (`ghost_stay_sockets.json`) to `PetSocketCatalog`, updating ghost idle
  head/body/back base anchors and replacing the head idle delta track with the
  Godot-authored frame sequence.
- Migrated pet display surfaces from direct GIF playback to bundled PNG
  sequences for ghost, cat, fish, and tiger stay/sleep/walk animations while
  retaining GIF assets as migration fallbacks.
- Matched the straw hat app catalog to the Godot equipment preview metadata
  (`anchor: 0.5,0.55`, width ratio `0.8`) and added aspect-preserving equipment
  sizing to avoid preview/app anchor drift from mismatched image boxes.
- Added variable-duration frame support to the socket workflow: Godot exports
  `frameDurationsMs` plus per-frame `durationMs`, and Flutter frame/motion
  helpers now use cumulative timing rather than only fixed frame holds.
- Invite link share flow shipped with live Supabase migration
  `20260420113000_add_reusable_room_invite_code_rpc.sql`, Firebase Hosting
  `/invite` fallback, App Links/Universal Links config, localized share copy,
  and invite-link service tests. Firebase Hosting and iOS Associated Domains
  were enabled on 2026-04-20. Remaining release setup: add the Android
  production SHA-256 to `assetlinks.json`.

## Next
- Ensure Edge Function secrets/config are set in Supabase for `delete_account`
  and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Restore or verify `.firebase-mcp.env.example`; Crashlytics MCP docs reference it
  but it is missing in this checkout.
