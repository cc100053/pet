# Release Status

This file is the repo source of truth for app release state and backend
deployment status. Update it whenever an app build, App Store Connect state,
server hotfix, Supabase migration, force-update config, or compatibility
decision changes.

Do not use git commit messages as the release-status source of truth. Commits
explain code history; this file records the operational state. Use git tags as
immutable snapshots only after a release is actually shipped or a deployment is
worth pinning.

## Current Public Release

Verify live store state before relying on these values for release decisions.

| Platform | Public version | Build | Store status | Verified at | Source | Git tag |
| --- | --- | --- | --- | --- | --- | --- |
| iOS | 2.3.0 | 13 | Repo workflow assumes current after completed `release-notes-sync`; ASC state `PREPARE_FOR_SUBMISSION`, build `VALID`, encryption exempt, attached, and not submitted in this step | 2026-07-26 | App Store Connect metadata sync/build upload/processing/attach; release-notes-sync completion rule | none |
| Android | Not tracked in current repo snapshot | - | Not tracked | - | - | none |

## Last Repo-Known Public Release

This section is a historical repo hint, not a live-store guarantee.

| Platform | Version | Build | Status note | Evidence | Git tag |
| --- | --- | --- | --- | --- | --- |
| iOS | 2.2.6 | 12 | Superseded in repo workflow by completed `2.3.0+13` release-notes-sync; ASC state was `READY_FOR_DISTRIBUTION` on 2026-07-26 | ASC version `b7b48f69-f839-41da-ba4f-60cc0bc9647b` | none |
| iOS | 2.2.5 | 11 | Superseded in repo workflow by completed `2.2.6+12` release-notes-sync; ASC state was `READY_FOR_DISTRIBUTION` on 2026-07-16 | ASC version `38afa02d-dc0a-4dff-a91c-4cedfe3095a0` | none |
| iOS | 2.2.4 | 10 | Superseded in repo workflow by completed `2.2.5+11` release-notes-sync; ASC state was `READY_FOR_DISTRIBUTION` on 2026-07-15 | ASC version `ca26e644-9448-4ee3-8640-bac50a810057` | none |
| iOS | 2.2.3 | 9 | Superseded in repo workflow by completed `2.2.4+10` release-notes-sync; ASC version state was `READY_FOR_DISTRIBUTION` on 2026-06-26 | ASC version `4f01124f-01d8-46c9-a5bf-106abb0d9f8d` | none |
| iOS | 2.2.2 | 8 | Superseded in repo workflow by completed `2.2.3+9` release-notes-sync; ASC version state was `READY_FOR_DISTRIBUTION` on 2026-06-22 | ASC version `1761de51-ec73-46e4-8b6f-134d9c650e1d` | none |
| iOS | 2.2.1 | 7 | Superseded in repo workflow by completed `2.2.2+8` release-notes-sync; ASC version state was `READY_FOR_DISTRIBUTION` on 2026-06-19 | ASC version `8eaa2a4f-8bc2-4044-a6e1-b3e510e609bb` | none |
| iOS | 2.2.0 | 6 | Superseded in repo workflow by completed `2.2.1+7` release-notes-sync; ASC version state was `READY_FOR_DISTRIBUTION` on 2026-06-16 | ASC version `ca6b8b89-a99e-4cc7-a23c-886853467b58` | none |
| iOS | 2.1.0 | 5 | Superseded in repo workflow by completed `2.2.0+6` release-notes-sync; ASC version state was `READY_FOR_DISTRIBUTION` on 2026-06-11 | ASC version `37897d26-cc47-492c-867f-c7bc3ee4d44b` | none |
| iOS | 2.0.2 | 4 | Previously recorded as public in archived release notes | Commit `ce4c85e` (`chore(release): bump to 2.0.2+4 with localized What's New`) | none |

## Next Release Candidate

| Platform | Version | Build | Local source | Store status | Store IDs | Next action | Git reference | Git tag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iOS | None active | - | `pubspec.yaml` `2.3.0+13` is now the repo current release baseline; Chicken is visible from `2.3.0`, while every `2.2.x` client keeps the default-pet fallback for unsupported remote Chicken state | ASC version `5a4313f5-29c6-4fc6-9ecf-0a5f9806670c` is `PREPARE_FOR_SUBMISSION`; build/upload ID `cab2d2f1-e325-4c66-bab5-ea974a6f5ab6` is `VALID`, App Store eligible, encryption exempt, and attached; localization IDs: en-US `d04d0424-e38d-4920-8313-146246ad14d5`, ja `a0dfd9cf-06a5-4a10-a238-0287da6389d5`, ko `491bb5fd-6ab8-42fe-b1cd-a67afd0c2533`, zh-Hant `9415b3c3-343b-410f-83b5-0729cf684d24` | Await an explicit request to run submission preflight and submit for review; monitor review/store outcome afterward | v2.3.0 release worktree | none |

## Backend Deployments

