---
id: TASK-47
title: >-
  Originality checker: flag real question-answer number pairs, not common
  numbers
status: To Do
assignee: []
created_date: '2026-10-12 15:48'
labels:
  - content
dependencies: []
priority: medium
ordinal: 110000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
check-lesson-originality rejects any worked-example block whose only numeric tokens are common values (2, 3, 10, 0.5) because some bank answer contains them. This pushed workers to delete dB working (task-46.1) instead of teaching it. Refine the rule so it flags reuse of a bank question's distinctive number set together with its keyed answer, while allowing ubiquitous values and standard step values (3 dB, 10 dB, x 2, x 10) in worked examples.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A worked example using 10 dB + 3 dB steps passes; copying a bank question's numbers with its keyed answer still fails (self-test cases)
- [ ] #2 All lessons on main still pass; any newly allowed lines are reviewed
<!-- AC:END -->
