# task-44.3 review-fix handoff

Branch: `task-44.3-apple-exam-tools`
Current HEAD before this handoff commit: `c6bd14235c5bf245d5cd7df4f928cd90355a05bc` (`fix: focus calculator after inspector layout`).

Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

## Current state

Committed and pushed review-fix groups so far:
- `e0544e8c1dc60d932f5c369ce5bd8c38630e576e` — restored the shared practice helper and removed the broader exam-tools occluded filter copy. `auditIgnoringOccludedLessonTextContrast` in `CanadianHamPracticeUITests.swift` was verified byte-identical to `origin/main` for the function body, activity name, and note. Exam-tools large/largest/iPad inspector audits now call the shared helper logic in the ExamTools file; local ExamTools scroll helpers were renamed to avoid shadowing shared helper names.
- `f780a9f7f48480bb18fd77e7fe8f0ed73e7cd19a` — calculator behavior fixes: web-matching keyboard mapping, interface-locale display/spoken values, French decimal key display, immediate locale refresh via `updateCalculatorLocale`, iOS-only first-responder resignation, and unit coverage.
- `1f499300fb00a1fa116287d5cc2789d6b5142fb5` — UI coverage/test updates: dark loops for large-detent/largest Dynamic Type/iPad inspector audits, exact sidebar visibility restore logic, renamed positioning test, added app-level `app.typeKey("7")` auto-focus test, added mock-exam calculator reset UI test.
- `7814b1bc` — deleted `docs/evidence/task-44.3/resume-handoff.md`, rebuilt `Localizable.xcstrings` deterministically from `origin/main` order plus the 36 task keys inserted in sorted position, and corrected `docs/testing/ui-audit-inventory-after.md`.
- `c6aebb97bcc9fa74271c1d5972429b0927c6e97a` — refreshed real iPad sidebar comparison PNGs.
- `752c449164a6d414b4d2e4e6716f33cf664b8010` — fixed a test setup issue by using calculator buttons for the persistence setup instead of now-removed web-only keyboard shortcuts.
- `bd980241a0b462de1965c462b728a47f03520200` — adjusted tests for iPad inspector geometry.
- `c6bd14235c5bf245d5cd7df4f928cd90355a05bc` — delayed calculator focus after layout to try to preserve iPad inspector auto-focus.

Worktree has uncommitted screenshot PNG changes from test/screenshot runs:
- `docs/evidence/task-44.3/calculator-ipad-inspector-dark.png`
- `docs/evidence/task-44.3/calculator-ipad-inspector-landscape-light.png`
- `docs/evidence/task-44.3/calculator-ipad-inspector-light.png`
- `docs/evidence/task-44.3/calculator-iphone-large-dark.png`
- `docs/evidence/task-44.3/calculator-iphone-large-light.png`
- `docs/evidence/task-44.3/calculator-iphone-medium-dark.png`
- `docs/evidence/task-44.3/calculator-iphone-medium-light.png`
Do not assume these are reviewed/ready; the next worker should decide whether to keep or revert after successful final screenshot validation.

## Running / queued now

A nohup validation chain is currently running and must be left alive:
- Script: `/tmp/task-44.3-r443-4-rerun2.sh`
- Nohup log: `/tmp/task-44.3-r443-4-rerun2.nohup.log`
- Log dir: `/tmp/task-44.3-r443-4-rerun2-20261015-192947`
- Status file: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/status.tsv`
- Current step at last check: iPhone full `CanadianHamExamToolsUITests` class running.
- PIDs at last check:
  - wrapper/background: `5179`, `5181`
  - xbuild wrappers: `5189`, `5190`
  - xcodebuild: `5192`
- Command currently running:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests -resultBundlePath /tmp/task-44.3-r443-4-rerun2-20261015-192947/iphone-exam-tools-class.xcresult test CODE_SIGNING_ALLOWED=NO`

Rerun2 queued sequence after iPhone:
1. iPad full `CanadianHamExamToolsUITests` class.
2. macOS unit tests.
3. `node scripts/check-apple-text-sources.ts`.
4. `node scripts/check-test-guard.mjs --base origin/main --head HEAD`.

