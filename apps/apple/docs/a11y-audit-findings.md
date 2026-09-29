# Apple accessibility audit findings

T-503/T-504/T-505/T-506/T-512 expanded the default Apple UI surface from the first category-practice slice to the progress/practice/mock/settings slice. The default iOS UI suite now runs deterministic `performAccessibilityAudit()` checks with no allow-list for these top-level screens in both light and dark appearances:

1. Home/readiness;
2. Practice hub;
3. Mock exam start;
4. Settings;
5. About.

The tests launch each audited screen directly with fixed launch arguments and reset local SwiftData files on launch, so audit state does not depend on scrolling history, prior progress, imported files, or random seeds. Any audit issue fails the test; fixes should be made in UI rather than allow-listed.

## Current default audit

- Tests:
  - `CanadianHamPracticeUITests.testAccessibilityAuditNewScreensLight`
  - `CanadianHamPracticeUITests.testAccessibilityAuditNewScreensDark`
- Launch state: `-CanadianHamResetDataOnLaunch` plus a fixed `-CanadianHamInitialScreen` value per screen.
- Appearances: light and dark.
- Allow-list: none.
- Expected default evidence output: none beyond normal XCTest pass/fail output.

## Timing notes

The latest worker validation on iPhone 17 Pro simulator reported these XCTest durations in the full default iOS suite:

| Test | Duration |
| --- | ---: |
| `testAccessibilityAuditNewScreensDark` | 56.550 s |
| `testAccessibilityAuditNewScreensLight` | 54.505 s |
| `testMockExamHappyPathWithDeterministicSeed` | 28.797 s |
| `testPracticeImmediateFeedback` | 12.606 s |
| `testSettingsResetConfirmation` | 13.983 s |
| Unit tests | 0.981 s total |

## Historical T-516 note

Earlier T-516 evidence in `apps/apple/docs/a11y-evidence/` remains historical diagnostic output. It should not be treated as refreshed evidence for the expanded progress/practice/mock/settings slice unless the opt-in diagnostic harness is explicitly re-run.
