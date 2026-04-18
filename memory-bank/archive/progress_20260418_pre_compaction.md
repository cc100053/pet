# Progress

This active file keeps only current state and the newest high-signal changes.
Full pre-compaction history is in
`memory-bank/archive/progress_20260411_pre_compaction.md`; older historical logs
remain in `memory-bank/archive/progress_archive.md`.

## Current State
- Profile bootstrap is centralized in `ProfileBootstrapService`; Home and Profile
  use the same missing-profile creation and timezone-sync path.
- Room furniture transform persistence now uses the additive
  `update_room_furniture_transform(...)` RPC with legacy per-field fallback.
- Home furniture editing uses tap-to-select, one-finger drag, and bottom scale
  controls (`0.8x..2.0x`) instead of pinch resizing.
- Placed room furniture can be flipped horizontally per instance on `1.1.2+`
  clients via the additive `update_room_furniture_flip(...)` RPC; older clients
  safely ignore the stored `flip_x` value.
- Shared room item rollout is now version-aware across backgrounds, furniture,
  and pets. Future rollouts should use `.codex/skills/shared-item-rollout/SKILL.md`.
- Shop-backed version-gated backgrounds are visible through
  `get_visible_shop_items(p_app_version)` while old clients keep the legacy
  `is_active = true` catalog path.
- Paid version-gated background purchase now works because purchase RPC predicates
  and `room_backgrounds` insert RLS allow non-hidden version-gated rows.
- Free compatibility-only backgrounds use `metadata.shop_visibility = 'hidden'`
  so they stay out of the user-facing Shop.
- Flutter background assets in nested folders must be declared explicitly in
  `pubspec.yaml`; verify with `flutter build bundle` when changing asset folders.
- Chat uses the V2 route only, with bounded message windows, separate long-press
  and reaction-details surfaces, shared emoji picker without search, and
  keyboard/latest-position regressions covered by tests.
- Chat supports display-only `@Name` mentions for active room members; messages
  remain plain text, known display-name mentions are highlighted, and no mention
  notification/schema contract exists yet.
- Chat crash hardening now records `chat_room_view_v2` Crashlytics context,
  cleans up realtime channels with `removeChannel(...)`, guards stale callbacks,
  restores composer state on send failures, and avoids invalid image cache sizes.
- App crash fallback now uses a dedicated pet-themed recovery screen with restart
  guidance; it no longer reuses force-update copy or opens the App Store.
- Chat text sends replace optimistic temp rows with confirmed server rows in one
  timeline update, avoiding the previous latest-view shrink/expand jitter after
  successful sends.
- Shop purchase feedback uses floating notices; room decor purchases can return
  to Home and trigger the room-decor guidance hint.
- Shop furniture purchases are repeatable and show shared room-owned quantity;
  backgrounds and other one-off cosmetics remain owned/locked.
- Shop supports image-backed bathroom furniture. Toilet (`150` candy), Tub
  (`300` candy), and a 500-candy exchange pack (`50` diamonds) are live
  version-gated catalog rows for app `1.1.2+`.
- Home room furniture inventory hydrates owned item details for inventory IDs
  missing from the visible shop catalog, so purchased version-gated decor stays
  usable in the room backpack. Home/Shop app-version gates prefer the live
  platform version over the cached last-launch version.
- Home and room-scoped Shop refresh shared furniture counts through
  `room_item_inventory_revisions` realtime events instead of subscribing to
  buyer-attributed inventory rows directly.
- Shop diamond-to-candy exchange purchases trigger the same candy-gain SFX and a
  floating `+N` reward animation on the candy balance chip.
- Shop candy-pack SFX now fires from the purchase-success branch when
  `new_coin_balance` increases; the currency chip only owns the visual reward
  animation and avoids overshooting `TweenSequence` input curves.
- iOS AdMob banner `AdWidget`s are disabled in debug by default to avoid Flutter
  `UiKitView` hot-restart/platform-view id collisions (`recreating_view`); set
  `ADMOB_ENABLE_DEBUG_BANNER_VIEWS=true` only when intentionally testing local
  banner rendering. Profile/release banner behavior is unchanged.