Do not start new runs until this chain finishes. Poll with `tail`/`grep` only.

## Validation evidence so far

From `/tmp/task-44.3-r443-4-validation-20261015-173620` (before the latest `c6bd1423` focus fix):
- `helper-localizable-precheck`: passed. It verified shared practice helper identity and Localizable 0 missing / 0 changed origin keys / 36 added keys.
- `iphone-practice-mock-audits`: passed, 4 tests / 0 failures. This also validated that the two mock navigator sheet audits pass after being reverted to plain audit.
- `macos-units`: passed in that chain, but because `c6bd1423` changed shared app UI code after that run, rerun2 has a macOS unit rerun queued.
- `pnpm-check-apple-l10n`: passed.
- `apple-text-sources`: passed.
- `test-guard`: failed with expected guarded findings; needs PR marker, not code weakening.
- `iphone-exam-tools-class`: failed before `752c4491` because the test used removed `s` keyboard shortcut.
- `ipad-exam-tools-class`: failed before `c6bd1423` due iPad auto-focus and geometry issues.

From `/tmp/task-44.3-r443-4-rerun-20261015-185855`:
- `iphone-exam-tools-class`: passed, 15 tests / 2 skipped / 0 failures.
- `ipad-exam-tools-class`: failed before `c6bd1423`, one remaining failure in `testCalculatorAutoFocusesHardwareKeyboardOnOpen` on iPad (display stayed `0` after `app.typeKey("7")`).
- `test-guard`: failed with expected guarded findings.

Rerun2 was started after `c6bd1423` to re-check iPhone/iPad plus macOS/text/guard. No result lines had appeared at the last check.

## Review findings status

Resolved or addressed:
- H1 helper identity: done.
- H2 broader exam-tools occluded filter: removed. Important: if reruns show the shared first-visible-scroll-view helper chooses the wrong scroll view while a tool is open, stop and report evidence; do not reintroduce another filter.
- H3 sidebar evidence: refreshed with real iPad app captures in `c6aebb97`; files are `docs/evidence/task-44.3/sidebar-headers-before.png` and `docs/evidence/task-44.3/sidebar-headers-after.png`. Log dir `/tmp/task-44.3-sidebar-capture-20261015-171356/`; `tail`/`sips` evidence showed both final files are 2500x1900 PNGs and `capture-origin-main 0`, `capture-branch 0`. A future worker/reviewer may still visually inspect the PNGs.
- M1 audit docs: updated.
- M2 dark runs: added to the large-detent, largest Dynamic Type, and iPad inspector audit tests.
- M3 keyboard mapping: fixed to match web.
- M4 interface-locale calculator: fixed with unit coverage.
- M5 exact sidebar restore: code and test expectations updated.
- Low 1: deleted old `docs/evidence/task-44.3/resume-handoff.md`.
- Low 2: renamed the overstated positioning test.
- Low 3: added app-level `app.typeKey("7")` auto-focus test. This is the test currently being validated after the iPad focus fix.
- Low 4: added UI test for new mock exam resetting calculator.
- Low 7: mock navigator audits reverted to plain audit and practice/mock audit run passed.
- Low 8: `suspendHardwareKeyboardInput` no longer resigns Mac first responder.
- Low 9: Localizable deterministic rebuild done; precheck passed.

Remaining / needs next worker:
- Finish rerun2. If it fails, fix only real failures and rerun only failed tests with `-only-testing`.
- Low 5: iPad full class is queued in rerun2; verify the non-skipped iPad tests after the latest fix.
- Low 6: empty band under the iPhone back button is not resolved. Need same-flow origin/main vs branch screenshots/evidence. If origin/main has it, report as pre-existing; otherwise fix. Medium-detent scroll is intended.
- Decide whether to keep/revert the dirty calculator screenshot PNGs after successful validation.
- Run/confirm final `pnpm check:apple-l10n` if needed after all changes. The r443-4 validation chain passed it before the latest focus-only change, but final acceptance should decide if a rerun is required.
- Update Backlog notes/final summary/status only after final validation.
- Final report needs full SHA, per-test results, and a findings-resolution table.
