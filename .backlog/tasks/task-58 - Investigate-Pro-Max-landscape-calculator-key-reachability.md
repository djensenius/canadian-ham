---
id: TASK-58
title: Investigate Pro Max landscape calculator key reachability
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 06:03'
updated_date: '2026-10-20 00:15'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline reproduced at 79b47a9e (main after TASK-60): iPhone 17 Pro Max OS 27.0 targeted xbuild exited 65. Test failed after 132.787s at CanadianHamExamToolsUITests.swift:1352 with "Failed to get matching snapshot" for calculator-key-percent. Evidence: /tmp/task-58/reproduce.log, /tmp/task-58/reproduce.xcresult, /tmp/task-58/reproduce-attachments/. The test-local scrollCalculatorPanelUntilElementExists helper reads element.identifier in its context string while !element.exists, causing XCTest to fail before the first swipe. The failure hierarchy shows five lazy-grid rows through equals (y356.7...402.7) inside the calculator ScrollView (y86.7...408), with the sixth row not yet instantiated. Replaced only that premature identifier lookup with literal diagnostic context; no product layout change is warranted unless corrected scrolling reveals an actual reachability issue. All assertions and guarded shared helpers remain unchanged.

Corrected targeted Pro Max OS 27.0 reachability test passed (xbuild exit 0): /tmp/task-58/fixed-reachability.log and /tmp/task-58/fixed-reachability.xcresult. Product already scrolls every key correctly; this is a genuine test-helper snapshot bug, not a sheet/home-indicator/detent defect. Supervisor reviewed implementation commit 78a2857e33741199f2035e0110cf0b4aaedd8bdc and approved the test-only fix before PR creation. Test guard passed with no guarded changes. Remaining device matrix is running via /tmp/task-58/verify.sh.
<!-- SECTION:NOTES:END -->
