# task-44.3 final handoff

Branch: `task-44.3-apple-exam-tools`
Current HEAD before Backlog/PR-body finalisation: `0d2515d6a841aecccbc229ab3eb22b72f622a4af` (`fix: expose lesson navigation bar helper`). Pushed to `origin/task-44.3-apple-exam-tools`.
Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

## Completed in this continuation

- Merged `origin/main` into the task branch at `264b7de3dc5a9b6679256f9f5aa2556e82a22cc0` and pushed it.
- Resolved the merge conflict in `LearnViews.swift` by keeping the lesson prerequisites section and restoring the `lessonReaderOpaqueNavigationBar()` view extension to non-private visibility so `StudyViews.swift` and `RootView.swift` compile.
- Rebuilt `Localizable.xcstrings` from `origin/main` with the Python JSON round trip (`OrderedDict`, `indent=2`, `ensure_ascii=False`, `separators=(',', ' : ')`, trailing newline) and added the task branch's 36 strings in sorted key order.
- Regenerated `apps/apple/CanadianHam.xcodeproj/project.pbxproj` from `apps/apple/project.yml` twice with XcodeGen; the second run left the project unchanged.
- Recaptured H3 sidebar evidence from a temporary detached `origin/main` worktree and from this branch, then removed the temporary worktree. Each final PNG was read once and confirmed to show the iPad app in landscape with the sidebar visible and comparable `Study`, `Practice categories`, and `Tools` headers:
  - `docs/evidence/task-44.3/sidebar-headers-before.png`
  - `docs/evidence/task-44.3/sidebar-headers-after.png`
- Checked LOW 6 with the same iPhone practice-question flow on `origin/main` and the branch. The origin/main log shows the large-title/top band already exists (`gapBelowNavigationBar=224.33` in `/tmp/task-44.3-low6-main.log`). The branch log shows a larger gap (`320.33` in `/tmp/task-44.3-low6-branch.log`) because the calculator tool row is present above the question card; the empty large-title band itself is pre-existing.
- Reverted incidental calculator screenshot churn from the validation runs; only the intentional sidebar evidence remains changed.

## Final validation

Final validation logs: `/tmp/task-44.3-final-validation-20261016-105104`.

Passed:
- iPhone full `CanadianHamExamToolsUITests`: 15 tests executed / 2 skipped / 0 failures. Log: `/tmp/task-44.3-final-validation-20261016-105104/iphone-exam-tools-class.log`.
- iPad full `CanadianHamExamToolsUITests`: 15 tests executed / 2 skipped / 0 failures. Log: `/tmp/task-44.3-final-validation-20261016-105104/ipad-exam-tools-class.log`.
- iPhone practice/mock audits (`testAccessibilityAuditPracticeSessionLight`, `testAccessibilityAuditPracticeSessionDark`, `testAccessibilityAuditMockExamFlowLight`, `testAccessibilityAuditMockExamFlowDark`): 4 tests / 0 failures. Log: `/tmp/task-44.3-final-validation-20261016-105104/iphone-practice-mock-audits.log`.
- macOS units: 135 tests / 0 failures. Log: `/tmp/task-44.3-final-validation-20261016-105104/macos-units.log`.
- `pnpm check:apple-l10n`: passed. Log: `/tmp/task-44.3-final-validation-20261016-105104/pnpm-check-apple-l10n.log`.
- `node scripts/check-apple-text-sources.ts`: passed. Log: `/tmp/task-44.3-final-validation-20261016-105104/apple-text-sources.log`.
- Shared practice helper identity check: 7 shared helper functions match `origin/main` byte-for-byte. Log: `/tmp/task-44.3-final-validation-20261016-105104/shared-helper-identity.log`.
- `TEST_GUARD_PR_BODY=$'Test-guard-approved: owner decision 2026-10-14\n' node scripts/check-test-guard.mjs --base origin/main --head HEAD`: passed; guarded findings approved by marker. Log: `/tmp/task-44.3-final-validation-20261016-105104/test-guard.log`.

## PR-body requirements

The PR body still needs to include the marker line exactly at the start of its own line:

`Test-guard-approved: owner decision 2026-10-14`

It should list the per-test results above, the sidebar before/after evidence paths, the LOW 6 result, and note that the PR waits for the merge batch on all four platforms because Apple shared code/string-catalog changes affect iOS, macOS, tvOS, and visionOS.
