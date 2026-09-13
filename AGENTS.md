# AGENTS.md — PicPet / PetTomo

## Scope and completion

- This repo contains the Flutter app and its Supabase integration. Hosting,
  legal/support pages, invite fallbacks, and universal-link files live in
  `/Users/fatboy/geo-marketing/projects/pettomo`; do not recreate or deploy
  hosting files here.
- Complete implementation and verification within the requested scope.
  Review-only work remains read-only. Reuse approval already given for the
  same scope; retain the explicit approvals below.
- After requested repository changes, commit and push this task's changes
  unless the user requested otherwise. Preserve unrelated edits; report
  verification or push blockers without claiming completion.
- Use `tasks/todo.md` for substantial work needing a durable plan or handoff.
  Update relevant memory/runbooks when contracts or product decisions change.
  Archive historical detail rather than adding unconditional reading rules.

## Context routing

Read the sources relevant to the operation, not every linked document:

| Operation | Source |
| --- | --- |
| Ownership, state flow, split views | `memory-bank/architecture.md` |
| Backend contracts | `memory-bank/database-schema.md` |
| Product UI | `memory-bank/ui-ux-guidelines.md` |
| Current work / dependencies | `memory-bank/progress.md` / `memory-bank/tech-stack.md` |
| Related regression history | `tasks/lessons.md` |
| Server behavior, client/server contracts, upgrade-persistent state | `docs/ai_collaboration_workflow.md` |
| Release or deployment decisions | `docs/release_status.md` |
| Feed/reward/upload behavior | `docs/feed_upload_pipeline.md` |
| Hunger scheduling | `docs/hunger_tick_schedule_report.md` |
| Photo cleanup | `docs/abandoned_room_cleanup.md` |
| Coin pricing | `docs/shop_pricing.md` — use its calibrated ladder and guardrails |

Load the matching repository skill:

- Crashlytics evidence: `.codex/skills/firebase-crashlytics-triage/SKILL.md`.
- Release notes / ASC metadata: `.codex/skills/release-notes-sync/SKILL.md`.
- Shared item rollout or compatibility: `.codex/skills/shared-item-rollout/SKILL.md`.
- Godot sockets, sequence exports, equipment placement:
  `.codex/skills/pet-socket-calibration/SKILL.md`; consult the relevant socket or
  equipment sections of `docs/godot-png-sequence-socket-workflow.md`.
- Visual-pattern or accessibility questions beyond existing product guidance:
  `.codex/skills/ui-ux-pro-max/SKILL.md`.

When `.codegraph/` exists, use `codegraph_explore` or `codegraph explore` first
for code discovery. Fall back to source search when its results are insufficient.

## Compatibility and backend safety

- Installed clients remain supported. Before implementing or releasing a
  parameter change that can affect released versions, present compatible
  alternatives and obtain approval. Incompatible contract changes also need
  approval. Follow the compatibility runbook for current contracts, old
  request/response shapes, RPC overloads, persisted state, rollback, and
  deployed verification. A future app fix does not protect installed clients.
- Use Supabase MCP for authorized backend changes. Verify project
  `ilxzpszgirhwxpeocygs` before mutation. Save schema changes as timestamped
  migrations in `supabase/migrations/`.
- Review-only, draft, and approval-pending SQL remains unapplied. Do not ask
  the user to run SQL the agent is authorized and equipped to run. Photo
  cleanup remains explicitly human-reviewed and snapshot-scoped.
- On authentication failure, run `codex mcp login supabase` and retry after
  login completes. Diagnose other failures from their actual error.
- Establish live DB behavior from the current definition and latest applied
  relevant migration, not the first historical match.
- Enable RLS on user tables. Room access requires active `room_members`
  membership; use `(select auth.uid())`, `TO authenticated`, explicit grants,
  and indexes appropriate to the actual query and authorization paths.
- Default new client-facing RPCs to SECURITY INVOKER. Preserve intentional
  privileged functions and their authentication, grants, and authorization
  checks. Validate inputs and retain named `p_` RPC parameters.
- Never scan `pg_timezone_names` in RPCs; use `public.normalize_timezone(text)`
  or `AT TIME ZONE` with the documented `22023` fallback.
