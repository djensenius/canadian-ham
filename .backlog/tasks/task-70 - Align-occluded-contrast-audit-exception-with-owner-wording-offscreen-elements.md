---
id: TASK-70
title: >-
  Align occluded-contrast audit exception with owner wording (offscreen
  elements)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 03:00'
updated_date: '2026-10-23 07:57'
labels: []
dependencies: []
priority: high
type: task
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22 (owner: make the best decisions you can; coordinator direction): align the shared occluded-contrast exception with the owner decision of 2026-10-12. Ignore only contrast audit findings whose non-zero element frame is not fully contained in the visible scroll area below an opaque navigation bar, including fully offscreen scroll-content descendants because the audit renders offscreen content as black. Remove only the scroll-frame intersection prerequisite in every helper copy, preserving nil-element, navigation-bar, ancestry, visible-containment checks and logging. Fully visible contrast and all non-contrast findings must still fail. Lone bullet and Question N of M false positives are conditional follow-up work, not granted by this task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every occluded-contrast helper copy removes only the scrollFrame.intersects(frame) prerequisite and retains contrast-only, non-nil/non-zero frame, navigation exclusion, scroll ancestry, visible containment, and logging; lesson copies remain byte-identical.
- [ ] #2 AGENTS.md records the dated 2026-10-22 clarification including fully offscreen content and explicitly states that fully visible bullet and Question N of M exceptions are not yet granted.
- [ ] #3 Document or unit-test frame classification for fully offscreen, partially visible, fully visible, non-contrast, and nil-element cases without a significant helper refactor.
- [ ] #4 Discover all direct and transitive helper-calling UI tests and record per-test targeted iPhone 17 Pro results plus iPad reference-sheet helper caller results; failures remain visible and are escalated rather than widening exceptions.
- [ ] #5 Run the test-guard self-test and diff check using Test-guard-approved: owner decision 2026-10-22; record commands and skipped-platform rationale.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect all helper copies and discover direct/transitive test callers, including reference-sheet iPad paths.
2. Remove only the four intersection guards; document the dated scope in AGENTS.md. Keep inline classification if extraction significantly rewrites the four audit bodies; document the classification truth table.
3. Run all helper caller tests with targeted -only-testing selections through xbuild in two nohup batches (iPhone default/figure plans, iPad reference sheet), recording per-test outcomes. Run the guard self-test and approved diff guard.
4. Record evidence, finalize the verified task, commit and push the branch without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
ID reconciliation: CLI allocated TASK-70 because the parallel Study-title lane reserved TASK-69. Coordinator approved keeping TASK-70 and renaming this branch to task-70-occluded-helper-align.
Classification kept inline: extracting audit type, optional XCUIElement/frame, nav-frame matching, and ancestry into a shared pure predicate would significantly rewrite all four existing audit closures for a one-line-per-copy change. The permitted documentation fallback is used: contrast + non-nil positive frame + non-nav + scroll descendant is ignored iff visibleScrollArea does not contain its frame. Fully offscreen -> ignored; partially visible -> ignored; fully visible -> not ignored; non-contrast -> not ignored (first guard); nil element -> not ignored (second guard); zero-size/nav/non-descendant -> not ignored. No bullet/header exception added.

Validation setup: source/call-graph scan found 66 helper-calling methods (45 LessonFigures, 10 Practice, 11 ExamTools), including indirect wrapper/scenario calls. Run 1: CanadianHamDefault, 19 selected methods, iPhone 17 Pro. Run 2: CanadianHamLessonFigures, 47 selected methods, iPhone 17 Pro. Run 3: CanadianHamDefault, iPad Pro 11-inch (M5), iOS 27.0, official-reference-sheet four-way EN/FR/light/dark caller plus iPad-only regular-width inspector caller. All runs use xbuild -parallel-testing-enabled NO and individual -only-testing: selectors in two sequential nohup batches, never killing any builds. Manifests/commands: /tmp/task70-test-manifest.json, /tmp/task70-commands.json. Result bundles/logs: /tmp/task70-{iphone-default,iphone-figures,ipad}.{xcresult,log}; batch scripts/logs /tmp/task70-{iphone,ipad}-batch.{sh,log}. iPhone currently waiting on the shared build lock.
Static proof passed: each Swift file is byte-identical to base 49b318df except the approved intersection-line removal; all four complete audit closures remain byte-identical to one another (reference-sheet setup remains unchanged). git diff --check passed. node scripts/check-test-guard.mjs --self-test passed. TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-22" node scripts/check-test-guard.mjs --base 49b318df --head HEAD passed with the expected approved helper/audit warnings. PR must carry that marker on its own line.
No macOS/tvOS/visionOS suites: only iOS UI-test helpers and documentation changed, no app/package/other-platform target code. No full iOS suite or title sweep: selection is limited to actual callers, including all affected figure tests in their required figure plan.

