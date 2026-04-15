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
- Chat crash hardening now records `chat_room_view_v2` Crashlytics context,
  cleans up realtime channels with `removeChannel(...)`, guards stale callbacks,
  restores composer state on send failures, and avoids invalid image cache sizes.
- Shop purchase feedback uses floating notices; room decor purchases can return
  to Home and trigger the room-decor guidance hint.
- Feed ad double rewards now use the additive `claim_feed_double_reward(...)`
  RPC so the extra reward is tied to a specific feed message. The Home HUD shows
  an x2 total-reward animation, and Chat feed-photo badges update from
  `messages.coins_awarded`.
- Crashlytics triage and release-note sync have repo-local skills:
  `.codex/skills/firebase-crashlytics-triage/SKILL.md` and
  `.codex/skills/release-notes-sync/SKILL.md`.

## Latest Completed Work
- Hardened chat rendering/send/realtime diagnostics against recent Crashlytics
  crash patterns while preserving existing chat, reaction, image, and room-switch
  behavior.
- Added feed double-reward clarity: a live Supabase RPC, Home reward feedback,
  Chat message-update handling, localized candy labels, and focused tests.
- Updated `AGENTS.md` with newly discovered repo workflows and commands:
  local skills, asset bundle verification, Firebase Crashlytics MCP wrapper, and
  ASC localization commands. Verified with `flutter analyze` and `flutter test`.
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
