# task-44.3 resume handoff

Current implementation HEAD before this handoff note: `b0f048700dfaf1fcc889ddb1891bbac9d778fec2` on branch `task-44.3-apple-exam-tools`.

Queued validation chain: `/tmp/task-44.3-resume-validation-20261015-094832` (nohup log `/tmp/task-44.3-resume-validation.nohup.log`). It is currently waiting for the shared `xbuild` lock behind other Apple jobs; do not kill those jobs.

Already validated before the b0f04870 fixes:
- Sidebar header comparison refreshed and pushed in `d55eda1d`.
- Exam tool screenshots refreshed and pushed in `58f9b4be`.
- Practice/mock audit run passed 4 tests in `/tmp/task-44.3-validation-20261014-152801/iphone-practice-mock-audits.log`.
- macOS unit run passed 133 tests in `/tmp/task-44.3-validation-20261014-152801/macos-units.log`.
- `pnpm check:apple-l10n`, `node scripts/check-apple-text-sources.ts`, and Localizable semantic check passed in `/tmp/task-44.3-validation-20261014-152801`.

Remaining queued/re-run validation from the current code:
1. Full iPhone `CanadianHamExamToolsUITests` class.
2. iPad portrait/landscape inspector tests and screenshot capture.
3. macOS units (rerun because `RootView.swift` changed after the earlier macOS run).
4. `node scripts/check-apple-text-sources.ts`.
5. Test guard and Localizable semantic check.

Known guard flags from the prior run are expected for this task/owner decisions: exam-tool audit-handler changes, approved exception helper calls, XCTSkip for compact/iPad split coverage, shared positioning/occlusion helpers, `.accessibilityHidden(true)` on the decorative calculator icon, and `.minimumScaleFactor` on the calculator display/key labels. The PR body needs the approved marker(s); do not weaken tests or helpers to satisfy the guard.

When the queued chain finishes, fix only real failures, rerun only failed tests with `-only-testing`, then check task ACs, write the final summary, set Done, push, and report the branch plus full SHA and per-test results.