Targeted iPhone default-plan run PASS (rc=0): 19 executed, 18 passed, 1 pre-existing iPad-only skip, zero failures. iPad-only inspector caller is additionally queued on iPad. Per-test output:
```text
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditHintedAnswerResultLightAndDark]' passed (219.109 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditHintToolLightAndDark]' passed (82.390 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark]' passed (70.494 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark]' passed (75.135 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testLessonQuizHintsDarkAndFullAccessibilityAudits]' passed (299.761 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testLessonQuizHintsLightAndFullAccessibilityAudits]' passed (172.796 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testOfficialReferenceSheetLightAndDarkEnglishAndFrench]' passed (275.152 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testReferenceSheetLargestDynamicTypeKeepsControlsReachable]' passed (133.732 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testRegularWidthInspectorAccessibilityAuditLightAndDark]' skipped (11.827 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingeStableSlightOpenPeeksHintOneInPractice]' passed (25.009 seconds).
Test Case '-[CanadianHamUITests.CanadianHamExamToolsUITests testSizeClassRegularInspectorAccessibilityAuditLightAndDark]' passed (69.887 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowDark]' passed (126.711 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowLight]' passed (134.396 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryDark]' passed (537.176 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryLight]' passed (518.421 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionDark]' passed (120.367 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionLight]' passed (117.976 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testLessonPrerequisiteNavigationAndAccessibilityDark]' passed (51.673 seconds).
Test Case '-[CanadianHamUITests.CanadianHamPracticeUITests testLessonPrerequisiteNavigationAndAccessibilityLight]' passed (60.493 seconds).
	 Executed 19 tests, with 1 test skipped and 0 failures (0 unexpected) in 3102.505 (3102.885) seconds
	 Executed 19 tests, with 1 test skipped and 0 failures (0 unexpected) in 3102.505 (3102.887) seconds
** TEST SUCCEEDED **
```
Command (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer):
```sh
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -parallel-testing-enabled NO -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/task70-iphone-default.xcresult -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAccessibilityAuditHintToolLightAndDark -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAccessibilityAuditHintedAnswerResultLightAndDark -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testRegularWidthInspectorAccessibilityAuditLightAndDark -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testSimulatedHingeStableSlightOpenPeeksHintOneInPractice -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testSizeClassRegularInspectorAccessibilityAuditLightAndDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testLessonPrerequisiteNavigationAndAccessibilityDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testLessonPrerequisiteNavigationAndAccessibilityLight test CODE_SIGNING_ALLOWED=NO
```
Figure-plan run is now waiting for the shared build lock; no builds interrupted.

Long-running figure sweep progress at 2026-10-23 06:27 UTC: first 27/47 methods passed with no failures (modules 1–4 complete, module 5 in progress). Timings are 181–492 seconds per method so far. Existing xbuild run remains untouched; iPad batch still queued after it.

Figure sweep encountered one infrastructure-style audit failure: CanadianHamLessonFiguresUITests.testModule7LessonFiguresLightPart1 failed after 436.543s with com.apple.xcode.xctest.accessibilityAudit Code=-56, Audit failed to complete in time (no contrast or other accessibility finding reported). The following three figure methods passed; remaining selections are still running. Will rerun only this failed method after the existing batches finish, per targeted fix-round policy; no test or source changes and no interruption of running builds.
<!-- SECTION:NOTES:END -->
