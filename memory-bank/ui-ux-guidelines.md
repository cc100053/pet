# UI/UX Design Guidelines

Compact current-state summary. Keep product UI playful and game-like. Latest
snapshot: `memory-bank/archive/ui_ux_guidelines_20260818_pre_compaction.md`.

## Interaction
- Use `JuicyScaleButton` for clickable elements; primary CTAs use
  `HardShadowPressButton` (ink border, presses into its same-hue shadow).
- Fire business logic immediately on release; do not await bounce animation.
- Standard haptics: `lightImpact` on press, `mediumImpact` on release.
- Chat text send uses a Telegram-style fly-in (`_SendFlyIn`, 340ms easeOutCubic):
  the bubble rises out of the composer input and older messages slide up with it.
  It runs only at the live bottom of the list and is skipped when the system
  reduce-motion setting is on. Its launch point survives the temp -> confirmed id swap.
- Other Telegram-style chat motion (`chat_room_view_v2_motion.dart`, time-based so
  it resumes across item rebuilds; none of it plays with reduce-motion on):
  photos sent from the room camera fly in once the camera route has closed;
  incoming messages at the live bottom grow in; own bubbles show a clock while
  sending, then a check pops in on confirm; reaction chips pop in or bounce and
  their counts roll on live changes (not on history loads); a floating date pill
  shows the topmost day while dragging the timeline, hidden while that day's
  inline separator is itself on screen.
- Chat emoji follow Telegram (`chat_emoji_text.dart`): inline emoji in text
  bodies, photo captions and the long-press preview render 1.25x the text size
  without growing the line; a body of only 1-3 emoji renders 44/38/32pt.

## Visuals ("Mori" direction, 2026-09-30)
- Modern Japanese social-game feel (Animal Crossing warmth). Use `AppTheme`
  Mori tokens (`paper`, `ink`, `leaf`, `leafStrong`, `leafDeep`, `sky`,
  `sakura`, `kinako`, `wood`, `gold`, `softLine`) instead of new hex literals.
- Outlines use warm-brown `AppTheme.ink`, `2..2.5` px, never pure black.
  Press shadows are solid same-hue offsets (e.g. `leafStrong` over `leafDeep`).
- White text only on `leafStrong` or darker; `leaf` is for accents/fills.
- `gold` rarity frames / NEW badges are reserved for shop and reward moments.
- The in-room "just arrived" popup shows once per account per NEW item (stored
  per user id in `app_settings`) and waits up to 2 min for a covering launch
  dialog such as What's New to close.
- Room-bound shop purchases always name their room: the kinako luggage-tag
  `ShopDeliveryTag` under the shop header (compact form in narrow dialogs) and
  a "Send to <pet>'s room?" confirm for multi-room users.
- Kana decorative labels (`KanaEyebrow`) render only for the `ja` locale, in
  the bundled `KiwiMaruKana` subset (kana + CJK punctuation only) with
  M PLUS Rounded fallback. Do not put kanji or Latin in it.
- Short UI copy that can wrap (titles, subtitles, hints, empty states, dialog
  and toast messages) uses `BalancedText` so lines break evenly instead of
  leaving an orphan (e.g. a lone 「す。」). It also never splits a word:
  ja/zh text is glued into BudouX phrases and Korean into space-separated
  words with invisible U+2060 joiners (`PhraseBreaks`, models loaded in
  `main.dart` before `runApp`), so 「ア｜イテム」-style breaks cannot happen.
  Keep plain `Text` for one-line labels and long user content (chat bodies).
- Fixed-size game surfaces must shrink, not overflow: `test/ui_overflow_matrix_test.dart`
  sweeps every locale × 320/375/402/440pt × text scale 1.0/1.3. Add new
  fixed-size surfaces to it.
- Room frame casings keep their original (black-outlined) art; do not reskin.
- New furniture art follows `docs/art_style.md` (canon: Cactus/Carpet/Vinyl
  gouache look; Gemini prompt templates; `scripts/normalize_furniture.py`).
- Rounded corners: large cards/toasts around `32`, dialogs/actions around `16`.
- Primary typeface: `GoogleFonts.mPlusRounded1c`.
- Text scale = system text size (capped at `kMaxUserTextScale`) × `appUiScale`,
  applied once in `MaterialApp.builder`; never also scale theme font sizes
  or multiply a `fontSize` by `homeUiScale`/`appUiScale`.
