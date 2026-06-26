# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshots before compaction:
- `tasks/archive/todo_20260606_pre_compaction.md`
- `tasks/archive/todo_20260621_pre_compaction.md`

## Active Follow-ups
- [ ] Run ASC submission preflight for repo-current iOS `2.2.4+10`, then submit
      ASC version `ca26e644-9448-4ee3-8640-bac50a810057` with attached build
      `cdd2fae2-1dd1-434b-bc25-d0bccaa402fd` for review if approved.
- [ ] Live-verify a real feed on the current build: confirm `feed_validate`
      returns `pet_state`, the satiety bar moves on slow upload, and presigned
      upload logs stay clean.
- [ ] Confirm Supabase secrets/config are set for `delete_account` and
      `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
      8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
      deployment config; current `verify_jwt` behavior is documented but no
      `supabase/config.toml` exists.

## Plan (2026-06-26 Release notes sync 2.2.4)
- [x] Bump local app version from `2.2.3+9` to `2.2.4+10`.
- [x] Add bundled What's New copy for `2.2.4` across maintained app locales.
- [x] Update ASC version-localization `.strings` files for `2.2.4`, preserving
      support/marketing URLs and direct Apple EULA description footers.
- [x] Run `flutter gen-l10n`, metadata terms test, `flutter analyze`, and
      `flutter test`.
- [x] Create/reuse ASC version `2.2.4`, upload localizations, and verify
      read-back.
- [x] Build/upload the `2.2.4+10` IPA, wait for processing, and attach the
      build.
- [x] Update `docs/release_status.md`, `memory-bank/progress.md`, and this task
      review with final ASC IDs/state and verification.

## Review (2026-06-26 Release notes sync 2.2.4)
- Bumped local app version to `2.2.4+10` and added bundled What's New copy for
  en, ja, ko, zh-Hant, and zh.
- Synced ASC version metadata for `2.2.4`; created ASC version
  `ca26e644-9448-4ee3-8640-bac50a810057` and verified localization IDs:
  en-US `90655a05-eac3-4095-9cf4-311b2d25a743`, ja
  `c19ae015-159e-4600-932f-e8c6a0075f06`, ko
  `8358afdd-7044-49b2-812f-90875c20e2d0`, zh-Hant
  `ef690e76-5fc3-4441-8550-88efe478318a`.
- Built and uploaded `build/ios/ipa/PetTomo.ipa`; ASC build/upload ID
  `cdd2fae2-1dd1-434b-bc25-d0bccaa402fd` is `VALID`, encryption `exempt`, and
  attached to version `2.2.4`.
- Verification passed: `flutter gen-l10n`, `flutter test
  test/app_store_metadata_terms_test.dart`, `flutter analyze`, `flutter test`
  (518 passed, 1 skipped because `feed_flow_integration_test.dart` needs
  Supabase test env vars), IPA plist check for version/build/device family/
  orientations/full-screen, ASC localization read-back, ASC build read-back.

## Plan (2026-06-26 Fresh Crashlytics issue)
- [x] Confirm Firebase MCP project/app context and fetch the latest/top iOS
      Crashlytics issue data.
- [x] Pull issue details, sample/recent events, affected versions, and any
      useful device/OS breakdown.
- [x] Map the stack or custom keys back to the current repo and decide whether
      the issue is current-code, old-version, symbolication, or external noise.
- [x] Record the triage result and recommended action.

## Review (2026-06-26 Fresh Crashlytics issue)
- Fresh iOS Crashlytics issue `a5a3f171e28ab8f7076fd99b695bc7eb` first
  appeared on current build `2.2.3 (9)` with 1 event / 1 impacted user at
  `2026-06-25T12:45:59Z`; device was Apple `iPhone18,1` on iOS `26.5.0`.
- Event breadcrumbs showed two feed attempts, a double-reward prompt route, and
  a fatal FlutterError wrapping `PostgrestException(code: 57014, canceling
  statement due to statement timeout)`.
- Root cause was a best-effort post-feed pet-info refresh launched with
  `unawaited(() async { ... }())` but no catch around `_loadPetId` /
  `_loadPetInfo`, allowing transient Supabase timeouts to reach the global
  fatal handler.
- Added best-effort catch guards for the feed-completion and unread/realtime
  pet-info refresh paths, plus a source-level regression test.
- Verification passed: `dart format` touched files, focused
  `flutter test test/features/home/home_multi_pet_query_test.dart`,
  `flutter analyze`, and full `flutter test` (516 passed, 1 skipped because
  `feed_flow_integration_test.dart` needs Supabase test env vars).

## Plan (2026-06-22 Release notes sync 2.2.3)
- [x] Bump local app version from `2.2.2+8` to `2.2.3+9`.
- [x] Add bundled What's New copy for `2.2.3` across maintained app locales.
- [x] Update ASC version-localization `.strings` files for `2.2.3`, preserving
      support/marketing URLs and direct Apple EULA description footers.
- [x] Run `flutter gen-l10n`, metadata terms test, `flutter analyze`, and
      `flutter test`.
- [x] Create/reuse ASC version `2.2.3`, upload localizations, and verify
      read-back.
- [x] Build/upload the `2.2.3+9` IPA, wait for processing, and attach the
      build.
- [x] Update `docs/release_status.md`, `memory-bank/progress.md`, and this task
      review with final ASC IDs/state and verification.

## Review (2026-06-22 Release notes sync 2.2.3)
- Bumped local app version to `2.2.3+9` and added bundled What's New copy for
  en, ja, ko, zh-Hant, and zh.
- Synced ASC version metadata for `2.2.3`; created ASC version
  `4f01124f-01d8-46c9-a5bf-106abb0d9f8d` and verified localization IDs:
  en-US `ce0def34-6bb1-4d5c-98ef-12acc6609d19`, ja
  `3c97e909-6e03-4a70-a714-47594b8c216f`, ko
  `4a5a9624-f173-43d9-8910-0e073bf962f9`, zh-Hant
  `52b6b425-72c7-487e-b066-21625b89fb80`.
- Built and uploaded `build/ios/ipa/PetTomo.ipa`; ASC build/upload ID
  `a2049b54-9297-4083-a5d3-e5729d213148` is `VALID`, encryption `exempt`, and
  attached to version `2.2.3`.
- Verification passed: `flutter gen-l10n`, `flutter test
  test/app_store_metadata_terms_test.dart`, `flutter analyze`, `flutter test`
  (515 passed, 1 skipped because `feed_flow_integration_test.dart` needs
  Supabase test env vars), IPA plist check for version/build/device family/
  orientations/full-screen, ASC localization read-back, ASC build read-back.

## Plan (2026-06-21 Chat route-pop duplicate-key crash)
- [x] Read crash attachment, active memory-bank files, and diagnose guidance.
- [x] Inspect chat route teardown, message list keys, and package chat builders.
- [x] Replace the route loading overlay switcher with a stable-key-safe render
      path.
- [x] Add/adjust regression coverage for the leave-chatroom crash class.
- [x] Run focused chat tests, `flutter analyze`, and `flutter test`.
- [x] Record review/results here before finishing.

## Review (2026-06-21 Chat route-pop duplicate-key crash)
- The user-provided Crashlytics log showed the first failure was
  `Duplicate keys found` inside Flutter's `AnimatedSwitcher` layout stack,
  followed by `_dependents.isEmpty` / "wrong build scope" during route pop.
- Removed the chat route's `AnimatedSwitcher` around the load-more overlay.
  `_ChatHistoryLoadingOverlay` is now inserted only while `_loadingMore`, so
  route teardown cannot retain duplicate null-key switcher children.
- Added coverage:
  `chat_route_pop_stability_test.dart` locks out the risky switcher pattern,
  and `chat_room_view_v2_bounded_window_test.dart` now simulates leaving while
  load-more is still awaiting.
- Verification passed: focused chat tests
  (`chat_route_pop_stability_test.dart`,
  `chat_message_surface_anchor_test.dart`,
  `chat_room_view_v2_bounded_window_test.dart`), `flutter analyze`,
  and `flutter test` (515 passed, 1 skipped: `feed_flow_integration_test.dart`
  needs Supabase test env vars), `git diff --check`, and code-only
  `[DEBUG-...]` cleanup grep.

## Plan (2026-06-21 Chat scroll latest crash)
- [x] Read active memory-bank files, lessons, and relevant local skills.
- [x] Inspect the chat scroll/message-surface implementation and existing
      working-tree changes.
- [x] Tighten the message-surface anchor lifecycle if needed.
- [x] Run focused chat tests, `flutter analyze`, and `flutter test`.
- [x] Record review/results here before finishing.

## Review (2026-06-21 Chat scroll latest crash)
- Replaced per-message lazy-list `GlobalKey` anchors with a lifecycle-managed
  `BuildContext` registry (`_MessageSurfaceAnchor`) for text and feed bubbles.
  The action sheet anchor and reply jump still measure the same surface rects,
  but no longer trigger GlobalKey reparenting during scroll-time window trims.
- Preview clones used by the message action sheet now receive a throwaway
  registry, so they cannot overwrite live list message contexts.
- Added a source-level regression guard:
  `test/features/chat/chat_message_surface_anchor_test.dart`.
- Verification passed: focused chat tests
  (`chat_message_surface_anchor_test.dart`,
  `chat_room_view_v2_bounded_window_test.dart`), `flutter analyze`,
  `flutter test` (513 passed, 1 skipped: `feed_flow_integration_test.dart`
  needs Supabase test env vars), `git diff --check`, and `[DEBUG-...]` cleanup
  grep.

## Review (2026-06-21 Room selection + entry latency)
- Added `features/home/pet_hunger_projection.dart` (pure, unit-tested) mirroring
  server `compute_pet_mood`/`tick_pet_state` decay.
- Room selection: `_fetchRoomPetSummaries` now fetches the decay anchor + main
  `pet_id` and projects health locally; removed the cold-start + periodic
  per-pet `tick_pet_state` storm and the redundant
  `_patchRoomSelectionPetSummaries` double-fetch. Health bars are accurate
  immediately from one fan-out.
- Room entry: cold entry seeds the known `pet_id` (skips `_loadPetId`), the
  artificial entry-loading floor dropped 550ms->150ms, per-room
  `pet_state`/`pet_id` persist in the bootstrap cache so the first entry after
  relaunch is warm, and picker-only decor loads defer to a post-frame callback
  to cut connection contention.
- Behavior caveat (accepted): in-app hunger-alert push from the selection screen
  is now covered by the 20-min server cron instead of firing on every load.
- Verified: `flutter analyze` clean; `flutter test` 510 passing / 1 skipped
  (network integration). New tests: `pet_hunger_projection_test.dart`; updated
  `home_loading_performance_test.dart` for the new invariants.
- Deferred (Tier 3, not done): single `get_room_overview` RPC to collapse the
  1+5 fan-out into one round-trip.

## Plan (2026-06-21 AGENTS + Memory-bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
      `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts before editing.
