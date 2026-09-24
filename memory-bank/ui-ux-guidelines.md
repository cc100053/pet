# UI/UX Design Guidelines

Compact current-state summary. Keep product UI playful and game-like. Latest
snapshot: `memory-bank/archive/ui_ux_guidelines_20260818_pre_compaction.md`.

## Interaction
- Use `JuicyScaleButton` for clickable elements.
- Fire business logic immediately on release; do not await bounce animation.
- Standard haptics: `lightImpact` on press, `mediumImpact` on release.

## Visuals
- Thick black borders, usually `2..3` px on primary surfaces.
- Rounded corners: large cards/toasts around `32`, dialogs/actions around `16`.
- Soft cream gradients and translucent vertical `BoxShadow` depth.
- Primary typeface: `GoogleFonts.mPlusRounded1c`.
- Text scale = system text size (capped at `kMaxUserTextScale`) × `appUiScale`,
  applied once in `MaterialApp.builder`; never also scale theme font sizes.
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