| Date | System | Target | Status | Compatibility note | Verification |
| --- | --- | --- | --- | --- | --- |
| 2026-07-16 | Supabase migration | `20260715164256_add_effective_room_pet_status_rpc` on `ilxzpszgirhwxpeocygs` | Applied (live migration `20260715165513`) | Backward-compatible, additive read-only RPC for a single server-timestamp effective hunger snapshot across the room picker and Pet Home. Existing RPCs, tables, and old-client behavior are unchanged; new clients retain the old local projection only as a rollout fallback if the RPC is unavailable | MCP apply succeeded after target URL verification. Live checks confirmed `SECURITY INVOKER`, stable/search path, authenticated-only execute, hunger 0–100, server timestamp, and matching JSON freshness metadata on a real active-member room. Supabase advisors report no lint for the new function |
| 2026-06-19 | Supabase Edge Function | `feed_validate` v21 on `ilxzpszgirhwxpeocygs` | Active / Deployed | Backward-compatible server hotfix for the intermittent "fed but satiety bar didn't move" bug. **Additive only:** after `process_feed_event` commits, reads `room_pet_state` (RLS `is_room_member`) and returns the authoritative post-feed state as new optional fields `pet_state` (hunger/mood/hygiene/last_decay_at/last_feed_at/last_overfed_at/poop_*) and `overfed`. No existing response field/type removed or changed; `verify_jwt` stays true; no DB function/signature change. Old app versions ignore the new fields and behave exactly as before. The app-side fix (authoritative apply + `last_decay_at` freshness guard + optimistic +25) ships in the next build and is what consumes these fields | MCP deploy returned v21 ACTIVE, `verify_jwt=true`; `flutter analyze` clean; `flutter test` 493 passed/1 skipped incl. `test/feed_validate_function_test.dart` (additive contract) + `test/features/feed/feed_pet_state_freshness_test.dart`. **Still to verify on live traffic:** watch `feed_validate` logs for non-200s and confirm `pet_state` is populated on a real feed |
| 2026-06-11 | Supabase config flag | `app_config.feed_presigned_upload_enabled` on `ilxzpszgirhwxpeocygs` | **Enabled (true)** | Turned the Phase 3 presigned upload path ON for clients that have the code (v2.2.0+). Old clients are unaffected (they never read the flag and keep the base64 path); new clients fall back to base64 on any presigned failure. Instantly reversible by setting the flag back to `false` | SQL `update` confirmed `value=true` at 2026-06-11T01:26Z. **Not yet end-to-end verified on a live build** — watch `feed_upload_url` + `feed_validate` edge logs for `presign_failed` / `invalid_image_url` / R2 PUT errors after real traffic |
| 2026-06-10 | Supabase Edge Functions + config | `feed_upload_url` v1 (new) + `feed_validate` v20 + `app_config` flag on `ilxzpszgirhwxpeocygs` | Active / Deployed, feature OFF at deploy time | Phase 3 presigned direct-to-R2 feed upload. Additive + opt-in: new `feed_upload_url` (verify_jwt=true) issues a room-scoped presigned PUT URL; `feed_validate` v20 (verify_jwt=true) now rejects a client `image_url` not under the room's R2 prefix (base64 path unchanged → zero impact on current traffic). Client uses the path only when `app_config.feed_presigned_upload_enabled` is true (seeded **false**) and falls back to base64 on any failure. Ships in a future app build; production behavior unchanged until the flag is flipped | `feed_upload_url` smoke: no-auth→401 (gateway), anon-bearer→`invalid_auth` (boots, imports resolve incl. presign); `feed_validate` v20 deployed (gateway 401 on no-auth); `deno check` parity with prior env quirks; `flutter analyze` clean; `flutter test` 481 passed/1 skipped incl. `test/features/feed/feed_presigned_upload_test.dart`. **Pre-rollout gate: keep flag false until the presigned client build is released and tested.** |
| 2026-06-10 | Supabase Edge Function | `notify_friend` v31 on `ilxzpszgirhwxpeocygs` | Active / Deployed | Behavior-preserving refactor (Phase 2): split the ~1300-line monolith into `notify_friend/l10n.ts` (push locale templates + store-item names) and `notify_friend/pets.ts` (avatar maps + type resolution), routed CORS/JSON through `_shared/http.ts`. No request/response contract change; `verify_jwt` stays false. Investigated the "tiger avatar bug" — `tiger_stay.gif` is a real R2 404, so `tiger -> ghost_stay.gif` is a deliberate fallback and was left unchanged (documented in `pets.ts`) | Deployed via CLI `--no-verify-jwt` (bundled index/l10n/pets/_shared); confirmed live v31 + `verify_jwt=false` and byte-exact CJK l10n via `get_edge_function`; smoke calls return 401/400 (boots, imports resolve); `deno check` clean; `flutter analyze` clean; `flutter test` green (472 passed/1 skipped) incl. `test/notify_friend_module_split_test.dart` |
| 2026-06-10 | Supabase migration | `20260610120000_add_room_home_summary_rpcs` on `ilxzpszgirhwxpeocygs` | Applied | Backward-compatible: two brand-new additive RPCs (`get_room_latest_feeds`, `get_room_member_counts`), both `SECURITY INVOKER` so existing RLS still governs access (no widened exposure); granted to `authenticated` only. Old app versions keep using their direct PostgREST queries; only new clients call the RPCs. Fixes the per-room latest-feed starvation bug and avoids transferring all member rows to count | MCP `apply_migration` success; smoke-tested both RPCs on live data; advisors show 0 new lints for the functions; `flutter analyze` clean; `flutter test` green (468 passed/1 skipped) incl. `test/room_home_summary_rpc_test.dart` and the home loading-performance introspection test |
| 2026-06-10 | Supabase Edge Functions | `feed_validate` v19, `avatar_upload` v6, `notify_friend` v30, `hunger_tick_dispatch` v7 on `ilxzpszgirhwxpeocygs` | Active / Deployed | Backward-compatible: no request/response contract change; each function's `verify_jwt` preserved (`feed_validate`/`avatar_upload`=true, `notify_friend`/`hunger_tick_dispatch`=false). Adds shared `_shared/{http,images,auth}.ts`; `feed_validate` reclaims its R2 object if `process_feed_event` rolls back; `avatar_upload` deletes the previous avatar on replace and the new object on failed profile update; webhook/scheduler secrets now use constant-time compare | `flutter analyze` clean; `flutter test` green (463 passed/1 skipped); `test/edge_function_storage_safety_test.dart` + existing introspection tests. Deployed via MCP (feed_validate/avatar_upload/hunger_tick_dispatch) and Supabase CLI `--no-verify-jwt` (notify_friend); confirmed live versions + `verify_jwt` via `list_edge_functions`; edge-function logs show all-200, no boot/import errors |
| 2026-06-07 | Supabase Edge Function + migration | `cleanup_abandoned_rooms` v2 and `20260607135307_guard_cleanup_purge_activity` on project `ilxzpszgirhwxpeocygs` | Active / Applied | Keeps `verify_jwt=false` custom bearer-secret auth; purge now fails closed unless approved candidates still match the stale room/R2 scan snapshot, and new room activity resets approved cleanup candidates to pending | MCP confirmed function v2/config, migration history, trigger/function permissions, active cleanup cron jobs, and cleanup queue `pending=88`, `purged=63`, `approved=0`; focused cleanup safety test; Supabase advisors checked; `flutter analyze`; `flutter test` |
| 2026-06-07 | Supabase Edge Function | `feed_validate` v18 on project `ilxzpszgirhwxpeocygs` | Active | Keeps the old response field `webhook_skipped: false`; moves partner push delivery off the feed response path via `EdgeRuntime.waitUntil` | MCP confirmed active function/config; focused function tests; `flutter analyze`; `flutter test` |
| 2026-06-07 | Supabase migration | `20260607005751_anchor_decay_after_pet_action.sql` | Applied | Existing clients keep using the same feed action contract; successful feed rewards now anchor hunger decay at feed time | MCP SQL verification; `test/feed_hunger_action_migration_test.dart`; full Flutter checks |
| 2026-06-07 | Supabase migration | `20260607005904_restrict_apply_pet_action_execute.sql` | Applied | Keeps `apply_pet_action` Data API execution authenticated-only | MCP SQL verification; full Flutter checks |

