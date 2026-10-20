---
id: TASK-46.6
title: Faded practice and stronger concept checks
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-20 14:34'
labels:
  - content
dependencies:
  - TASK-46.1
  - TASK-46.2
  - TASK-46.3
  - TASK-46.4
parent_task_id: TASK-46
priority: medium
ordinal: 104000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
For quantitative lessons, add one partly worked practice problem after each worked-example set. Replace giveaway concept checks (especially M6) with diagnostic ones, avoid NOT stems, and give each concept check per-option feedback explaining why each wrong option is wrong. Turn story-only 'worked examples' into stepwise ones or rename them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every lesson with calculations has at least one faded practice problem
- [ ] #2 No concept check can be answered by eliminating absurd options (reviewed); each has per-option feedback
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Part A (this branch):
1. Add optional localized concept-choice feedback in schemas and content-swift, a staged require-feedback quiz-checker flag, and accessible web chosen-option feedback with regression/EN-FR light-dark axe tests. Validate, commit, and push this foundation FIRST; notify coordinator with its SHA so Part B can branch from it.
2. Revise M1-M4 content within existing formats: M1 remains reference-only with no concept checks; add faded problems after calculation worked-example sets in M2-M4, rename narrative worked examples, and make all M2-M4 concept choices diagnostic with per-option feedback. Validate, commit, and push each coherent step.
3. Search then create Apple feedback-display subtask under 46.6 depending on TASK-50.14.2. No Apple app edits. Run content-swift tests (37 lessons) and requested content/web checks; list edited lessons containing figures for coordinator figure-plan tests.
Part B: coordinator starts M5-M8 content branch from the pushed foundation commit. Require feedback in the default checker once all quizzes are converted at end of 46.6. Parent stays In Progress pending Part B and Apple subtask.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
From task-46.3 r463-2 review: QZ-L-007-03-A C1 and C3 were rewritten to avoid copying bank questions, but they should receive a stronger technical redesign in the faded-practice/stronger-concept-check pass. Also check EXP-B-008-004-004's spurious-emissions distractor note: the current 'broad category' wording may conflict with the cause-based out-of-band vs spurious distinction.
<!-- SECTION:NOTES:END -->
