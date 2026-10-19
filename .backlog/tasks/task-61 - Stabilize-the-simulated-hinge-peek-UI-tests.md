---
id: TASK-61
title: Stabilize the simulated hinge peek UI tests
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-19 12:49'
updated_date: '2026-10-19 15:22'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Establish a baseline by repeatedly running the CanadianHamExamToolsUITests testSimulatedHinge* methods on the requested iPhone 17 Pro, iPad Pro 13-inch (M5), and iPhone Duo destinations before product/test edits.
2. Inspect the simulated hinge UI-test helpers and DEBUG posture/playback hooks to identify race points around sequence start, elapsed sleeps, and no-reopen assertions.
3. Make only DEBUG/test-seam changes needed for deterministic synchronization: gate simulated playback on an explicit readiness trigger, wait for playback progress/state instead of wall-clock sleeps, and keep existing assertions intact or stricter.
4. Re-run the repeated targeted matrix on the branch, record per-test/device evidence, finalize TASK-61, commit, push, and open the PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline repeated hinge run on main/current branch before edits (logs /tmp/task61-baseline-20261019085207): iPhone 17 Pro 3x showed testSimulatedHingeDismissedPeekReopensOnlyAfterReset 2 pass/1 fail and the other four simulated hinge tests 3/3 pass; iPad Pro 13-inch (M5) 3x showed testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip 0 pass/3 fail at playback progress stuck at 7.500 waiting for 60.4, and the other four 3/3 pass; iPhone Duo once showed the lesson round-trip hinge test failed at the known TASK-54 navigation back-button exposure limitation and the other four passed.
Implemented DEBUG-only triggered simulated hinge segments and a UI-test trigger so playback starts only after each test reaches the state it wants to assert; replaced sleeps/long absolute timestamps with waits on debug-hinge-playback-progress and kept the no-reset/reopen/fast-unfold/mock-exam assertions. Branch validation is queued behind the shared xbuild lock in /tmp/task61-after2-driver.log.
<!-- SECTION:NOTES:END -->
