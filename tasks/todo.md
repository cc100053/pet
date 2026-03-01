# TODO

## Plan
- [x] Confirm current room-creation flow between `PetSelectionPage` and Home controller.
- [x] Move room-creation execution trigger to `PetSelectionPage` via async submit callback.
- [x] Keep loading UI on `PetSelectionPage` (`建立中...`) until room creation finishes.
- [x] Keep failure on `PetSelectionPage` (do not pop), show actionable error, and allow retry.
- [x] Run `flutter analyze` and `flutter test`.

## Review
- `PetSelectionPage` now submits room creation through an async callback and stays on the same page while creating.
- During creation, the page shows an in-page loading state (`roomSelectionCreating`) with interaction blocked; it only pops after successful creation.
- On creation failure, the page remains open and surfaces localized error text for immediate retry.
- Validation: `flutter analyze` and `flutter test` both passed.
