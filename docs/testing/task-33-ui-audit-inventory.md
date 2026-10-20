# TASK-33: iOS audit coverage and launch-sharing diff

Baseline source: `e7a1dfa7` (main when this task branch was created). The older
[task-31 inventory](ui-audit-inventory-after.md) remains historical; the tables below
also include later prerequisite, sending-exam, Settings text-size, and hint audits.
Only the iOS UI test target and its scheme/plans change. No app code changes.

## Changed audit flows: before → after

Each row below applies independently to **light and dark**. “Top” means the initial
screen/scroll position, not a lower-content substitute. Every original assertion and
`performAudit` call (including its context string) is retained with the same multiplicity.
The plain audit and approved-exception implementations are unchanged.

| Screen/state | Region | Before test | After test | Audit |
| --- | --- | --- | --- | --- |
| Compact root list, reset Basic data | Top | `testAccessibilityAuditCoreScreens{Light,Dark}` | Same | Plain |
| Home, reset Basic data | Top | Same | Same | Plain |
| Practice hub, reset Basic data | Top | Same | Same | Plain |
| Mock exam start, reset Basic data | Top | Same | Same | Plain |
| Learn module list, reset Basic data | Top | Same | Same | Plain |
| Settings, reset Basic data | Top | Same | Same | Plain |
| Morse home, reset Basic data, no playback | Top | Same | Same | Plain |
| About, Basic bank | Top | Same | Same | Plain |
| Forced store-open failure | Recovery screen | Same | Same | Plain |
| Morse sending practice, debug hook, 600-second exam setting, no key input | Main screen | `testAccessibilityAuditMorseSendingMainScreen{Light,Dark}` | `testAccessibilityAuditMorseSendingMainAndExamScreens{Light,Dark}` | Plain |
| Same sending session, feedback positioned and settled below opaque bar | Lower half | Same | Same | Plain |
| Morse sending exam, 600-second setting, started and unanswered | Exam card | `testAccessibilityAuditMorseSendingExamScreen{Light,Dark}` | `testAccessibilityAuditMorseSendingMainAndExamScreens{Light,Dark}` | Plain |

**Coverage delta: 24 screen/state/appearance/region tuples before, 24 after; none removed.**

### Why these launches can be shared

- Core: seven read-only destinations share the same reset Basic store, preferences,
  locale, appearance, and initial scroll position. `RootView.applyLaunchNavigation`
  and the compact navigation links construct the same `RootNavigationRoute` stacks:
  root → section for Home/Practice/Learn/Morse/Settings, and root → Settings → About.
  Back navigation removes the section before entering the next. No practice/exam is
  started, lesson read, preference changed, or Morse audio played. Settings is audited
  before scrolling to its About link. The mock fixture retains its own launch and
  exact root → Practice → Mock stack; forced-store failure retains its separate
  non-reset launch. Launches per appearance: **9 → 3**.
- Sending: both original fixtures used exactly the same launch arguments (Morse,
  sending debug hook, 600-second exam duration). The first two audits only inspect
  and scroll the untouched sending screen. The existing `openSendingExamStyleCheck`
  positions/taps the same exam entry before the unchanged start/card assertions and
  audit. Results retain their distinct 120-second fixture. Launches per appearance:
  **2 → 1**. No appearance changes while either app is running.
- Dark test wrappers restore appearance only through the existing teardown, which
  terminates the app first. Initial appearance assignments remain before launch.
  Tests whose names contain `LightAndDark` already terminate between launches and
  are unchanged.

### Removed method → moved assertions (test-guard approval justification)

| Removed method | Destination |
| --- | --- |
| `testAccessibilityAuditMorseSendingMainScreenLight` | `testAccessibilityAuditMorseSendingMainAndExamScreensLight`, main/top and lower-half assertions/audits in `auditMorseSendingMainAndExamScreens` |
| `testAccessibilityAuditMorseSendingExamScreenLight` | Same combined light method, exam-start and exam-card assertions/audit after the lower-half audit |
| `testAccessibilityAuditMorseSendingMainScreenDark` | `testAccessibilityAuditMorseSendingMainAndExamScreensDark`, main/top and lower-half assertions/audits in `auditMorseSendingMainAndExamScreens` |
| `testAccessibilityAuditMorseSendingExamScreenDark` | Same combined dark method, exam-start and exam-card assertions/audit after the lower-half audit |

All four wrappers only assigned appearance and called their flow. Their combined
flow retains all original assertions and all three audit sites. Only the duplicated
launch/termination and second `openSendingPractice` navigation were removed. No other
test method is removed. The eventual PR body must contain this standalone line:

Test-guard-approved: task-33

## Unchanged default-plan audit inventory

All functions, assertions, loops, fixtures, appearance pairs, positioning, and audit
implementations for these call paths are byte-identical to baseline, except redundant
end-of-test light restoration in dark wrappers (now handled by terminate-first teardown).
Each row names the source entry point(s), not merely a general screen category.

