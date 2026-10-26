# TODO

## Risk-based verification workflow (2026-10-26)
- [x] Route implementation work from AGENTS.md to the testing decision table;
      choose and execute behavior checks proactively while retaining the code gate.
- [x] Document the simulator procedure, isolated-data fallback, concrete proof,
      normal-app restoration and remaining device/live-service boundaries.
- [x] Walk through documentation, logic, simulator-file-lifetime and hardware
      branches; validate links, heading anchors, referenced command targets and
      whitespace. Documentation-only, so no Flutter or simulator rerun needed.

## Feed photo lifetime follow-up (2026-10-26)
- [x] Defer terminal-job acknowledgement while Home's feeding animation uses
      its photo; release on completion, replacement, room switch or disposal.
- [x] Sweep only unreferenced owned photos and abandoned staging files once at
      repository startup, before accepting new photo writes; retain all saved jobs.
- [x] Regress both reported failures and cleanup/write ordering; the animation
      regression runs the real Home terminal handlers through five scenarios.
      Updated the feed runbook. Final-tree format: 366 files unchanged; analysis
      clean; 805 tests passed / 1 live integration skip. Documentation links and
      whitespace pass.
- [ ] Verify a fast upload keeps the photo through every bite, plus interrupted
      enqueue/restart on an iOS device `[USER ACTION REQUIRED]`; ships next build.

## Durable feed photos (2026-10-25)
- [x] Persist queue-owned photos before enqueue; retain them across retries and
      restarts, rebase paths after iOS container moves, and clean up on acknowledgement.
- [x] Preserve old Hive job fields and reconcile server success before reading
      old picker files; regress enqueue failures, retry, restoration and cleanup.
- [x] Update the feed runbook. Final-tree format: 365 files unchanged; analysis
      clean; 802 tests passed / 1 live integration skip. Seven new regressions
      cover durable photos and safe cleanup; documentation links/whitespace pass.
- [ ] Verify picker → interrupted upload → app restart on an iOS device
      `[USER ACTION REQUIRED]`; monitor Crashlytics
      `20256d54958a5fffbd2cc26adef3b81e` after the next release.

## Review prompt refinement (2026-10-24)
- [x] Lower first eligibility to five feeds on two observed local feed days;
      retain existing counters/dates and allow recurring requests after 90 days.
- [x] Wait for feed/reward feedback and a visible, resumed, keyboard-free screen;
      count each completion once across Home and Chat.
- [x] Add a localized Profile review link; remove automatic store fallback and
      report native API calls as requests, not confirmed displays.
- [x] Regress eligibility, upgrade continuity, timing, duplicate events, manual
      navigation and localized Profile link/error handling; update architecture.
      Final-tree format: 365 files / 0 changes; analysis clean; 794 tests passed /
      1 live integration skip. Documentation links and whitespace passed.
- [ ] Check native dialog timing after feed/reward feedback and the manual
      review page on a shipping iOS build `[USER ACTION REQUIRED]`. Apple owns
      actual dialog display; assess rating/review volume after release/adoption
      using the measurement guidance in `memory-bank/architecture.md`.

## Maintenance implementation (2026-10-22)
- [x] Add a minimal pinned-SDK CI with fake offline configuration and validate
      it from a clean checkout with no `.fvm` or production config. Format and
      analysis and the full suite passed; all 3 final opt-in cases also passed
      separately with fake config.
- [x] Make live feed integration explicitly opt-in so routine checks cannot
      mutate services merely because credentials exist in the environment.
- [x] Refresh the two recent Crashlytics issues and record delivery/verification
      status without closing issues or changing production.
- [ ] Firebase alert subscriptions / Missing dSYMs dashboard checks remain
      `[USER ACTION REQUIRED]`: MCP exposes issue data, not those settings, and
      the available browser requires Google sign-in. Latest Apple secret
      reminder workflow completed successfully (run `36818778995`); email
      delivery and future scheduling were not verified.
