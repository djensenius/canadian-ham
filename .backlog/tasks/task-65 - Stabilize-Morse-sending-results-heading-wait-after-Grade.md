---
id: TASK-65
title: Investigate residual iOS heading-wait and single-figure audit flakes
status: To Do
assignee: []
created_date: '2026-10-20 06:58'
updated_date: '2026-10-21 23:42'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
TASK-33 final evidence (all tests unchanged; no flake fix claimed):
1. Sending-results light failed at the 5 s post-Grade heading wait in /tmp/task-33-after.log (78.654 s); isolated /tmp/task-33-sending-results-rerun.log passed 91.923 s, outer wall208 s, exit0.
2. Ohms-law dark failed with accessibilityAudit Code=-56 in /tmp/task-33-after.log (471.508 s); the figure full run subsequently passed dark1316.588 s and light1321.591 s; isolated /tmp/task-33-ohms-dark-rerun.log passed1217.286 s, outer wall1253 s, exit0. Both pure-figure methods moved intact into the figure plan.
3. Single-figure M7 dark failed with Code=-56 in /tmp/task-33-figures.log (230.276 s); coordinator-run isolated /tmp/task-33-m7-dark-rerun.log passed257.999 s, outer wall402 s, exit0. It already has one lesson and one figure and cannot be range-split further.
Full-run totals: default126 UI (superset of final124),3 existing skips,2 failures, UI elapsed11390.378 s/outer11533 s; figure47 UI,1 failure, elapsed11444.382 s/outer11520 s. Units190 passed. Complete per-test results and literal failure lines: docs/testing/task-33-ios-results.md; result bundles use corresponding /tmp log basenames.
Host-load evidence at2026-10-20T10:39:35Z: load81.94/81.56/88.02, simulator testmanagerd99.9%CPU, two lockf84.9%/84.1%, host/simulator diagnosticd55.8%/50.2%, exactly one active xcodebuild observed. Coordinator confirmed FluxTerm builds shared the xbuild lock. No other lane process stopped; contention is context, not demonstrated causation. Supervisor approved TASK-33 acceptance with these documented unchanged failures plus passing isolated reruns; this follow-up remains To Do.

TASK-46.6.1 follow-up (supervisor-approved addition, 2026-10-21): the NEW concept-check AX-XXXL method testLessonQuizConceptOptionFeedbackLargestDynamicType passes its option-feedback/explanation text and full-visibility assertions, then its second full default audit auto-scrolls to the unchanged quiz header and reports Contrast for fully visible Question 1 of 1. Reproduced on iPhone 17 Pro twice without source changes: /tmp/task-46.6.1-iphone-largest-fix.log (184.329 s) and /tmp/task-46.6.1-iphone-largest-retry.log (196.875 s); matching xcresult basenames. Both element screenshots have the identical payload hash and show near-black ink on paper, not the new feedback. Screenshots: /tmp/task-46.6.1-contrast-app.png, /tmp/task-46.6.1-contrast-element.png and -contrast-retry-app/element.png. The first full option-status audit passed; second audit of the fully visible existing explanation reports the header. Investigate audit auto-scroll/timing/contrast false-positive provenance; no claim that host load is causal. The unchanged approved occluded-only contrast helper correctly fails this fully visible finding and was not changed or narrowed. Four default-size light/dark option-feedback audits pass. An unrelated existing hint AX-XXXL restore test also failed once then passed an unchanged targeted retry (269.356 s). No full suites or additional audit exception.
<!-- SECTION:NOTES:END -->