- Before authorized Edge Function deployment, verify deployed `verify_jwt`
  settings and required secrets; these are not centralized in a checked-in
  Supabase config. Follow the relevant runbook and verify deployed behavior.
- Never commit credentials, `.env`, service-account keys, `.p8` files, or
  generated secrets.

## Runtime invariants

- Refresh affected UI state after successful state transitions.
- Furniture dual-writes canvas and legacy positions. Preserve separate legacy
  4-argument and non-defaulted 6-argument RPC overloads.
- New shared items require version-gated visibility and old-client rendering
  fallbacks. Decor catalog, purchase predicates, and RLS must agree.
- Preserve GIF paths as stable source/fallback identifiers until explicit
  cleanup approval. PNG playback uses PetAnimationFrames,
  PetAnimationFrameBuilder, and PetAnimatedImage.
- Preserve every intentional non-zero Level 2 socket track using the calibration
  skill's `--track-threshold 0` rule; provisional captures require human review.
- Keep feed reward/message writes on the response path and partner push in
  `EdgeRuntime.waitUntil(...)`; preserve legacy response field types.
- Keep Hive initialization before UncleanExitService starts its sentinel.

## Flutter conventions

- Match `.fvmrc` (currently Flutter 3.44.0 / Dart 3.12.0); use matching
  `flutter` and `dart` binaries. Keep Flutter SPM integration and checked-in
  resolved packages aligned with the pinned SDK.
- In split-view `part` extensions, call the State's `_setStateForXxx` wrapper,
  qualify static members, and use the correct relative `part of` path.
  Moving symbols may require updating source-introspection tests.
- Use `userFacingError` for localized handled failures,
  `reportUserVisibleError` for bespoke visible copy, and
  `reportSwallowedError` with a stack trace for silent best-effort failures.
  Do not display raw exception text or classify errors by localized messages.
- ImageStreamListener callbacks own their ImageInfo clone: dispose it after
  reading, and use the already-sized provider for aspect-ratio probes.
- Use localized UI strings and regenerate localization after ARB changes.
- Follow the existing Juice UI system: JuicyScaleButton actions execute
  immediately on release; showJuiceToast is blocking and showJuiceSnackbar
  is non-blocking. Validate dialog input before closing. Visual and feedback
  rules live in `memory-bank/ui-ux-guidelines.md`.

## Verification

- `docs/testing.md` owns the validation policy; there is no CI gate. Before
  pushing code or runtime-asset changes, run its final-tree format/analyze/test
  sequence. Format only touched Dart files; run Flutter test processes
  sequentially because they share generated assets.
- Documentation-only changes require instruction/link/command validation
  instead of Flutter checks. Preserve the full code gate for executable changes.
- Live integration/webhook tests may mutate configured services or send
  notifications. Verify target, test account, and authorization before enabling
  them; credentials can also come from `.env`.
- For nested asset or sequence changes, run `flutter build bundle` and inspect
  the manifest and copied assets.
- Pet animations loop indefinitely; pump bounded durations in those widget
  tests instead of relying on pumpAndSettle.

## Releases

- Read the release skill before release-note changes. Localized drafts require
  approval before applying release-note files or ASC metadata. Explain the
  execution scope before approval; the approved full flow includes build,
  upload, and attachment. Preserve bundled/ASC copy separation, maintained
  locale mappings, older bundled entries, and the direct Apple Standard EULA.
- For every iOS release path, immediately after building the archive run:
  `ios/scripts/upload_archive_dsyms.sh build/ios/archive/Runner.xcarchive`.
  Preserve the archive before another build can overwrite it. A non-zero exit
  blocks release. See `docs/ios_app_store_export.md`.
- Preserve existing iPhone-only settings; release work does not authorize
  adding iPad or Mac Catalyst support. App Review submission requires an
  explicit request.
- Record repository baseline, exact ASC state, and verified public availability
  separately in `docs/release_status.md`; update it when actual release,
  deployment, or compatibility decisions change.
- Label required human dashboard/device checks `[USER ACTION REQUIRED]`.
  Report pending checks accurately rather than claiming full completion.
