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
  center reset; Save persists the `avatar_view_v2` fragment, while Cancel leaves
  the current avatar unchanged.
- Debug-admin tools include a one-shot Profile Setup onboarding preview for
  testing the new-user name/photo entry point without rewriting persisted
  onboarding completion state.
- Remote Profile photo avatars still support non-destructive framing adjustment
  through the same editor; saving only updates the `avatar_url` fragment.
- Shared room item rollout is version-aware across backgrounds, furniture, and
  pets. Use `.codex/skills/shared-item-rollout/SKILL.md` for future rollouts.
- Shop-backed version-gated decor uses `get_visible_shop_items(p_app_version)`;
  old clients keep the legacy `is_active = true` path. Hidden compatibility-only
  decor uses `metadata.shop_visibility = 'hidden'`.
- Home furniture editing uses tap-to-select, one-finger drag, bottom scale
  controls (`0.8x..2.0x`), atomic transform persistence, and per-instance
  horizontal flip on `1.1.2+` clients.
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
- Chat supports display-only `@Name` mentions for active room members. Messages
  remain plain text; there is no mention notification/schema contract yet.
- Chat crash hardening records `chat_room_view_v2` Crashlytics context, removes
  realtime channels with `removeChannel(...)`, guards stale callbacks, restores
  composer state on send failures, and avoids invalid image cache sizes.
- Chat text sends replace optimistic temp rows with confirmed server rows in one
  timeline update to avoid latest-view shrink/expand jitter.
- Feed uploads run through a durable Hive/Riverpod queue. Capture only enqueues;
  Home owns global completion/failure refresh, and Chat observes local
  optimistic-row reconciliation.
- Feed double rewards use additive `claim_feed_double_reward(...)`; Home shows
  x2 total-reward feedback and Chat updates badges from `messages.coins_awarded`.
- Crash fallback is a dedicated pet-themed recovery screen, not the force-update
  flow. Hard/soft force updates and What's New remain separately sequenced.
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

## Next
- Ensure Edge Function secrets/config are set in Supabase for `delete_account`
  and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Restore or verify `.firebase-mcp.env.example`; Crashlytics MCP docs reference it
  but it is missing in this checkout.