- [x] Update canonical testing/maintenance guidance. Final-tree format:
      364 files / 0 changes, analysis clean, 780 tests passed / 1 live skip;
      all tracked documentation links and workflow YAML syntax passed.
- [x] Implementation `0a5c349` and portable-link fix `322c367` committed/pushed.
      [Remote CI run 39727064053](https://github.com/cc100053/pet/actions/runs/39727064053)
      passed bootstrap, locked dependencies, format, analysis, full tests and
      all tracked documentation links. Machine-specific internal links are now
      relative; external Godot examples use that project's root as their base.
- [ ] Require `verify` as a merge check if a mandatory gate is desired
      `[USER ACTION REQUIRED]`; main has neither branch protection nor an
      active branch ruleset. CI currently reports failures without blocking
      direct pushes.

## Maintenance research (2026-10-22)
- [x] Map existing architecture, local gates, regression tests and open release
      verification against current source and repository history.
- [x] Record prioritized prevention, detection and recovery recommendations
      in [the research note](../docs/project_maintenance_research.md), with
      repository and official-source evidence.
- [x] Validate documentation links/instructions and whitespace; documentation
      only, so no Flutter checks. Runtime/service changes remain proposals.

## Feed picker loading timing (2026-10-22)
- [x] Reproduce Loading appearing before native photo selection finishes.
- [x] Keep the preview during selection; defer feedback until returned-photo
      read/decode exceeds 250ms, retaining duplicate-pick/send guards.
- [x] Regress slow/fast preview, cancellation and disposal (12 focused tests).
      Final-tree format: 364 files unchanged; analysis and document links clean;
      777 tests passed / 1 live integration skip.
- [ ] Check native gallery/camera return and iCloud photos on the next iOS build
      `[USER ACTION REQUIRED]`; automated tests mock the native picker.

## Furniture inventory recovery (2026-10-21)
- [x] Regress Crashlytics `b2f9f845e3bf777517ec16c582ab4bfa` handling and
      protect pending placements from removal/stale reloads.
- [x] Localize inventory exhaustion, reconcile the captured room after failure,
      and document the client-only behavior without changing RPC contracts.
- [x] Final-tree format: 364 files unchanged; analysis and document links clean;
      775 tests passed / 1 live integration skip. Five delayed-response scenarios
      fail against the prior source and pass with the fix. Mocked the existing
      auth test's missing native preferences channel; no new dependency.
- [ ] Verify furniture placement/removal on the next iOS build
      `[USER ACTION REQUIRED]`; live-monitor the issue after release.
      Read-only refresh 2026-10-22: issue remains OPEN / NON_FATAL;
      `topVariants` returned 1 event / 1 affected user for
      2026-10-15T00:00:00Z–2026-10-22T23:59:59Z. Latest sample:
      2026-10-21T11:49:15Z, `5.0.0 (31)`,
      `_persistFurniturePlacement` → `ui_error/unexpected` for
      `insufficient_inventory`. Fix `2508637` is in source; no verified build
      containing it was established. No issue state or backend changes.

## Auth token recovery (2026-10-21)
- [x] Handle auth stream errors in AuthGate, Home and FCM; retain SDK session
      cleanup/retry behavior and show the existing localized re-auth prompt.
- [x] Regress expired-token recovery, transient failures and subsequent sign-in;
      update architecture. Final-tree format: 363 files unchanged; analysis clean;
      772 tests passed / 1 live integration test skipped.
- [ ] Verify expired-session fallback on the next iOS build
      `[USER ACTION REQUIRED]`; live-monitor Crashlytics issue
      `c4880f82580d97645ad01e9cd866c7c1` after release.
      Read-only refresh 2026-10-22: issue remains OPEN / classified FATAL;
      `topVariants` returned 4 events / 2 affected users for
      2026-10-15T00:00:00Z–2026-10-22T23:59:59Z. Two latest samples:
      2026-10-19T17:13:16Z (`5.0.1 (32)`) and 14:44:49Z (`5.0.0 (31)`),
      `GotrueFetch._handleError` → session recovery → `zoned_guarded`,
      `refresh_token_already_used`. These are captured fatal reports, not
      independent evidence of OS process termination. Fix `73cad68` is in
      source; no verified build containing it was established.

## Approved release 5.0.1+32 (2026-10-16)
- [x] Owner approved patch version, five bundled locales and four ASC locales.
- [x] Production catalog diff 5.0.0 → 5.0.1 is empty; Gingerbread Man and
      five furniture pieces remain gated at 5.1.0; Ghost Sky stays unapplied.
- [x] Generate localizations and pass final-tree validation: 361 Dart files /
      0 format changes, analyze clean, 764 tests passed / 1 live test skipped.
- [x] Sync/read back ASC metadata; build, upload dSYMs, preserve archive,
      upload IPA, verify processing and attach build. Do not submit for review.
- [x] Record verified results and commit/push this release.
- [ ] Crashlytics Missing dSYMs and onboarding/native photo device checks
      `[USER ACTION REQUIRED]`; see `docs/release_status.md`.
- [ ] Align notification extension version/build with Runner in a future build;
      current VALID build has two Apple `90473` warnings (extension 1.4.0+1).

## Feed photo selection feedback (2026-10-13)
- [x] Implement approved pet loading design and five localized copy pairs.
- [x] Keep loading through sized preview decode; prevent sending an old photo
      during replacement; preserve caption and prior preview on cancel/failure.
- [x] Final-tree format/analyze passed; 759 tests passed / 1 live integration
      skip. Five-language layout, reduced motion and rendered loading checks
      passed (widget rendering uses a test font).
- [ ] Check native camera/gallery return and large/iCloud photos on device
      `[USER ACTION REQUIRED]`; widget tests cannot emulate native transfer.

## Debug currency repair (2026-10-13)
- [x] Reproduce protected-column writes failing and trace both debug buttons.
- [x] Replace the direct UPDATE with an authenticated, admin-only, self-only
      atomic RPC; surface and report write failures.
- [x] Deploy additive migration `20261013034744`; transactional SQL checks
      passed with every balance/timestamp write rolled back. Final-tree format,
      analyze and tests passed (755 passed / 1 live integration skip).
- [ ] Rebuild/install the app and check both +100 buttons with a real admin
      session `[USER ACTION REQUIRED]`; backend deployment is recorded in
      `docs/release_status.md`.

## Gingerbread Man rollout (2026-10-11)
- [x] Inspect and preserve the supplied stay/walk/sleep art and exact timing.
- [x] Wire `gingerbread_man`, five locales, PNG playback, GIF fallbacks and
      equipment preview; owner approved `minAppVersion = 5.1.0`.
- [x] Prepare Godot scenes and level-1 head/body/back estimates for review.
- [x] Owner explicitly approved provisional Flutter socket sync; retain all
      non-zero tracks and mirror Godot default equipment fits.
- [x] Owner Level-2 equipment review passed 2026-10-22 on the loop-centre head
      sockets and Godot default fits; back stays marker-only until a back SKU.
- [x] Final-tree format/analyze/test passed (750 tests / 1 skipped), bundle
      includes all 21 PNGs and three GIFs; rollout state documented.
- [ ] Owner review continuous loops, room-size rendering, equipment in both
      facings and release timing `[USER ACTION REQUIRED]`.
- [ ] Publish the push avatar and deploy `notify_friend` under separate
      approval; until then the existing ghost fallback remains.

## Active follow-ups
- [ ] Pro-only Ghost Sky (2026-10-22): migration applied and
      `grant_pro_backgrounds` deployed; `REVENUECAT_SECRET_KEY` set.
      `[USER ACTION REQUIRED]` verify on a 6.0.0 device that a Pro account
      gets Ghost Sky in every room and a free account sees "Pro only".
- [x] Festive furniture implementation (2026-10-11): normalized all five PNGs,
      wired the draft catalog, five app locales and purchase push names;
      format/analyze/test/bundle verified. Rollout state and required device
      checks are in `docs/release_status.md`.
- [x] Applied the festive furniture catalog migration and deployed
      `notify_friend` v40 with the owner's separate approvals (2026-10-11);
      production compatibility/source/HTTP/log checks passed.
- [ ] Release a build bundling the five festive furniture PNGs at `5.1.0+`;
      device and purchase-push acceptance remain `[USER ACTION REQUIRED]`.
      See `docs/release_status.md`.
- [x] Rotated the R2 access key (new Cloudflare token, Supabase secrets set
      2026-10-08 08:17 UTC, upload tested) and `NOTIFY_WEBHOOK_SECRET`
      (08:19 UTC; hunger cron 200, notify_friend accepts new / rejects
      wrong). Both had shipped in plain text in the 5.0.0 archive's
      `flutter_assets/.env`.
- [x] Old R2 API token deleted in Cloudflare (2026-10-08); the key bundled
      in 5.0.0 no longer works.
- [x] The app bundles `.env.app` (public keys only, `scripts/write_app_env.sh`)
      instead of `.env` from the next build on.
- [ ] Onboarding redesign (B + C hybrid) is code-complete; run the device
      checks listed in `tasks/onboarding_redesign.md` before release
      `[USER ACTION REQUIRED]`.
- [ ] Confirm build 31's Runner UUID `56233931-A031-3B30-BCF8-A5E536E9AF6B`
      and App.framework UUID `0C7143A3-FD06-B831-485E-50E69C4B8751` are absent
      from Crashlytics → Settings → Missing dSYMs `[USER ACTION REQUIRED]`; the
      release record lists all 12 uploaded UUIDs.
- [ ] Decide whether any room-frame casing belongs in the shop. This needs an
      `items` row, a price from `docs/shop_pricing.md`, and migration /
      old-client compatibility approval.
- [ ] Real-device verify shared frames in two upgraded clients (`3.2.0+24`
      has shipped); legacy-only choices are shared on Done.
- [ ] Crashlytics `0183b64515477452f62329d7d3a83a4f` (room-decor transient
      failure, fixed in `3.0.1+21`) stays OPEN until live verification.
- [ ] Live-verify Crashlytics `572d36c880cdbb5b0bf49e5694d08713` (create_room
      `ClientException`) and `5f5325b85f7205abe05a09582e05cf7e` (onboarding
      profile save 4s timeout); both fixes landed after build 24.
- [ ] Confirm build 24's Runner UUID `899B069B-543E-33E9-B307-4C78FBEC276A`
      and App.framework UUID `0C7143A3-E8A1-4BD6-485E-50E684619EE5` are absent
      from Crashlytics → Settings → Missing dSYMs `[USER ACTION REQUIRED]`.
- [ ] Confirm build 23's Runner UUID
      `1074123E-B8C3-3470-9A05-F5D2ACAF3F78` and App.framework UUID
      `0C7143A3-F470-6FF3-485E-50E695C70643` are absent from Crashlytics →
      Settings → Missing dSYMs `[USER ACTION REQUIRED]`.
- [x] Confirm build 22's recorded UUIDs (Runner
      `3D5833E2-B9BC-3107-9C9C-15DEFC0C5886`, App.framework
      `0C7143A3-330B-1F8B-485E-50E6EF09C56E`) are absent from Crashlytics →
      Settings → Missing dSYMs — confirmed 2026-08-26.
- [x] Confirm build 21's recorded UUIDs are absent from Crashlytics Missing
      dSYMs — confirmed 2026-08-20.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and
      `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm organic post-deploy timing for timezone-normalized pet RPCs.
- [ ] Add a leak regression test for `CachedNetworkImageView` if its cache
      manager harness can be stabilized without hanging `flutter test`.
- [ ] Convert source-text app tests to behavioral coverage where practical.
- [ ] Instrument remaining best-effort bare catches opportunistically with
      `reportSwallowedError(...)`.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.


## History

Previous task plans and verification evidence:
`tasks/archive/todo_20260913_pre_instruction_cleanup.md`,
`tasks/archive/todo_20261004_completed_plans.md`.
