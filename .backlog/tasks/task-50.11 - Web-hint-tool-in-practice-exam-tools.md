---
id: TASK-50.11
title: Web hint tool in practice exam tools
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
labels:
  - web
dependencies:
  - TASK-50.3
  - TASK-50.4
  - TASK-50.5
  - TASK-50.6
  - TASK-50.7
  - TASK-50.8
  - TASK-50.9
  - TASK-50.10
parent_task_id: TASK-50
priority: high
type: task
ordinal: 125000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the Hint tool to the existing web practice/review exam-tools panel after Basic hint content exists. Hints must be hidden in mock exams, localized EN/FR, accessible, and integrated with progress so hinted answers are treated as answered with help.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Practice and review sessions show a localized Hint tool in the existing exam-tools panel; mock exams never expose hints.
- [ ] #2 Opening Hint 1 then Hint 2 follows the approved ladder, announces state accessibly, and does not reveal official answer text.
- [ ] #3 Answering after any opened hint records answered with help, does not advance mastery or weak-area clearing, and schedules the question sooner in spaced review.
- [ ] #4 Web tests cover availability by session type, accessibility/keyboard behaviour, EN/FR display, and progress/spaced-review effects.
<!-- AC:END -->
