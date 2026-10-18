---
id: TASK-54
title: >-
  Verify hardware keyboard input and navigation back-button accessibility on
  real iPhone Duo / iOS 27.1
status: To Do
assignee: []
created_date: '2026-10-18 01:53'
updated_date: '2026-10-18 03:19'
labels:
  - apple
dependencies:
  - TASK-15
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
- [ ] #4 Verify on a real iPhone Duo that unfolded practice shows the question and exam tools side by side, and that a fold/unfold during practice preserves the current question, selected answer and calculator value
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up 2026-10-18: TASK-54 depends on TASK-15 part 1 / PR #286 for the Duo simulator classification and unfolded-layout hooks; it does not need part 2 hinge-peek work except insofar as Backlog cannot express a dependency on part 1 only.
<!-- SECTION:NOTES:END -->