- Feed ad double rewards now use the additive `claim_feed_double_reward(...)`
  RPC so the extra reward is tied to a specific feed message. The Home HUD shows
  an x2 total-reward animation, and Chat feed-photo badges update from
  `messages.coins_awarded`.
- Feed photo uploads now run through a durable Hive/Riverpod queue. Camera
  capture only enqueues the job, while Home/Chat observe queue state so pending
  photos, completion refresh, and failed uploads survive route changes and are
  reconciled on app resume/restart.
- Crashlytics triage and release-note sync have repo-local skills:
  `.codex/skills/firebase-crashlytics-triage/SKILL.md` and
  `.codex/skills/release-notes-sync/SKILL.md`.

## Latest Completed Work
- Added the durable feed upload queue and moved compression/`feed_validate`
  invocation out of `FeedCaptureView`. Home now owns global completion handling
  for pet state, coins, gallery, and failure cleanup; Chat observes the same
  queue for optimistic row reconciliation. Verified with focused queue/chat
  tests, `flutter analyze`, and `flutter test`.
- Added per-instance furniture horizontal flip, repeatable furniture buying,
  shared owned/available furniture counts, and room inventory revision realtime
  refresh. Applied the live Supabase migration and verified with
  `flutter gen-l10n`, focused widget tests, `flutter analyze`, and
  `flutter test`.
- Replaced the crash fallback "update required" screen with localized recovery
  copy, a default ghost pet GIF visual, and an acknowledgement action that clears
  the overlay while leaving true hard/soft update flows unchanged.
- Root-caused a local iOS `PlatformException(recreating_view)` stack to embedded
  AdMob banner `UiKitView` creation after debug platform-view id reuse, verified
  it was not present as a current live Crashlytics cluster, and gated banner
  platform views off in debug with an explicit env override.
- Followed up the Shop candy-pack reward feedback: moved SFX to the purchase
  success path, fixed the `TweenSequence` scheduler assertion, expanded focused
  animation coverage, and recorded the rollout lessons in the local shared-item
  skill.
- Fixed post-purchase usability for the new bathroom furniture by merging owned
  inventory item details into Home's furniture catalog, refreshed app-version
  resolution for version gates, and added Shop candy reward feedback for the
  500-candy pack.
- Added version-gated shop catalog rows for Toilet, Tub, and the 500 Candy Pack;
  applied the live Supabase migration, wired PNG furniture rendering in Shop/Home,
  and verified `1.1.1` clients do not see the new SKUs while `1.1.2` clients do.
- Added display-only chat mentions plus smooth optimistic-to-confirmed text send
  replacement, with parsing/widget/send regression coverage.
- Hardened chat rendering/send/realtime diagnostics against recent Crashlytics
  crash patterns while preserving existing chat, reaction, image, and room-switch
  behavior.
- Added feed double-reward clarity: a live Supabase RPC, Home reward feedback,
  Chat message-update handling, localized candy labels, and focused tests.
- Updated `AGENTS.md` with newly discovered repo workflows and commands:
  local skills, asset bundle verification, Firebase Crashlytics MCP wrapper, and
  ASC localization commands. Verified with `flutter analyze` and `flutter test`.
- Prepared and synced `1.1.2` release metadata (Bathroom Decor, Furniture Flip & @Mentions) across
  local ARB, What's New catalog, and App Store Connect localization strings.
- Prepared and synced `1.1.1` release metadata (stability and bugfix focus) across
  local ARB, What's New catalog, and App Store Connect localization strings.
- Compacted active memory-bank docs to reduce mandatory-read token cost while
  preserving long-form snapshots under `memory-bank/archive/`.

## Next
- Ensure Edge Function secrets/config are set in Supabase for `delete_account`
  and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Restore or verify `.firebase-mcp.env.example`; Crashlytics MCP docs reference it
  but it is missing in this checkout.
