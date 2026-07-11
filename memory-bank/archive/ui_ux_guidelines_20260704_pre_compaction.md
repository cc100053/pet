# UI/UX Design Guidelines

Compact current-state summary. Keep product UI playful and game-like. Latest
snapshot: `memory-bank/archive/ui_ux_guidelines_20260627_pre_compaction.md`.

## Interaction
- Use `JuicyScaleButton` for clickable elements.
- Fire business logic immediately on release; do not await bounce animation.
- Standard haptics: `lightImpact` on press, `mediumImpact` on release.

## Visuals
- Thick black borders, usually `2..3` px on primary surfaces.
- Rounded corners: large cards/toasts around `32`, dialogs/actions around `16`.
- Soft cream gradient backgrounds instead of flat fills.
- Use `BoxShadow` depth with translucent black and vertical offset; avoid solid
  fake-depth slabs.
- Primary typeface: `GoogleFonts.mPlusRounded1c`.

## Feedback
- `showJuiceToast`: blocking alerts, confirmations, and input.
- `showJuiceSnackbar`: non-blocking success/info feedback.
- `JuicePosition.center`: complex input, IAP previews, critical confirmations.
- `JuicePosition.bottom`: standard warnings and alerts.

## Implementation Notes
- Validate `showJuiceToast` inputs inside the dialog with `StatefulBuilder`;
  only close when validation passes.
- Prefer `AppTheme.primaryColor`, `successColor`, `secondaryColor`, and
  `errorColor` for semantic feedback states.
- For broader UI/UX implementation or review, read
  `.codex/skills/ui-ux-pro-max/SKILL.md` first.
