# Onboarding redesign — B + C hybrid

Status: **phase 1 (backend) applied 2026-10-08 as `20261008065402`; phase 2
(pre-auth shell) phases 3–6 (profile step, pet picker + naming, invite card, first-day
checklist) done 2026-10-08; phase 7 next.** Phase 0 decisions: backend contract approved; invite landing uses
generic copy before sign-in (option b). Design canvas (approved direction):
https://claude.ai/artifact/63F7MbNVcTLhdWvXhYpimF — rows "B+C Hybrid — New
keeper path" and "B+C Hybrid — Invited keeper path".

## Goal

Replace the sign-in wall → profile overlay → create room → step-locked coach
cards flow with:

- **New keeper:** Welcome fork → Sign-in + name + photo → Pick pet → Pet asks
  its name (creates room) → Invite card → Home with "first day" checklist →
  First-meal reward + push soft-ask.
- **Invited keeper:** invite link (or fork → code entry) → Invite landing with
  sign-in + name + photo → Joined celebration → Invitee checklist → same
  first-meal reward + push soft-ask.

## Current code it replaces

| Today | Where |
| --- | --- |
| `SignInView` first for any signed-out user | `lib/features/auth/auth_gate.dart`, `sign_in_view.dart` |
| Profile name/photo overlay (step `profile_setup`) | `lib/features/home/flows/home_onboarding_flow.dart` (`_buildProfileSetupOnboardingOverlay`, `_completeProfileSetupOnboarding`, `_uploadOnboardingProfileAvatar`) |
| Create / join room + pet picker | `lib/features/home/room_selection_view.dart`, `lib/features/home/controllers/home_room_manager.dart` (`_createRoom` → `create_room(p_name)`, join → `join_room_by_code`) |
| Coach cards `invite_friend` / `feed_once` | `home_onboarding_flow.dart` (`_buildBasicOnboardingCoachCard`, focus overlay), `onboarding_focus_utils.dart` |
| Onboarding state (device-local Hive) | `lib/services/settings/` `onboardingBasic*` keys |
| Push permission asked on every sign-in | `lib/services/fcm_service.dart` `initialize()` → `_requestNotificationPermission()` and `_initLocalNotifications()` iOS `requestPermissions` |
| Pending invite code from links | `lib/services/invite/invite_link_service.dart`, consumed in `lib/features/home/controllers/home_room_manager.dart:880` |

## Rewards (one-time per account, server-granted)

| Task | Who | Coins |
| --- | --- | --- |
| `first_feed` — feed a photo | both | 20 |
| `co_keeper_joined` — another active member joins your room | inviter | 50 |
| `first_furniture` — place a furniture item | both | 10 |
| `first_chat` — send a chat message | invitee | 10 |

Max 80 coins per account (about 3 median play days per `docs/shop_pricing.md`,
which affords a 100-rung item early). These are bonuses on top of the normal
feed reward from `claim_action_reward`. Re-run the shop_pricing calibration
queries after this ships ("after any change to coin rewards").

## Phases

### 0. Approvals needed before code `[USER ACTION REQUIRED]`

- [x] Backend contract below (new ledger source + RPC). It is additive, so
      installed clients are unaffected, but AGENTS.md requires approval.
