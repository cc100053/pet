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
  zone (ratio 1.72), the pet overlaps only its bottom-right corner, and no frame
  name or rarity text appears on the card — names live in the 換相框 sheet.
- Card height comes from `RoomFrameGeometry`, shared by the card's build and the
  grid's cell estimate. Keep them reading the same source.

## Implementation Notes
- Validate `showJuiceToast` inputs inside the dialog with `StatefulBuilder`;
  only close when validation passes.
- Prefer `AppTheme.primaryColor`, `successColor`, `secondaryColor`, and
  `errorColor` for semantic feedback states.
- For broader UI/UX implementation or review, read
  `.codex/skills/ui-ux-pro-max/SKILL.md` first.
