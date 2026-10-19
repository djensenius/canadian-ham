---
id: TASK-61
title: Stabilize the simulated hinge peek UI tests
status: To Do
assignee: []
created_date: '2026-10-19 12:49'
labels:
  - apple
  - tests
dependencies: []
priority: high
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The DEBUG simulated-hinge UI tests from TASK-15 part 2 fail intermittently on several devices and branches: testSimulatedHingeDismissedPeekReopensOnlyAfterReset (iPhone 17 Pro, 50.13 branch, passed earlier), testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip (iPad Pro 13, TASK-60 branch; Duo). Logs: /tmp/task-50.13-final-iphone-examtools-learn.log, /tmp/task-60-final-ipadpro.log, /tmp/task-60-final-iphone-duo.log.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The hinge peek UI tests are run repeatedly on main (iPhone 17 Pro, iPad Pro 13-inch, iPhone Duo) to establish whether they are flaky, with results recorded
- [ ] #2 Timing-dependent waits are replaced with deterministic synchronization (for example the DEBUG hinge playback-progress hook) without weakening what the tests assert
- [ ] #3 The hinge tests pass reliably in repeated targeted runs on iPhone 17 Pro and iPad Pro 13-inch; any Duo-only failure is tied to TASK-54 with evidence
<!-- AC:END -->