| Entry point(s) in `CanadianHamPracticeUITests` | State/appearance/region coverage retained |
| --- | --- |
| `testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice` | French light Home and unanswered practice; all other French navigation assertions retained |
| `testSettingsLanguageControlSupportsLargestAccessibilityTextSize` | English and French light Settings language control, accessibility XXXL, fully visible below navigation bar |
| `testAccessibilityAuditMorse{Beacon,Tape}Output{Light,Dark}` | Each output during and after playback, fully visible |
| `testAccessibilityAuditMorseCourseLessonAndSummary{Light,Dark}` | Morse home top/lower settings, course home top/lower final unit, unit 1, lesson session, summary; exact existing per-region exception handlers retained |
| `testAccessibilityAuditMorseSendingResults{Light,Dark}` | Graded sending result, distinct 120-second fixture |
| `testAccessibilityAuditMorseExamGradedDiff{Light,Dark}` | Character-diff result and start-another affordance, all three iterations per appearance |
| `testAccessibilityAuditPracticeSession{Light,Dark}` | Unanswered, incorrect feedback, exact correct feedback, review top, review lower feedback; separate reset/mode fixtures retained |
| `testLessonPrerequisiteNavigationAndAccessibility{Light,Dark}` | L-006-03 prerequisite block and tapped L-006-02 destination reader |
| `testAccessibilityAuditLearnFlow{Light,Dark}` | Module list, L-006-03 reader top, answered one-question quiz |
| `testOhmsLawLessonFiguresAndAccessibility{Light,Dark}` | All three L-005-02 figures inline and enlarged; expanded power-wheel equivalent, all 12 row assertions; enlarged sheets keep plain audit |
| `testAccessibilityAuditMockExamFlow{Light,Dark}` | Timer question, timer navigator, answered/flagged question, answered/flagged navigator, results top, results lower details; distinct fixtures retained |
| `testAccessibilityAuditAdvancedCourseScreens{Light,Dark}` | Advanced picker, coming-lessons view, hub, unanswered practice, mock start, unanswered 50-question mock, results; all distinct initial-screen fixtures retained |
| `testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight`, `testCourseSwitchConfirmationAuditsDark` | Unfinished mock course-switch confirmation; cancellation and retained-session assertions |

`CanadianHamExamToolsUITests.swift` is **entirely byte-identical**, including all these
current audit entry points (and all existing platform guards):

| Entry point(s) | State/appearance/region coverage retained |
| --- | --- |
| `testAccessibilityAuditExamTools{Light,Dark}` | Compact calculator medium detent, 24-key/display/Close prechecks, existing capped clipping exception |
| `testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark` | Compact large detent, keyboard help visible, occluded-content rule |
| `testAccessibilityAuditHintToolLightAndDark` | Both hints revealed, large compact sheet or iPad inspector, existing platform branches |
| `testAccessibilityAuditHintedAnswerResultLightAndDark` | First hint revealed, tool closed, answer A submitted, feedback fully positioned |
| `testRegularWidthInspectorAccessibilityAuditLightAndDark` | iPad portrait and landscape inspector, both appearances; existing iPhone platform guard unchanged |
| `testSizeClassRegularInspectorAccessibilityAuditLightAndDark` | Forced regular size-class inspector, both appearances; existing native-sheet adaptation branch unchanged |
| `testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark` | Accessibility XXXL calculator, reciprocal key reached by scrolling, both appearances |

All tvOS, visionOS, and app/unit-test sources remain untouched. The default plan still
contains the complete unit-test target and every non-figure UI test; it does not narrow
any existing audit method or platform guard.

## Figure-plan inventory diff

`CanadianHamLessonFiguresUITests` moves intact out of `CanadianHamDefault` into
`CanadianHamLessonFigures`. This is a plan-membership change, **not removal of audits**.
The figure spec arrays (including IDs and alt text), dark sample selection, verifier,
launch arguments, screenshots, positioning, and exception helper remain byte-identical.
Every light lesson is still visited exactly once, every listed figure is still audited,
and every module's first figure is still sampled in dark appearance.

| Module | Light lessons before → after | Light figures before → after | Dark samples before → after |
| --- | --- | --- | --- |
| M1 | 6 → 6 | 6 → 6 | 1 → 1 |
| M2 | 4 → 4 | 4 → 4 | 1 → 1 |
| M3 | 8 → 8 | 8 → 8 | 1 → 1 |
| M4 | 3 → 3 | 3 → 3 | 1 → 1 |
| M5 | 6 → 6 | 8 → 8 | 1 → 1 |
| M6 | 5 → 5 | 5 → 5 | 1 → 1 |
| M7 | 3 → 3 | 3 → 3 | 1 → 1 |
| M8 | 2 → 2 | 2 → 2 | 1 → 1 |
| **Total** | **37 → 37** | **39 → 39** | **8 → 8** |

Thirteen two-lesson ranges become single-lesson ranges. The existing `PartN` method
keeps the first lesson and any original evidence request; `PartNNextLesson` holds the
second. Existing one-lesson methods and all eight dark methods are unchanged. This
raises figure methods from 32 to 45 without changing audit/figure coverage or launches.
M1 Part 2 already covers only L-001-03's single figure after the lesson split, unlike
the older content behind the historical timeout; it remains covered in the figure run.

## Verification and counts

- Source comparison: all common functions byte-identical except the two edited audit
  flows, the 13 figure range splits, and dark-wrapper restoration. Exact assertion/audit
  call-line multisets match for both edited flows. All nine direct
  `performAccessibilityAudit` sites, named shared/exception helpers, positioning helpers,
  and complete figure spec arrays are unchanged. Range multisets match for all 37 light
  lessons; eight dark sample methods are byte-identical.
- Original scheme: **160 UI methods** (128 non-figure + 32 figure).
- Before launch sharing, new default membership: **128 UI methods**.
- After launch sharing: **126 default UI methods**, plus **45 figure-only methods**.
- Core and sending launch count: **22 → 8** across both appearances (14 fewer), with
  identical 24 audit tuples. Other launches and all unchanged audit loops remain.
- Runtime wall clocks, executed counts, per-test results, and any existing skips/flakes
  are recorded separately in the task notes and runtime evidence document.
