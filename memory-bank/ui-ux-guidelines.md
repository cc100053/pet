# UI/UX Design Guidelines

Compact current-state summary. Keep product UI playful and game-like. Latest
snapshot: `memory-bank/archive/ui_ux_guidelines_20260704_pre_compaction.md`.

## Interaction
- Use `JuicyScaleButton` for clickable elements.
- Fire business logic immediately on release; do not await bounce animation.
- Standard haptics: `lightImpact` on press, `mediumImpact` on release.

## Visuals
- Thick black borders, usually `2..3` px on primary surfaces.
- Rounded corners: large cards/toasts around `32`, dialogs/actions around `16`.
- Soft cream gradients and translucent vertical `BoxShadow` depth.
- Primary typeface: `GoogleFonts.mPlusRounded1c`.

## Feedback
- `showJuiceToast`: blocking alerts, confirmations, and input.
- `showJuiceSnackbar`: non-blocking success/info feedback.
- `JuicePosition.center`: complex input, IAP previews, critical confirmations.
- `JuicePosition.bottom`: standard warnings and alerts.

## Room Frame Casings (房間選擇)
- `RoomFrameSkin` in `lib/features/home/widgets/room_frame_skins.dart` is the
  only place casing values live; `RoomFrameCard` renders all of them.
- `RoomFrameStyle.original` is the pre-redesign card and the default; never drop
  it, or existing rooms lose the look they had.
- Casings unlock by room level through `RoomFrameSkin.unlockLevel`. To stage the
  ladder, change only those numbers.
- Three invariants every casing must keep: nothing paints over the photo message
  zone (ratio `RoomFrameSkins.photoAspectRatio`, currently 1.25), the pet
  overlaps only its bottom-right corner, and no frame name or rarity text
  appears on the card — names live in the 換相框 sheet.
- The card is laid out around its photo, which holds 63–66% of the card. Widen
  the ratio and the photo shrinks; the mat is sized from its own contents, so
  the two never trade space silently.
- The mat is a text block beside the hunger ring, not a stack of rows. The ring
  is the trailing element centred against both text rows — at the end of the
  last row it reads as fallen into the corner — and is kept below the text
  block's height so it can never drive the mat's size.
- The mat's horizontal inset derives from `skin.photoInset`, not `matPadding`,
  so the name lands on the photo's left edge in every casing. Retune photo
  insets freely; the mat follows.
- The caption line is never blank and never conditional: blank reads as a hole,
  conditional makes cards in one grid different heights. It falls back through
  photo caption → hungry → new photo → no photo yet, and a status line is styled
  distinctly from a human one (lighter, with a glyph) so the app is never
  mistaken for a person.
- Names are fitted to the lane they get (15→11pt, then ellipsis), not capped to
  fit it. No character limit can serve both scripts: CJK names run 3 characters
  on average, Latin ones 5, with 95th percentiles of 5 and 11.
- Card height comes from `RoomFrameGeometry`, shared by the card's build and the
  grid's cell estimate. Keep them reading the same source.
- In the 換相框 sheet, the label under a swatch names the casing — it never
  states ownership. 使用中 is the green ring plus check badge, locked is a dark
  `🔒 Lv n` chip on the drained miniature, and the 擁有 majority needs no word:
  a label every unremarkable swatch shares carries no signal. Swatches show
  `RoomFrameSkin.shortLocalizedName` (the variant half, scaled down to fit, not
  ellipsised); the full `family · variant` name stays under the preview.
- 換相框 opens on long press, which has no visual form, so the gesture is taught
  in two places and nowhere else: `roomSelectionSubtitle` names it permanently,
  and `RoomFrameLongPressHint` — a coach bubble over the first card, owed once
  per device via `AppSettingsRepository.roomFrameHintSeen` — says it out loud on
  the first visit. The bubble times itself out with an `AnimationController`,
  never a `Timer`, so `pumpAndSettle` runs it out instead of failing on a
  pending timer. It is spent by a tap, by its stay ending, or by a long press
  from a player who never needed it. Do not add per-card chrome for this: the
  rim already carries the unread badge, the paywall chip, and the top accent.
- The sheet header's trailing button leaves the room and says so:
  `Icons.logout_rounded` in a red-tinted circle, the same glyph the room-options
  leave tile uses. It is not an overflow menu and must not wear one.

## Implementation Notes
- Validate `showJuiceToast` inputs inside the dialog with `StatefulBuilder`;
  only close when validation passes.
- Prefer `AppTheme.primaryColor`, `successColor`, `secondaryColor`, and
  `errorColor` for semantic feedback states.
- For broader UI/UX implementation or review, read
  `.codex/skills/ui-ux-pro-max/SKILL.md` first.
