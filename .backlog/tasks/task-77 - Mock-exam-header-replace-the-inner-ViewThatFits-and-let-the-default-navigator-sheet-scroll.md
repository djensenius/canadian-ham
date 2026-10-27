---
id: TASK-77
title: >-
  Mock exam header: replace the inner ViewThatFits and let the default navigator
  sheet scroll
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-26T16:14:00Z'
updated_date: '2026-10-27T21:03:00Z'
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
- [ ] #1 Both inner ViewThatFits in the mock header are replaced by single-tree measured-fit layouts, with pixel-identical before/after screenshots in every layout they choose
- [ ] #2 The question navigator sheet scrolls at every text size; a 100-question mock exam's full grid is reachable in iPhone portrait and landscape
- [ ] #3 The targeted iPhone and iPad mock exam tests and audits pass via xbuild
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
<!-- SECTION:NOTES:END -->
