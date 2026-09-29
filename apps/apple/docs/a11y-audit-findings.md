# Apple accessibility audit findings

T-503/T-504/T-505/T-506/T-512 expanded the default Apple UI surface from the first category-practice slice to the progress/practice/mock/settings slice. The default iOS UI suite now runs deterministic default `performAccessibilityAudit()` checks with no allow-list in both light and dark appearances for these screens and states:

1. Home/readiness;
2. Practice hub, unanswered practice, answered practice, and practice review;
3. Mock exam start, question navigator/timer, answered/flagged navigator state, and results;
4. Learn placeholder;
5. Settings;
6. About;
7. Store recovery.

The tests launch each audited screen directly with fixed launch arguments and reset local SwiftData files on launch, so audit state does not depend on prior progress, imported files, or random seeds. Any audit issue fails the test; fixes should be made in UI rather than allow-listed.

## Current default audit

- Tests:
  - `CanadianHamPracticeUITests.testAccessibilityAuditCoreScreensLight`
  - `CanadianHamPracticeUITests.testAccessibilityAuditCoreScreensDark`
  - `CanadianHamPracticeUITests.testAccessibilityAuditPracticeSessionLight`
  - `CanadianHamPracticeUITests.testAccessibilityAuditPracticeSessionDark`
  - `CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowLight`
  - `CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowDark`
- Launch state: `-CanadianHamResetDataOnLaunch` plus fixed launch arguments per audited screen/state.
- Appearances: light and dark.
- Allow-list: none.
- Expected default evidence output: none beyond normal XCTest pass/fail output.

## Timing notes

Keep timing notes in the task/review report for the exact commit under review. Do not treat historical XCTest durations as refreshed evidence after UI or audit-surface changes.

## Historical T-516 note

Earlier T-516 evidence in `apps/apple/docs/a11y-evidence/` remains historical diagnostic output. It should not be treated as refreshed evidence for the expanded progress/practice/mock/settings slice unless the opt-in diagnostic harness is explicitly re-run.
