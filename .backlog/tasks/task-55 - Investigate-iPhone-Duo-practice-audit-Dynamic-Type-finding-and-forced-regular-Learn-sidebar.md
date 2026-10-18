---
id: TASK-55
title: >-
  Investigate iPhone Duo practice audit Dynamic Type finding and forced-regular
  Learn sidebar
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 02:16'
updated_date: '2026-10-18 20:02'
labels:
  - apple
dependencies:
  - TASK-15
priority: high
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-15 part 1 required iPhone Duo practice audits and Learn navigation runs. Both this branch and detached origin/main fail on the iOS 27.1 iPhone Duo simulator: CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight and Dark report 'Dynamic Type font sizes are partially unsupported' at CanadianHamPracticeUITests.swift:2321, and testLearnUserNavigationOpensLessonQuiz fails waiting for root-sidebar under forced-regular landscape. Branch log: /tmp/task15-duo-practice-targeted-20261017221133.log. Main log: /tmp/task15-main-duo-practice-targeted-20261017221356.log.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Identify the element or elements behind the Duo 'Dynamic Type font sizes are partially unsupported' audit finding and fix app code if it is an app issue; do not filter or weaken the audit
- [ ] #2 Make CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz pass on iPhone Duo, or document why forced-regular landscape has no root-sidebar on the iOS 27.1 Duo runtime
- [ ] #3 Rerun CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight, testAccessibilityAuditPracticeSessionDark and testLearnUserNavigationOpensLessonQuiz on iPhone Duo and record per-test results
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reproduce the two practice accessibility audits and forced-regular Learn navigation failure on the iPhone Duo 27.1 simulator with result bundles under /tmp, then export xcresult attachments and inspect complete issue descriptions/screenshots for the failing elements.
2. Trace the identified practice clipping and forced-regular Learn layout through the SwiftUI views/policy in iOS-shared app code, fixing only app layout bugs without audit filtering, minimumScaleFactor, hidden visible text, fixed widths, or hard-coded colours.
3. Rerun the targeted Duo and iPhone 17 Pro tests, including CanadianHamExamToolsUITests for regression, then record per-test results/log paths in task notes and finalize the task evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up 2026-10-18: TASK-55 depends on TASK-15 part 1 / PR #286 because it investigates Duo simulator practice audit/navigation failures found by that work; it does not need part 2 hinge-peek work except insofar as Backlog cannot express a dependency on part 1 only.
<!-- SECTION:NOTES:END -->