- [x] Inspect repo-local skills, referenced docs, scripts, Edge Functions, and
      relevant migration references before documenting workflow claims.
- [x] Archive full active memory-bank snapshots under `memory-bank/archive/`.
- [x] Compact active memory-bank files into current-state summaries.
- [x] Update `AGENTS.md` only for newly verified workflow notes or TODOs.
- [x] Run diff/line-count checks plus `flutter analyze` and `flutter test`.
- [x] Add review notes with before/after counts, archive paths, and
      verification results.

## Review (2026-06-21 AGENTS + Memory-bank Optimization)
- Updated `AGENTS.md` with the verified direct App Store Connect API fallback
  for ASC wrapper `-50` failures: use `scripts/asc_version_localization_sync.py`
  with bundled Codex Python.
- Compacted active memory-bank summaries from 364 to 341 lines:
  `architecture.md` 101 -> 97, `database-schema.md` 90 -> 88,
  `progress.md` 101 -> 84, `tech-stack.md` 41 -> 41,
  `ui-ux-guidelines.md` 31 -> 31.
- Archived exact pre-compaction snapshots:
  `memory-bank/archive/architecture_20260621_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260621_pre_compaction.md`,
  `memory-bank/archive/progress_20260621_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260621_pre_compaction.md`,
  `memory-bank/archive/ui_ux_guidelines_20260621_pre_compaction.md`.
- Archived the long task log at
  `tasks/archive/todo_20260621_pre_compaction.md`; active `tasks/todo.md` now
  keeps only current follow-ups, this plan, and this review.
- Verification passed: `wc -l memory-bank/*.md`, `git diff --check`,
  `git diff --stat`, `flutter analyze`, and `flutter test` (493 passed,
  1 skipped). The skipped test was `test/feed_flow_integration_test.dart`
  because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` were unset.
- Working tree also contains a small `lib/features/home/home_view.dart` mounted
  guard that this documentation run did not edit; it was left untouched.
