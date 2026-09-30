# UI/UX Design Guidelines

Compact current-state summary. Keep product UI playful and game-like. Latest
snapshot: `memory-bank/archive/ui_ux_guidelines_20260818_pre_compaction.md`.

## Interaction
- Use `JuicyScaleButton` for clickable elements; primary CTAs use
  `HardShadowPressButton` (ink border, presses into its same-hue shadow).
- Fire business logic immediately on release; do not await bounce animation.
- Standard haptics: `lightImpact` on press, `mediumImpact` on release.

## Visuals ("Mori" direction, 2026-09-30)
- Modern Japanese social-game feel (Animal Crossing warmth). Use `AppTheme`
  Mori tokens (`paper`, `ink`, `leaf`, `leafStrong`, `leafDeep`, `sky`,
  `sakura`, `kinako`, `wood`, `gold`, `softLine`) instead of new hex literals.
- Outlines use warm-brown `AppTheme.ink`, `2..2.5` px, never pure black.
  Press shadows are solid same-hue offsets (e.g. `leafStrong` over `leafDeep`).
- White text only on `leafStrong` or darker; `leaf` is for accents/fills.
- `gold` rarity frames / NEW badges are reserved for shop and reward moments.
- Kana decorative labels (`KanaEyebrow`) render only for the `ja` locale, in
  the bundled `KiwiMaruKana` subset (kana + CJK punctuation only) with
  M PLUS Rounded fallback. Do not put kanji or Latin in it.
- Short UI copy that can wrap (titles, subtitles, hints, empty states, dialog
  and toast messages) uses `BalancedText` so lines break evenly instead of
  leaving an orphan (e.g. a lone 「す。」). Keep plain `Text` for one-line
  labels and long user content (chat bodies).
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
