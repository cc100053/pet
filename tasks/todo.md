# TODO

## Plan
- [x] Verify why Step 1 CTA close does not work under debug force mode.
- [x] Fix close-path guard ordering so debug close always sets hidden state.
- [x] Run `flutter analyze` and `flutter test`.

## Review
- Root cause: `_isBasicOnboardingActive` mixed debug and normal activation with `OR`; in debug force mode, even after setting `_debugForceOnboardingHidden=true`, the normal branch (`!dismissed && !completed`) re-activated CTA immediately.
- Fixed by making activation mutually exclusive: when debug force is active, onboarding visibility is controlled only by `_debugForceOnboardingHidden`.
- Validation: `flutter analyze` and `flutter test` both passed.
