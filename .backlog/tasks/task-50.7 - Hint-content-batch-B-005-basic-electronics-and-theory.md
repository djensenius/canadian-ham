---
id: TASK-50.7
title: 'Hint content batch: B-005 basic electronics and theory'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 14:18'
labels:
  - content
dependencies:
  - TASK-50.2
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-005
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 121000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-005 electronics and theory questions, including formula/setup hints that follow E/I/R/P notation and SI spacing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-005 basic electronics and theory active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read the B-005 source questions, M5 lessons, explanations, reference-sheet keys, and calibrated B-001 hint examples.\n2. Write hand-authored EN/FR hints for B-005 one subsection at a time, using formula/setup ladders where useful and single-level topic pointers only for pure recall.\n3. After each subsection, run pnpm check:hints with --subsection and --require-complete, commit, push, and record progress notes.\n4. Stop after B-005-001 and B-005-002 for calibration with six EN/FR samples before continuing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Completed B-005-001 calibration slice: wrote 11 hint files (9 two-level method, 2 single-level prefix recall); pnpm check:hints -- --subsection B-005-001 --require-complete passed.
<!-- SECTION:NOTES:END -->
