---
id: TASK-77
title: >-
  Mock exam header: replace the inner ViewThatFits and let the default navigator
  sheet scroll
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-26T16:14:00Z'
updated_date: '2026-10-27T13:25:00Z'
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
