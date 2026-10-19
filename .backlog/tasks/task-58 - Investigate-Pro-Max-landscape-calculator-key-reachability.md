---
id: TASK-58
title: Investigate Pro Max landscape calculator key reachability
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 06:03'
updated_date: '2026-10-19 23:57'
labels:
  - apple
dependencies: []
priority: low
type: bug
ordinal: 136000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The iPhone 17 Pro Max targeted run reproduced a main-branch failure in CanadianHamExamToolsUITests.testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey: the test could not find the calculator-key-percent control in the forced-regular landscape medium sheet. This is separate from TASK-15 Duo layout work and should be diagnosed without weakening the calculator reachability coverage.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The iPhone 17 Pro Max forced-regular landscape medium-sheet calculator-key-percent failure is reproduced or shown no longer reproducible with a targeted xbuild UI-test run
- [ ] #2 The underlying calculator sheet reachability issue is fixed without deleting, skipping or weakening the calculator key reachability assertions
- [ ] #3 Targeted iPhone 17 Pro Max CanadianHamExamToolsUITests validation is recorded with log paths
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reproduce the existing targeted forced-regular landscape calculator failure on iPhone 17 Pro Max with xbuild.
2. Inspect calculator sheet layout and test-local scrolling to identify the root cause; apply the smallest adaptive layout or test-local helper fix without weakening reachability/44 pt assertions or changing guarded shared helpers.
3. Run targeted landscape/calculator tests on Pro Max and Pro, the landscape reachability test on Duo OS 27.1, and macOS unit tests; record per-test evidence.
4. Finalize task evidence, commit, and submit for required review before opening the requested PR.
<!-- SECTION:PLAN:END -->
