---
id: TASK-77
title: >-
  Mock exam header: replace the inner ViewThatFits and let the default navigator
  sheet scroll
status: Done
assignee:
  - '@worker'
created_date: '2026-10-26T16:14:00Z'
updated_date: '2026-10-27T21:46:00Z'
labels:
  - accessibility
  - layout
dependencies: []
priority: low
ordinal: 162000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the TASK-74 review. The mock header still has two inner ViewThatFits (flagAndNavigatorControls, quickJumpControls). Under the owner's 2026-10-18 single-tree layout rule, they should become measured-fit single-tree layouts like MockExamHeaderControlLayout, because rejected candidates can leak accessibility nodes the way TASK-74's outer header did. Also, the default-size iPhone question navigator sheet doesn't scroll (TASK-74 fixed only accessibility sizes); with a 100-question exam in iPhone landscape, the grid probably doesn't fit.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Both inner ViewThatFits in the mock header are replaced by single-tree measured-fit layouts, with pixel-identical before/after screenshots in every layout they choose
- [x] #2 The question navigator sheet scrolls at every text size; a 100-question mock exam's full grid is reachable in iPhone portrait and landscape
- [x] #3 The targeted iPhone and iPad mock exam tests and audits pass via xbuild
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing measured-fit layouts, mock fixtures, and TASK-74 capture procedure; capture baseline header and fitting navigator states with temporary UI probes.
2. Replace the two inner header candidate trees with measured-fit single-tree layouts and make the sheet content always scrollable without changing fitting geometry; add 100-question portrait/landscape reachability coverage.
3. Capture matching after states and record exact native RGB diffs/SHA-256s with a small representative evidence set.
4. Run the TASK-74 nine-method set plus the new test on iPhone/iPad through xbuild, macOS build-for-testing, text-source and guard checks; commit/push milestones, record per-test results, and finalize criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestones pushed: bf03db03 adds the full 100-question portrait/landscape regression; 343bbf49 reuses MockExamHeaderControlLayout for both inner control groups and makes the compact sheet always scrollable. Baseline native appearance capture passes on iPad (106.539 s) and iPhone (272.889 s); final appearance/new-test and nine-method TASK-74 runs are queued via xbuild with one destination/worker each. No audit/assertion/helper changes or exceptions.

The first complete requested product matrix passed: 10/10 methods on iPad and 10/10 on iPhone, including 100-question portrait/landscape selection. Header visual comparisons are 20/20 exact native RGB matches so far. Fitting-sheet comparison caught full-height paper-background/subpixel-centering differences introduced by the initial ScrollView container; changed only that container to measured available-height centering with the paper background retained on the original content. Its affected iPhone flow/navigation rerun is waiting on the shared xbuild lock. Additional AX captures explicitly position early controls; the first temporary positioning probe exposed coarse-scroll oscillation (diagnostic-only failure), so its local probe now uses the unchanged existing precise-scroll helper. No product assertion/audit or shared helper changed.

Resumed after the long shared-lock wait. The final fitting-sheet container passes both exact full-modal comparisons (0 differing pixels light/dark), all four affected iPhone product methods pass, fixed AX baseline/after probes pass (506.544/504.434 s), and final macOS build-for-testing passes with scratch source removed. Evidence inspection then found XCUIApplication.screenshot() truncates landscape PNGs (1416-column full-height black strip), so numeric landscape matches did not prove whole-screen parity. Coordinator approved replacing only landscape evidence with one XCUIScreen.main.screenshot() baseline/after pair, a local attachment-only change in the new full-grid test plus one iPhone rerun, and a one-line TASK-74 doc correction. Full-screen baseline passes (423.610 s): all 12 landscape captures orient to 2622x1206 and have zero all-black rows/columns. Matching after/new-test run is queued behind other xbuild work; no build interrupted.

