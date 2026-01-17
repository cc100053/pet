# Implementation Plan

## Scope
In scope:
- Auth (Apple/Google), profiles, account deletion flow
- Rooms, invite codes, multi-room limits, room membership
- Pet lifecycle + state machine (hunger/mood/hygiene/sleep)
- Night Mode protections (00:00-08:00 reduced decay, no poop penalty)
- Feeding flow with label mapping and backend validation
- Hybrid chat stream + pagination + memory calendar
- Supabase RLS + Edge Functions + webhook notifications
- Store, coins, subscriptions, rewarded ads
- Analytics + push notifications

Out of scope (initial release):
- Global rollout beyond initial languages
- Advanced personalization beyond GDD
- Cross-device offline reconciliation beyond basic retry

## Phases
Phase 0 - Foundation
- Repo structure, CI, basic Flutter shell
- Supabase project bootstrap, env management
- Auth scaffolding and profile stub
Testing:
- Smoke test app boot + sign-in on device/simulator
- Validate profile read/write via Supabase client
Exit: app boots, auth works, profile read/write
Status: Completed

Phase 1 - Data Model + Security
- Implement schema, indexes, and RLS policies
- Edge Function for feed validation + reward logic
- Invite code generation + room membership flow (`create_room`, `join_room_by_code`, `leave_room`, `regenerate_invite_code`)
Testing:
- SQL checks for RLS denial across rooms
- RPC tests for owner-only invite refresh + ownership transfer
- In-app Edge Function smoke test (create room + feed_validate)
Exit: rooms + membership flows are secure and verified with negative RLS tests
Status: Completed

Phase 2 - Core Gameplay Loop
- Pet state machine + night mode logic
- Feeding flow with ML Kit + mapping layer
- Seed `label_mappings` and `quests` from the label dictionary
- Chat stream (text + feed cards + system events)
Testing:
- Unit tests for label matching (EN->ZH/JA) and cooldown logic
- Integration test for feed -> Edge -> DB -> chat message
Exit: full loop works in one room with real-time sync
Status: Completed

Phase 3 - Social + Memory
- Memory calendar view from feed messages
- Webhook notifications for partner events
- Basic report/block flows
Testing:
- Pagination tests for chat history + memory query
- Notification delivery verification on both platforms
Exit: memory view + notifications usable
Status: Completed (basic flows accepted; hardening deferred)

Phase 4 - Monetization
- Store, coins, IAP/subscription, rewarded ads (opt-in)
- Room limits tied to subscription status
Testing:
- Sandbox IAP purchase/restore flows
- Rewarded ad opt-in flow tracking + coin ledger updates
Exit: monetization path functional end-to-end
Status: Completed

Phase 5 - Polish & Compliance
- [x] App config force-update, analytics events, UX fixes
- Performance tuning (image sizes, caching, load times)
- Report/block hardening (server-side enforcement + notification filtering)
- Implement offline-first message repository with Hive caching
Testing:
- Beta checklist: crash-free rate, startup time, cold-load chat
- Privacy/report flows validated
- Verify Hive local cache usage for chat history (offline support)
Exit: beta-ready build with tracking and compliance
Status: In progress

## Milestones
- M1: Schema + RLS + Edge Functions signed off
- M2: Core pet loop + chat working on device
- M3: Memory + notifications complete
- M4: Monetization and compliance ready for beta

## Risks & Dependencies
- ML Kit label mapping quality and localization coverage
- DraggableScrollableSheet vs ListView gesture conflict
- RLS correctness (room scoping and data leakage)
- Edge Function validation logic + latency
- Ad UX impact on retention
- Supabase Auth JWT signing mode mismatch (ES256) can cause Edge Function `verify_jwt` 401s; keep HS256 for now.

## Last things to-do
- Replace example `app_config` store URLs with real App Store / Play Store links.
- 