- [x] Invite landing pre-auth preview: either (a) add an anon-callable
      `get_invite_preview(p_code)` returning only pet name, species and
      inviter nickname, or (b) show generic copy ("You've been invited to raise
      a pet") until sign-in. **Chose (b)**: no pre-auth data exposure,
      and the Joined screen right after is already personal.
- [ ] "Co-keeper joined" push to the inviter: v1 relies on the checklist
      noticing on next open; a `member_joined` type in `notify_friend` is
      phase 9 (needs old-client tap-handling check).

### 1. Backend — DONE (`supabase/migrations/20261008065402_add_onboarding_rewards.sql`; rollback dry run: claim 20 then 0, non-member and unknown task rejected, anon has no execute) (one migration, Supabase MCP, project `ilxzpszgirhwxpeocygs`)

- Extend `coin_ledger_source` check with `'onboarding'` (keep every existing
  value, latest list from `20260202090000_add_diamond_currency.sql`).
- Partial unique index on `coin_ledger (user_id, (metadata->>'task')) where
  source = 'onboarding'`: guarantees one grant per task per account.
- `claim_onboarding_reward(p_room_id uuid, p_task text) returns int`
  (coins granted, 0 if already claimed or not eligible). SECURITY DEFINER
  (it writes `profiles.coins`, matching `award_quest_reward`),
  `set search_path = public`, requires `auth.uid()` and an active
  `room_members` row. Amounts live **in the function**, not params. It
  checks eligibility from server truth:
  - `first_feed`: caller has an `image_feed` message in the room.
  - `co_keeper_joined`: room has ≥2 active members and the caller was a
    member first.
  - `first_furniture`: room has a placed furniture row owned or placed by
    the caller.
  - `first_chat`: caller has a `text` message in the room.
  Insert into the ledger with `on conflict do nothing`; update coins only when
  the insert landed. Grant `execute` to `authenticated` only.
- Update `memory-bank/database-schema.md` (Current Contracts) in the same
  commit.

### 2. Pre-auth shell — DONE (`lib/features/onboarding/onboarding_entry_view.dart`, `test/onboarding_entry_view_test.dart`; the invited sign-in is `SignInView(invited: true)`, restyled in phase 3)

- `AuthGate`: signed-out → `WelcomeForkView` (instead of `SignInView`).
  A pending invite link skips the fork and opens `InviteLandingView`.
- `WelcomeForkView`: "Start a new pet" → `SignInView` (new-keeper mode);
  "I was invited" → `InviteCodeEntryView` → stores the code with the existing
  `rememberPendingInviteCode` → `InviteLandingView`.
- Keep the existing terms/safety agreement checkbox and copy on both sign-in
  surfaces.

### 3. Sign-in + name + photo — DONE, simplified

As built: no extracted controller. Both paths reach `HomeView` right after
sign-in, and HomeView already owns the profile save/upload, so the old
overlay became `_buildProfileSetupOnboardingPage()`: a full Mori page shown
whenever the `profile_setup` step is active, including inside a joined room
(the old overlay only showed on room selection, so invited users skipped it).
It shows a "Signed in with Apple/Google ✓" chip, the avatar with a camera
badge (optional), and the name, prefilled from the provider
(`lib/features/onboarding/provider_display_name.dart`; Apple's given name is
saved to auth metadata at sign-in) and never prefilled with the localized
default. The sign-in screen is restyled to Mori with a new-keeper title. The
"disabled name/photo preview before sign-in" was dropped as ceremony.
`[USER ACTION REQUIRED]`: device-check the profile page after a fresh Apple
and Google sign-in (no widget test reaches it).

Original plan:

- Extract the save/upload logic out of `home_onboarding_flow.dart`
  (`_completeProfileSetupOnboarding`, `_compressOnboardingAvatar`,
  `_confirmOnboardingAvatarFraming`, `_uploadOnboardingProfileAvatar` via the
  `avatar_upload` function) into a reusable `ProfileSetupController` + an
  `AccountSetupPanel` widget.
- The screen has two states (the canvas shows them merged):
  1. **Signed out:** Apple / Google buttons and the terms checkbox. Name and
     photo are shown but disabled.
  2. **Signed in:** the buttons collapse to "Signed in with Apple ✓", the name
     is prefilled from the provider (fall back to empty, never the localized
     default nickname), and tapping the avatar opens the existing picker and
     framing. The photo is optional; Continue needs only a name.
- `InviteLandingView` uses the same panel under a pet-first header.
- Gate: `AuthGate` routes a signed-in user without a completed profile
  (`_isProfileSetupComplete` rule) back to this panel, so killing the app
  mid-flow resumes correctly.

### 4. Pick pet + naming dialogue — DONE, as built

`PetSelectionPage` is now two steps: pick ("Move in", local only), then the pet
asks its name in a dialogue box over the default room background ("That's
you!" submits; create still calls `create_room(p_name)` unchanged). The room
preview lives on the naming step, not the picker. Shop pet-ticket adoption
uses the same page and gets the naming step with its own confirm label. Also
fixed: pet cards overflowed at max text size on 320pt phones (name 1 line,
tagline 2). The createPet coach card is removed in phase 6.

Original plan:

- Restyle the picker in `room_selection_view.dart`: the preview shows the pet
  in the free room background. "Move in" is **local only**.
- New `PetNamingDialogue` (game-style text box over the room, "???" tag)
  uses `validate_pet_name` rules client-side. Submit calls the existing
  `create_room(p_name)`, so there's **no RPC change** and the room is created
  with the real name.
- Remove the separate "create room" step from onboarding.

### 5. Invite card — DONE, as built

The existing invite dialog (`_showInviteCodeDialog`, reached from the new-room
prompt, the in-room Invite button and the room list) now shows
`InvitePolaroidCard` (`lib/features/home/widgets/invite_polaroid_card.dart`).
Share captures that card as a PNG and sends it with the link; if capture
fails it shares the link alone. "+50 coins when they join" shows only while
basic onboarding is active (the claim itself is phase 6). The card does not
auto-open after naming: the new-room prompt ("<pet> needs a second keeper",
Invite) opens it, so no code is created for people who skip. Six unused
invite strings were removed.

Original plan:

- `InviteCardSheet`: polaroid widget (pet + "Help me raise <pet>?" + code),
  rendered to PNG via `RepaintBoundary` and shared with `share_plus` (already
  a dependency) alongside `inviteUriForCode(code)`. Show "+50 when they
  join".
- "Later" just closes it; the checklist keeps the task.

### 6. First-day checklist — DONE, as built

- `lib/features/onboarding/first_day_checklist.dart` (tasks + card) and
  `lib/features/home/flows/home_first_day_flow.dart` (HomeView wiring).
- Claimed state = the caller's own `coin_ledger` rows with
  `source = 'onboarding'`; no client-side task state. Sync claims every open
  task on room refresh (10s throttle), first room render, feed completed,
  chat closed and decor closed. All three claimed → onboarding `completed`.
- Eligibility: a new Hive flag `onboarding_first_day_eligible`, set only when
  a fresh onboarding starts. Every install from before this sits in the old,
  never-finishing `invite_friend` step, so without the flag all existing
  users would get the checklist and the +50 invite promise. (A reinstall
  counts as fresh; the server still pays each task once per account.)
- After saving the profile, a new keeper with no room and no pending invite
  goes straight to the pet picker. That replaced the create-pet coach card;
  the coach card, focus overlay and `onboarding_focus_utils.dart` (and its
  test) are deleted, along with three unused strings.
- The new-room invite prompt hides while the checklist shows (it has an
  invite row).
- Skipped: the keeper-slot avatars in the room header. The checklist's
  invite row keeps the invite visible; add slots if testing shows people
  miss it.

Original plan:

- `FirstDayChecklistCard` in the home room, three rows; tapping a row runs
  its action (camera, invite sheet, furniture inventory).
- Rows are derived from data HomeView already loads (feeds, member count,
  placed furniture, messages), with no new client state. When a row turns
  true, call `claim_onboarding_reward`; on >0 show the reward using the
  existing gold/reward styling.
- Keeper slots in the room header: the inviter's avatar plus a dashed "+"
  slot that opens the invite sheet while the room has 1 member.
- Collapses to a pill; dismissable; hidden once all three are done.
- Delete `_buildBasicOnboardingCoachCard`, `_buildBasicOnboardingFocusOverlay`
  and `onboarding_focus_utils.dart` once nothing references them.

### 7. First-meal reward + push soft-ask

- `FCMService.initialize()`: request permission **only** when status is
  already `authorized`/`provisional`, or when called from the soft-ask.
  Otherwise just check `getNotificationSettings()`. Gate the
  `_initLocalNotifications()` iOS `requestPermissions` the same way.
  Existing users who already answered are unaffected.
- After the first successful feed: the "Yum! +20" card, then "Yes, remind me"
  → `FCMService.requestPermissionAndInitialize()`. "Not now" stores
  `pushSoftAskSnoozedUntil` (+3 days) in app settings and re-asks once after
  a later feed.

### 8. Invited keeper

- `InviteLandingView` → sign-in + profile → existing
  `join_room_by_code` (through the pending-code path in `home_room_manager`)
  → `JoinedCelebrationSheet` (both avatars + pet, "Feed <pet> a photo" /
  "Look around first").
- Invitee checklist = the same component with tasks `first_feed`,
  `first_chat`, `first_furniture`.
- Expired or invalid code: return to code entry with localized copy via
  `userFacingError`.

### 9. Later (not in v1)

- `member_joined` push to the inviter (`notify_friend` type + client tap
  route + old-client fallback check).
- Pre-auth invite preview RPC if phase 0 chooses (a).

## Migration of existing installs

- `onboardingBasicCompleted == true` or dismissed → no change; the checklist
  never appears.
- Stored step `profile_setup`/`create_pet` → enter the new flow at phase 3/4.
- Stored step `invite_friend`/`feed_once` → show the checklist (rewards still
  one-time, server-enforced).
- A reinstall resets Hive, but rewards can't be re-earned (unique index).

## Cross-cutting

- l10n: every new string in `app_en/ja/ko/zh/zh_TW.arb`, regenerate. Use
  `BalancedText` for wrapping copy; Mori tokens only; `HardShadowPressButton`
  for primary CTAs; `JuicyScaleButton` elsewhere.
- Analytics funnel (`AnalyticsService.logEvent`): `onboarding_fork`
  (`path`), `onboarding_signed_in`, `onboarding_profile_saved` (`has_photo`),
  `onboarding_pet_named`, `onboarding_invite_shared` / `_skipped`,
  `onboarding_task_done` (`task`), `push_soft_ask` (`answer`),
  `onboarding_invite_landing` (`source: link|code`), `onboarding_joined`.
- Errors via `reportUserVisibleError` / `reportSwallowedError`.
- Tests: widget tests for fork routing (pending code skips the fork), two-state
  sign-in panel, naming dialogue validation, checklist derivation, FCM no
  longer prompting on sign-in (inject `requestPermission`, as existing tests
  do); SQL checks for the RPC (double-claim returns 0, non-member raises,
  ineligible returns 0).
- Docs in the same commits: `memory-bank/ui-ux-guidelines.md` (onboarding
  section), `memory-bank/architecture.md` (new feature folder + state flow),
  `memory-bank/database-schema.md`, `memory-bank/progress.md`.
- Gate: `docs/testing.md` final-tree format/analyze/test before each push.

## Suggested order / PRs

1. Backend migration + RPC tests (phase 1) — safe to ship alone.
2. Profile panel extraction + pre-auth shell + invite landing (2, 3, 8 entry).
3. Pet picker + naming dialogue + invite card (4, 5).
4. Checklist + rewards + keeper slots, delete coach cards (6, 8 rest).
5. FCM soft-ask (7).
6. Real-device check of both paths with two accounts `[USER ACTION REQUIRED]`.
