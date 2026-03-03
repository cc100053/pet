# TODO

## Plan
- [x] Locate Profile page structure and extract current feedback entry from About section.
- [x] Add a standalone feedback section above the Terms of Use row, with motivating copy encouraging users to submit requests and improvement feedback.
- [x] Prefix app version text in Profile footer with localized "版本：" label.
- [x] Run `dart format` for touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this UI/content adjustment.

## Review
- [x] Implemented and verified.
- Profile page now shows feedback in its own card/section with motivational copy, positioned above the legal links section that contains `使用條款`.
- About/legal card now keeps privacy policy + terms only; feedback entry is no longer mixed in that card.
- Footer version text now uses a localized prefix (`版本：` in zh/zh-TW) before `v{version} ({buildNumber})`.
- Added new localization keys across EN/JA/KO/ZH/ZH-TW: `profileFeedbackEncouragement` and `profileVersionPrefix`, then regenerated l10n.
- Verification passed: `flutter analyze`, `flutter test`.
