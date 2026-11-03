---
id: TASK-54
title: >-
  Verify hardware keyboard input and navigation back-button accessibility on
  real iPhone Duo / iOS 27.1
status: In Progress
assignee:
  - '@coordinator'
created_date: 2026-10-18 01:53
updated_date: '2026-11-03T03:49:00Z'
labels:
  - apple
  - owner-gate
dependencies: []
ordinal: 133000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-15 part 1 found four iPhone Duo simulator failures that also reproduce on origin/main with the iOS 27.1 Duo runtime: calculator hardware-keyboard events do not reach the focusable/onKeyPress calculator path, and system NavigationBar back buttons are not exposed to XCTest after pushed destinations even though destination content appears. The simulator has no fold controls and only the Duo device type for iOS 27.1 on this host, so this needs confirmation on real hardware or a newer simulator before changing product behaviour.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Re-run CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen, testCalculatorKeyboardInputIsFocusScoped, testCalculatorValueResetsForNewMockExam and testHintToolLadderAndLessonLink on a real iPhone Duo or newer iOS 27.1+ simulator and record per-test results
- [ ] #2 Verify with VoiceOver or Accessibility Inspector that the lesson/result back affordance is reachable and correctly labelled on iPhone Duo
- [ ] #3 If the failures reproduce on real hardware, fix product code without weakening tests; if they do not, document the simulator limitation and keep TASK-15 tests unchanged
- [ ] #4 Verify on a real iPhone Duo that unfolded landscape (about 951x669 pt) uses the side-by-side question plus exam-tools inspector layout, unfolded portrait (about 669x951 pt) stays on the compact sheet, and fold/unfold in both directions during practice preserves the current question, selected answer and calculator value
- [ ] #5 Verify on a real iPhone Duo that the Hint 1 hinge peek triggers only in the implemented slight-open angle band (default 20–35° until hardware evidence says otherwise), and record the observed comfortable angle range.
- [ ] #6 Verify on a real iPhone Duo that the slight-open posture must dwell stably for about 0.7 s before Hint 1 peeks, including small edge jitter, and record pass/fail evidence.
- [ ] #7 Verify on a real iPhone Duo that a normal fold-to-unfold motion passing quickly through the peek band never reveals Hint 1.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up 2026-10-18: TASK-54 depends on TASK-15 part 1 / PR #286 for the Duo simulator classification and unfolded-layout hooks; it does not need part 2 hinge-peek work except insofar as Backlog cannot express a dependency on part 1 only.

From the #286 final review: (R2) record the safe-area width actually measured in unfolded landscape on hardware; the 800 pt rule uses the safe-area size, not the full window. (R3) check for a one-frame compact→split flash at launch on an unfolded Duo, since the first frame lays out before the size is measured.

TASK-60 (2026-10-19): the Duo unfolded layout is now driven by system size classes, not point widths. On real hardware, record for the unfolded Duo in portrait and in landscape: (1) the horizontal and vertical size class reported; (2) the resulting layout (compact sheet vs split view plus exam-tools inspector; phone + regular horizontal + non-compact vertical gives split); (3) that fold/unfold keeps the question, selected answer and calculator value; (4) the calculator panel scrolls with keys of at least 44 pt in the inspector.

TASK-60 review follow-up (2026-10-19): because real unfolded Duo size-class reporting is now the source of truth, either hardware outcome can require follow-up. If unfolded portrait reports regular horizontal size class, verify whether split view plus inspector leaves a usable narrow exam column or create a product follow-up. If unfolded landscape reports compact horizontal size class, verify whether losing the inspector is acceptable or create a product follow-up.

Coordinator 2026-11-03 (TASK-83 tracking pass): removed the TASK-15 dependency. TASK-54 needs only the merged TASK-15 part 1 (PR #286), while TASK-15 waits on this task's hardware evidence, so the dependency made both tasks wait on each other. Labelled owner-gate: the criteria need a real iPhone Duo.

Correction (coordinator 2026-11-03): AC#5-7 test the hinge peek from TASK-15 part 2 (PR #292), not only part 1 (PR #286). Both merged on 2026-10-18, so removing the dependency still holds.

TASK-87 2026-11-03: owner steps and evidence format for this task are indexed in docs/release/owner-gates.md (Sitting 4: iPhone Duo; AC#1-#7 steps and expected results). The guide restates and links these criteria without changing them.

Coordinator 2026-11-03: re-running the four AC #1 UI tests on the iPhone Duo simulator with the newer iOS 27.2 runtime (iPhone19-4 build 24B91016s) on branch task-54-duo-simulator-rerun; real-device AC #2 and #4-#7 stay owner-gated.
<!-- SECTION:NOTES:END -->
