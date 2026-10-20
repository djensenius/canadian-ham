---
id: TASK-65
title: Investigate residual iOS heading-wait and single-figure audit flakes
status: To Do
assignee: []
created_date: '2026-10-20 06:58'
updated_date: '2026-10-20 10:39'
labels:
  - apple
  - testing
dependencies: []
references:
  - docs/testing/task-33-ios-results.md
priority: low
type: bug
ordinal: 140000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-33 required iPhone 17 Pro runs exposed three unchanged test flakes. (1) testAccessibilityAuditMorseSendingResultsLight failed before its audit because morse-sending-results-heading did not exist within the existing 5-second wait after Grade (CanadianHamPracticeUITests.swift:1708, /tmp/task-33-after.log; dark passed67.311s and historical light passed72.445s). (2) testOhmsLawLessonFiguresAndAccessibilityDark failed with XCTest accessibilityAudit Code=-56, Audit failed to complete in time (471.508s, /tmp/task-33-after.log). Its light/dark pure-figure methods were moved intact into the figure plan under supervisor approval. (3) testModule7LessonFigureDarkSample failed with the same XCTest Code=-56 (230.276s, /tmp/task-33-figures.log); it already audits one lesson and one figure, so it cannot be range-split further. All audit/positioning/exception helpers are byte-identical to branch baseline. Raw result bundles share the corresponding log basename; durable per-test output is in docs/testing/task-33-ios-results.md. Supervisor approved one low-priority follow-up covering all three; investigate Grade interaction/results transition and residual single-figure audit timing without assuming longer waits or suppressing audit failures.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The causes of the intermittent post-Grade missing heading and residual single-figure XCTest audit timeouts are investigated with failure evidence, targeted reproduction, and host-load observations.
- [ ] #2 Relevant light/dark sending-results and Ohms-law/M7 figure tests retain every existing assertion and accessibility audit without skips, narrowed audit types, or relaxed exception handlers.
- [ ] #3 Targeted iPhone 17 Pro results for the affected methods and any residual flakiness are recorded; do not repeat full suites solely for this follow-up.
<!-- AC:END -->