Final evidence/source milestone: e31391521320b73cf1cc1352aa3f77881e06d671, pushed on task-77-mock-header-layouts. AC1: both inner controls reuse unchanged MockExamHeaderControlLayout; docs/evidence/task-77/visual-diffs.json proves 34/34 exact native RGB comparisons (32 header views + 2 fitting-sheet views), all 0 differing pixels / max channel difference 0. The 12 corrected full-screen landscape pairs use XCUIScreen.main.screenshot(): all 24 source PNGs orient to 2622x1206 and have zero all-black rows/columns; raw sizes, EXIF orientation, SHA-256s, control frames and exact bounds are recorded. The one approved full-screen baseline/after run pair passed 423.610/324.026 s with no further iteration. TASK-74's landscape partial-image claim is corrected in its doc. Four representative native after PNGs plus JSON/hierarchies total 1,292,650 bytes.

AC2: the navigator always scrolls; measured available-height framing and the original content background preserve fitting appearance exactly in light/dark. The new real 100-question Basic exam method reaches and taps question 100 in portrait and landscape, verifies current state and Question 100 of 100; latest iPhone PASS 119.842 s after its local full-screen attachment-only change, iPad PASS 92.446 s. No short question-limit fixture is used.

AC3: all ten requested product methods PASS on each device (20 product results, no skips). The four affected iPhone Practice methods passed again after the fitting-container repair; six unaffected ExamTools results and the unchanged regular-width iPad results carry forward. Final macOS build-for-testing PASS (/tmp/task77-macos-final-build.log, exit 0), with all scratch probes removed before compilation. Later screenshot attachment code is inside #if os(iOS), with no macOS-visible change. node scripts/check-apple-text-sources.ts, guard --self-test, guard --base 3872dc54 --head HEAD (no findings/approval marker), git diff --check and evidence manifest integrity all PASS. ExamToolsUITests is byte-identical to base; existing Practice assertions/audits/helpers remain unchanged. No scratch test, new audit exception, shared-helper change, point-width threshold, PR or distribution build ships.

Per-test product results (iPad / iPhone; seconds); complete logs/bundles and commands in docs/testing/task-77-mock-header-layouts.md and docs/evidence/task-77/test-results.json:

| `CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints` | PASS 19.377 s | PASS 38.657 s |
| `CanadianHamExamToolsUITests/testMockExamCodeCaptionAccessibilityBoundsLightAndDark` | PASS 31.675 s | PASS 48.094 s |
| `CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam` | PASS 106.693 s | PASS 209.385 s |
| `CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam` | PASS 140.035 s | PASS 202.793 s |
| `CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench` | PASS 186.827 s | PASS 260.981 s |
| `CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable` | PASS 38.330 s | PASS 128.545 s |
| `CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark` | PASS 96.489 s | PASS 142.542 s |
| `CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight` | PASS 98.130 s | PASS 144.142 s |
| `CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize` | PASS 51.386 s | PASS 85.549 s |
| `CanadianHamPracticeUITests/testHundredQuestionMockExamNavigatorReachesLastQuestionInPortraitAndLandscape` | PASS 92.446 s | PASS 119.842 s |

TV, vision and watch suites skipped because StudyViews.swift is not in their target membership; no package/catalogue changes. Full iOS merge-batch suites and independent branch review remain coordinator responsibilities. All Apple commands used xbuild, one destination/worker, and waited for the shared lock; no builds were interrupted by this worker.

Coordinator, after the review (approve with notes): ran the missed affected test CanadianHamExamToolsUITests/testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet on iPhone 17 Pro, which passed (56.855 s). The new 100-question test now asserts that the window really is landscape in the landscape pass, and its Done check has a failure message; it passed again (109.590 s). The doc now says 6 'lower' records repeat their base case, so there are 28 distinct exact comparisons.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced both inner mock-header ViewThatFits trees with the existing measured-fit single-tree layout. Made the compact navigator scroll at every text size while preserving fitting default geometry/background. Added real-100-question portrait/landscape navigation coverage. All 20 requested product results, final macOS compilation, text-source and guard checks pass; 34 native comparisons are pixel-identical, including corrected full-screen landscape evidence (1.3 MB total). All previous assertions/audits/helpers remain intact, scratch probes are removed, and TASK-74's partial landscape screenshot claim is corrected. Branch pushed; no PR. Independent review and merge-batch full suites are next.
<!-- SECTION:FINAL_SUMMARY:END -->
