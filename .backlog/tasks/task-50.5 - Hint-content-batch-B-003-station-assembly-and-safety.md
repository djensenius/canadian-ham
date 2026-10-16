---
id: TASK-50.5
title: 'Hint content batch: B-003 station assembly and safety'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 15:19'
labels:
  - content
dependencies:
  - TASK-50.2
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-003
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 119000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-003 station assembly and safety questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-003 station assembly and safety active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read hint authoring guidance, reviewed batches, module lessons, explanations, reference sheet, and active B-003 questions/options.\n2. Author original EN/FR hint files under content/hints/b-003 by subsection, using single-level topic pointers except true calculation/method questions.\n3. For any two-level method hints, record the mandatory non-leak note in task notes and validate with subsection hint checks.\n4. Run required batch validation checks and summarize coverage, risks, and review needs.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented 199 draft B-003 hint files under content/hints/b-003. Two-level method hints recorded per brief: B-003-010-006: learner must compute/derive local oscillator frequency by converting 455 kHz to MHz and adding one IF; the hint never states the answer frequency. B-003-011-007: learner must compute/derive AM occupied bandwidth by applying twice the highest audio frequency; the hint never states the numeric answer. B-003-012-010: learner must compute/derive lower-sideband RF tone by converting the audio offset and subtracting from the setting; the hint never states the answer frequency. B-003-016-009: learner must compute/derive parallel battery voltage/capacity; the hint never states the final voltage/capacity pair. B-003-016-010: learner must compute/derive series battery voltage/capacity; the hint never states the final voltage/capacity pair. B-003-017-009: learner must compute/derive round-trip lead drop for each listed gauge and select the minimum passing gauge; the hint never states the gauge. B-003-021-008: learner must derive RF exposure distance scaling from spreading-area reasoning; the hint never states the inverse-square answer property.

Validation: read all B-003 EN/FR question/options from the active bank and ran literal option self-test while authoring; ran per-subsection hint checks B-003-001 through B-003-021 with --require-complete; ran category hint check, hint checker self-test, schemas, explanations, lesson originality, typecheck, and full pnpm test. Content review remains pending for AC #2/#4/#5.
<!-- SECTION:NOTES:END -->
