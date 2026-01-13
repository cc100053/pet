# Progress

## Done
- Created initial memory-bank docs: `tech-stack.md`, `architecture.md`, `implementation-plan.md`, `progress.md`.
- Captured stack details from GDD into `tech-stack.md`.
- Integrated critical review updates into GDD (night mode, label mapping, UI gesture handling, opt-in ads, RLS, backend validation).
- Updated memory-bank docs to reflect new architecture, stack, and plan notes.
- Filled `implementation-plan.md` with phases, milestones, and risks.
- Added `database-schema.md` with draft tables and RLS policy examples.
- Finalized table/field naming and added RPC vs Edge Function split in schema docs.
- Updated architecture and tech stack notes to reflect the hybrid approach.
- Added `label-mapping.md` with seed mappings and quest keywords.
- Generated Supabase schema migration and seed data for label mappings/quests.
- Added `create_room` RPC and ownership transfer trigger for room owner changes.
- Added `leave_room` RPC to deactivate membership and trigger owner transfer.
- Added `regenerate_invite_code` RPC for owner-only invite refresh.
- Clarified owner-only invite code sharing in the GDD.
- Refined implementation plan with per-phase testing steps.
- Reformatted the GDD for readability without changing content.
- Added MVP designer checklist to the GDD.
- Simplified designer deliverables to interface design, component library, and pet assets.
- Added non-Figma asset handoff guidance in the GDD.
- Added asset format table and Rive material guidance to the GDD.
- Restructured GDD section 7.4 for clearer designer deliverables.
- Implemented Phase 0 scaffold: Flutter project, env setup, CI, auth gate, and profile stub.
- Added Supabase env template and README setup guidance.
- Updated architecture and tech stack docs to reflect Phase 0 modules and CI.
- Marked Phase 0 as completed in the implementation plan.
- Added `award_quest_reward` RPC to grant daily quest bonus safely.
- Added `feed_validate` Edge Function to validate labels, award feed/quest coins, and store feed messages.
- Fixed RLS recursion on `room_members` with `is_room_member` helper.
- Fixed `create_room` RPC ambiguity for `invite_code`.
- Added in-app test tools: Create Test Room + Run Feed Test.
- Added auth debug logging for JWT + UID on sign-in.
- Temporarily disabled `verify_jwt` for `feed_validate` due to Edge gateway JWT rejection; function still validates via `auth.getUser()`.

## Next
- Review and refine the schema/RLS with real Supabase project constraints.
- Define label mapping strategy and localization coverage for ML Kit tags.
- Validate seed data against ML Kit label logs once available.
- Configure and deploy `feed_validate` with R2 credentials, then run end-to-end feed tests.
- Revisit Edge JWT verification and re-enable `verify_jwt` once root cause is found.
