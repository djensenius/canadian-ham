---
id: TASK-50.8
title: 'Hint content batch: B-006 feeders and antennas'
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
  - content/explanations/b-006
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 122000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-006 feeder and antenna questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-006 feeders and antennas active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the approved hint examples, M6 lessons, B-006 explanations, question options, and reference-sheet sections before drafting.\n2. Draft B-006 hint JSON by subsection, using single-level topic pointers except where a real calculation or derivation method is needed.\n3. After each subsection, run pnpm check:hints -- --subsection B-006-0NN --require-complete, record any two-level justification notes, and commit that focused slice.\n4. Run the full B-006 hint, self-test, schema, explanation/originality, typecheck, and test commands; record review handoff notes and final evidence.
<!-- SECTION:PLAN:END -->
