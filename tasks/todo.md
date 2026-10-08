# TODO

## Active follow-ups
- [ ] Rotate the R2 access key and `NOTIFY_WEBHOOK_SECRET`: the app bundles
      `.env` as a Flutter asset, and the 5.0.0 archive's
      `flutter_assets/.env` contains both in plain text (the app uses
      neither). Then bundle a client-only env file `[USER ACTION REQUIRED]`.
- [ ] The admin debug coin tool (`lib/features/home/home_view_debug.dart`)
      writes `profiles.coins`/`diamonds` directly and now fails silently
      since those columns are server-only; replace it with an admin RPC.
- [ ] Onboarding redesign (B + C hybrid): plan and phase-0 approvals in
      `tasks/onboarding_redesign.md`.
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
