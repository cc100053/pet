# Archived completed plans (2026-10-04)

## Plan — "Mori" UI polish (2026-09-30)

Mockup: https://claude.ai/artifact/QkgrW69ooC6F5YwnuACR8r. Decisions: kana
labels only for `ja`; room frame casings unchanged; Kiwi Maru bundled as a
kana-only subset with M PLUS Rounded fallback.

- [x] Phase 1: `AppTheme` Mori tokens, `HardShadowPressButton`, juice
      toast/snackbar, `AppDialog`.
- [x] Phase 2: Home HUD, polaroid photo card, raised camera dock (icon-only).
- [x] Phase 3: Room selection chrome, `MoriPaperBackground`, ja-only `KanaEyebrow`.
- [x] Bundled Kiwi Maru kana subset (59 KB) as `KiwiMaruKana`; removed shop noren.
- [x] Overflow sweep: fixed Pro banner (ja), room header invite pill, shop buy
      button at 320pt; added `test/ui_overflow_matrix_test.dart`. All 5 locales
      checked on device pages at 402pt with zero overflow logs.
- [x] Copy gaps: ko/zh_TW missing keys added; zh (Hans) converted from
      Traditional (303 strings, mainland vocabulary); ja `roomLockedBadge`
      → ロック中; removed 7 duplicate keys ×4 ARBs;
      `test/l10n_completeness_test.dart` guards missing/duplicate keys.
- [x] Phase 4: Shop paper bg, noren strip (kana ja-only), green buy, gold frame = diamond-priced items, opaque pinned bar. Pro banner left as-is.
- [x] Phase 5: Calendar paper bg; profile + support ink sweep. Chat left as-is (chrome sits on the purchased room background); drawer + sign-in already harmonious.

## Plan — Repository instruction cleanup (2026-09-13)

- [x] Audit actual instructions and agree the full cleanup scope.
- [x] Simplify root guidance and skill routing; preserve operational constraints.
- [x] Correct runbook conflicts and archive historical context.
- [x] Validate skills, links, commands, and the complete diff.
- [x] Prepare the validated documentation changes for commit and push.

## Review — Repository instruction cleanup

- Simplified root and seven skill entrypoints, corrected paths and execution
  scope, and consolidated validation into `docs/testing.md`. Operational
  compatibility, release-copy, dSYM, socket, and cleanup safeguards remain.
- Release baseline and recorded public availability are separate. Preserved
  exact previous lesson, task, and release-ledger contents in linked archives.
- Seven skill metadata validators, 18 local Markdown links, five helper CLI
  help checks, historical snapshot equality, and `git diff --check` passed.
- Independent scope scenarios covered draft-only release, bundled-only edits,
  migration review, and an authorized crash fix; clarified conditional release
  sections following that check.
- Documentation only: no runtime changes, Flutter tests, or production actions.
