---
id: TASK-50.10
title: 'Hint content batch: B-008 interference and suppression'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 15:26'
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
- [x] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [x] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 After this final content batch, CI requires full Basic-bank hint completeness with check:hints -- --require-complete (or equivalent) before UI integration proceeds.
- [ ] #6 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [x] #7 All in-scope B-008 interference and suppression active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read the hint authoring rules, teaching/reference materials, existing reviewed hint examples, B-008 lessons, explanations, and active question data.\n2. Add hand-written EN/FR hint files for all active B-008 questions, using single-level hints except for true computation/derivation items.\n3. Run subsection/category hint checks and required content/project checks, then assess full-bank completeness and update CI only if the whole bank is complete.\n4. Record implementation notes, validation evidence, and any pending CI/full-bank/review status in the Backlog task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented B-008 hints: 55/55 active questions covered. Counts by subsection (two-level/single-level): B-008-001 1/10; B-008-002 0/11; B-008-003 0/11; B-008-004 3/8; B-008-005 0/11. All referenceSheetSection values are null because no B-008 hint uses a reference-sheet formula/section pointer. Applied the literal option self-test to all four EN and FR options for every file, per level and across levels; self-check found no reference-sheet copying, equivalent-unit leak, or distractor numeric elimination.\nTwo-level method notes: B-008-001-010: learner must compute/derive the receiver-mixing frequency difference and compare it with channel 5; the hint never states the high-pass-at-TV answer property. B-008-004-005: learner must compute/derive the reported/operating frequency ratio; the hint never states the harmonic-output answer property. B-008-004-007: learner must compute/derive the 15 m integer-multiple range and compare it with channel 3; the hint never states the harmonic-emission answer property. B-008-004-010: learner must compute/derive the listed band-name frequency multiples; the hint never states the second-harmonic-of-10 m answer property.\nValidation passed: per-subsection pnpm check:hints -- --subsection B-008-00N --require-complete for all five subsections; pnpm check:hints -- --category B-008 --require-complete; pnpm check:hints:self-test; pnpm check:schemas; pnpm --filter @canadian-ham/content-tools check:explanations; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all; pnpm typecheck; pnpm test. Full-bank pnpm check:hints -- --require-complete intentionally left out of CI because B-003 (199 missing) and B-007 (87 missing) are not present on this branch/main; .github/workflows/ci.yml remains unchanged and the full-bank switch is pending those merges. Review AC #2/#4/#6 remain for content reviewer/PR review.

Review fix for PR #272: addressed every row in r272 findings table across 45 hint files (22 High rows, 18 Med rows, 3 Low rows, 2 Low/Med rows; this includes the reviewer summary's 16 leak files and 18 medium issues). Used the proposed EN/FR wording except B-008-002-002 FR was rephrased from the proposed wording to satisfy the hint leak checker while preserving the same topic pointer. For every touched file, read all four EN and FR options and reapplied the literal option self-test. Clean files listed by the review were not touched. Updated two-level method notes: B-008-001-010 learner must compute/derive the FM-minus-HF difference, compare it with channel 5, identify where the two signals meet, then choose filter type and placement; the hint does not state the high-pass-at-TV property. B-008-005-009 is now two-level: learner must place 40 m, 31 m (via 300 / lambda), and 30 m on a frequency line and compare that line with filter-family response sketches; the hint does not state the band-reject answer property. Validation after fixes: pnpm check:hints -- --category B-008 --require-complete; pnpm check:hints:self-test; pnpm check:schemas; pnpm --filter @canadian-ham/content-tools check:explanations; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all; pnpm typecheck; pnpm test.
<!-- SECTION:NOTES:END -->
