# UI/UX Design Guidelines: Juice UI System

Compact current-state summary. Keep product UI playful and game-like.

## Interaction Rules
- Use `JuicyScaleButton` for clickable elements.
- Fire business logic immediately on release; do not await the bounce animation.
- Standard haptics for juicy buttons:
  `lightImpact` on press and `mediumImpact` on release.

## Visual Rules
- Thick black borders, usually `2..3` px on primary surfaces.
- Rounded corners: large cards/toasts around `32`, dialogs/actions around `16`.
- Soft cream gradient backgrounds instead of flat fills.
- Use `BoxShadow` depth with translucent black and vertical offset; avoid solid
  fake-depth slabs.
- Primary typeface: `GoogleFonts.mPlusRounded1c`.

## Feedback Surfaces
- `showJuiceToast`
  Use for blocking alerts, confirmations, and input.
- `showJuiceSnackbar`
  Use for non-blocking success/info feedback; overlay-based and auto-dismissed.
- `JuicePosition.center`
  Use for complex input, IAP previews, and critical confirmations.
- `JuicePosition.bottom`
  Use for standard warnings and alerts.

## Implementation Notes
- Validate `showJuiceToast` inputs inside the dialog with `StatefulBuilder`;
  only close when validation passes.
- Prefer `AppTheme.primaryColor`, `successColor`, `secondaryColor`, and
  `errorColor` for semantic feedback states.
- Keep comments and styling choices minimal but intentional; avoid generic
  enterprise UI patterns.