- Legal/subscription disclosure text: at least 11pt, fully opaque.

## Onboarding (B+C hybrid, in progress)
- Plan and status: `tasks/onboarding_redesign.md`; canvas linked there.
- Signed-out entry is a two-option Welcome ("Start a new pet" / "I was
  invited"). The invited sign-in shows generic copy only: no room, pet or
  inviter data before sign-in.
- After sign-in, the `profile_setup` step is a full Mori page (provider chip,
  optional photo, required name prefilled from Apple/Google), shown even
  inside a joined room so invited users get it too.
- `PetSelectionPage` (create room and shop pet tickets) is two steps: pick,
  then the pet asks its name in a game-style dialogue box over the room. Only
  the naming step pads for the keyboard; the page itself does not resize.
- Invites share `InvitePolaroidCard` as an image plus the link. The +50 line
  appears only to a room owner on the first-day checklist who hasn't earned
  it.
- The first-day checklist (`FirstDayChecklistCard`) sits at the bottom of the
  room: three tasks with coin rewards, any order, header tap collapses, ×
  dismisses for good. It replaces the old coach cards and the new-room invite
  prompt while shown.
- New accounts never see the iOS notification prompt at sign-in. After the
  feed that earns the first-meal reward, a card shows the reward and, while
  iOS is undecided, asks in the pet's voice; the system prompt appears only
  on "Yes, remind me". "Not now" re-asks once, at least 3 days later.
- Joining a room by code or link shows a celebration card (both keepers and
  the pet, "Feed <pet> a photo") instead of the old "joined" snackbar; a
  locked room keeps the snackbar.

## Feedback
- `showJuiceToast`: blocking alerts, confirmations, and input.
- `showJuiceSnackbar`: non-blocking success/info feedback.
- `JuicePosition.center`: complex input, IAP previews, critical confirmations.
- `JuicePosition.bottom`: standard warnings and alerts.

## Room Frame Casings (房間選擇)
- `RoomFrameSkin` is the single casing-value source and `RoomFrameCard`
  renders every style. `original` is the pre-redesign default.
- Unlocks come only from `unlockLevel`; lowering is safe, but raising can
  retract an already worn casing. The picker grandfathers the equipped style.
- `RoomFrameGeometry` is shared by card layout and grid height. Keep the photo
  message zone clear, the pet overlap at bottom-right, and frame names/rarity
  out of the card.
- The caption lane never disappears: photo caption falls back through hungry,
  new photo, then no photo. Status copy stays short and visually distinct.
- Names fit their available lane through responsive sizing/ellipsis; do not
  derive a character limit from one card layout.
- Long press opens 換相框. Teach it only in the persistent subtitle and the
  one-shot `RoomFrameLongPressHint`; below the `3.0.0` feature gate, neither
  path is exposed or spent.
- Swatches show casing names. Active uses a green ring/check; locked uses a
  drained miniature plus `Lv n`. Level-chip text must meet 4.5:1 contrast.
- Done explicitly saves a shared room casing even when the selection is
  unchanged. Save failures keep the sheet open with localized juice feedback.
  Legacy choices remain local until confirmed; shared state wins once loaded.
- Pet sprites animate forever, so widget tests on these surfaces pump explicit
  durations rather than `pumpAndSettle`.

## Implementation Notes
- Validate `showJuiceToast` inputs inside the dialog with `StatefulBuilder`;
  only close when validation passes.
- Prefer `AppTheme.primaryColor`, `successColor`, `secondaryColor`, and
  `errorColor` for semantic feedback states.
- Use `.codex/skills/ui-ux-pro-max/SKILL.md` only for design/accessibility
  questions not answered by existing product patterns.
- Currency-grant purchases update balances immediately from the RPC result,
  trigger gain SFX from purchase success, and animate with an explicit reward
  event id; a passive balance rebuild is not the feedback trigger.
- Keep TweenSequence input in `0..1`: put overshoot in tween values rather
  than feeding it an overshooting curve.
- `JuicePosition.top` is for background task notifications; complex inputs
  validate inside the dialog before closing.
