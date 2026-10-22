---
id: TASK-50.14
title: Lesson-quiz hints follow-up decision
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-20 13:03'
labels: []
dependencies: []
parent_task_id: TASK-50
priority: low
type: task
ordinal: 128000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Lesson quizzes are explicitly out of scope for the initial question-hints feature. Revisit only after the owner decides whether lesson-quiz hints fit the teaching model and how they should affect quiz feedback/progress.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded on whether lesson quizzes should have hints.
- [x] #2 If approved, follow-up implementation tasks define lesson-quiz hint content, UI, and progress semantics separately from practice/review question hints.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Record the owner decision verbatim and create web/model plus dependent Apple follow-up subtasks.
2. Implement the web/model subtask with existing practice hint components and progress semantics, preserving mock exams and concept checks.
3. Validate, commit/push each step, and finalize the decision task and verified web subtask.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-20: YES, lesson quizzes get hints.
1. **Which questions:** official ISED bank questions inside lesson quizzes show the existing two-level hint ladder and lesson link, using the same UI and rules as practice (a hint visible for at least 0.5 s before scoring counts as help; hints after scoring don't change the record). The lesson link leads back to the lesson, which may be the current one.
2. **Concept checks** (original lesson items) get no hints in this version, and the Hint control isn't shown for them.
3. **Quiz score:** a correct answer given with help still counts as correct. The results summary shows how many answers used help, and each per-question result shows a "with help" marker. Lesson completion and passing are unaffected.
4. **Progress:** wherever lesson-quiz answers to bank questions already update per-question progress (Leitner box, weak areas, recent answers), apply the TASK-50.15 semantics: hinted correct keeps its box and is due now, hinted incorrect counts as incorrect, and weak areas count it as an attempt without proficiency credit. Use the existing answeredWithHelp flag. If lesson quizzes don't feed question progress today, don't add that; just store the flag in the quiz attempt record if a record exists.
5. **Mock exams** never get hints. Timed modes are unchanged.

Coordinator approved actual nested IDs TASK-50.14.1/.2 because the Backlog CLI allocates child IDs from their parent; next-free 50.x cannot be assigned under 50.14 through the CLI.

Created TASK-50.14.1 (web + engines + schemas) and TASK-50.14.2 (all Apple platforms, depends on .1), defining the approved content/UI/progress/accessibility/localization/test contract. Decision task ACs are met; Apple implementation remains separately tracked.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Recorded the affirmative 2026-10-20 owner decision verbatim and created scoped web/model plus dependent all-platform Apple implementation subtasks. Both decision-task acceptance criteria are satisfied; implementation progress is tracked in the children.
<!-- SECTION:FINAL_SUMMARY:END -->
