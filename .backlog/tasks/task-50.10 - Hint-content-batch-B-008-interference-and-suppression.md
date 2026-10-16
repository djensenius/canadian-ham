---
id: TASK-50.10
title: 'Hint content batch: B-008 interference and suppression'
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 11:50'
labels:
  - content
dependencies:
  - TASK-50.3
  - TASK-50.4
  - TASK-50.5
  - TASK-50.6
  - TASK-50.7
  - TASK-50.8
  - TASK-50.9
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-008
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 124000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-008 interference and suppression questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 After this final content batch, CI requires full Basic-bank hint completeness with check:hints -- --require-complete (or equivalent) before UI integration proceeds.
- [ ] #6 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #7 All in-scope B-008 interference and suppression active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->