## Tracking Rules

- `pubspec.yaml` records the local app candidate version/build, not live store
  state.
- App Store Connect and storefront lookups are the authority for submitted,
  approved, and public iOS release status.
- This file records the repo's current operational understanding of release
  state, backend deployments, and compatibility decisions.
- `memory-bank/progress.md` should stay compact and point to this file for
  release details.
- `tasks/todo.md` should track active follow-ups, not long release history.
- Git commits are useful evidence, but they are not enough to know what is live.
- After a public app release, create a tag such as `ios/v2.1.0+5` and record it
  in the tables above.

## Update Checklist

Before uploading or submitting an app build:

- Update `pubspec.yaml` and bundled What's New / ASC metadata as needed.
- Add or update the candidate row in "Next Release Candidate".
- Record ASC version IDs, build IDs, upload time, and processing status.
- Record compatibility notes for old app versions.

After App Store/TestFlight state changes:

- Update the candidate status and next action.
- After the full approved `release-notes-sync` flow completes for a target
  version, treat that target version as the repo's Current Public Release for
  workflow purposes, even if ASC still reports a post-submit state such as
  `WAITING_FOR_REVIEW` or `PENDING_DEVELOPER_RELEASE`. Record the exact ASC
  state and IDs in the tables, but do not leave the completed target tracked
  only as a next release candidate.
- Add the release git tag after the shipped state is verified.

After backend deployment or migration:

- Add a "Backend Deployments" row with date, target, status, compatibility
  note, and verification.
- Update related docs and `memory-bank/progress.md` if current behavior changed.
- Confirm whether app-version gating, force-update config, or old-client
  defaults need to change.
