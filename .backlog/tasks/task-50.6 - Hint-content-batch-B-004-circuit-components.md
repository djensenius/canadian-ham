---
id: TASK-50.6
title: 'Hint content batch: B-004 circuit components'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 14:46'
labels:
  - content
dependencies:
  - TASK-50.2
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-004
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 120000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-004 circuit component questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-004 circuit components active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect B-004 active questions, lessons, explanations, reference-sheet sections, and merged hint examples for schema and tone.
2. Author one hand-written hint JSON file per active B-004 question, using single-level pointers for recall/definition/concept items and two-level method hints only for computations or derivations.
3. After each B-004 subsection, run the subsection hint checker with --require-complete, record any required two-level justifications in task notes, and commit that subsection.
4. Run the category hint checker, self-test, schema, explanations, originality, typecheck, and test commands; update task notes/final status and open the requested PR.
<!-- SECTION:PLAN:END -->
