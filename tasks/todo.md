# TODO

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

## Auth token recovery (2026-10-21)
- [x] Handle auth stream errors in AuthGate, Home and FCM; retain SDK session
      cleanup/retry behavior and show the existing localized re-auth prompt.
- [x] Regress expired-token recovery, transient failures and subsequent sign-in;
      update architecture. Final-tree format: 363 files unchanged; analysis clean;
      772 tests passed / 1 live integration test skipped.
- [ ] Verify expired-session fallback on the next iOS build
      `[USER ACTION REQUIRED]`; live-monitor Crashlytics issue
      `c4880f82580d97645ad01e9cd866c7c1` after release.

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
- [ ] Sync level-2 exported sockets/equipment fits after owner review
      `[USER ACTION REQUIRED]`; do not publish estimated tracks as final.
- [x] Final-tree format/analyze/test passed (750 tests / 1 skipped), bundle
      includes all 21 PNGs and three GIFs; rollout state documented.
- [ ] Owner review continuous loops, room-size rendering, equipment in both
      facings and release timing `[USER ACTION REQUIRED]`.
- [ ] Publish the push avatar and deploy `notify_friend` under separate
      approval; until then the existing ghost fallback remains.

## Active follow-ups
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
