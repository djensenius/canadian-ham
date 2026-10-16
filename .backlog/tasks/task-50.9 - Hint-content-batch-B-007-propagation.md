---
id: TASK-50.9
title: 'Hint content batch: B-007 propagation'
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
  - content/explanations/b-007
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 123000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-007 propagation questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [x] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [x] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [x] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [x] #6 All in-scope B-007 propagation active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read hint guidance, reviewed examples, B-007 lessons/explanations/reference material, and active B-007 question/options.
2. Add hand-written EN/FR hint files for each active B-007 question under the existing hint content conventions, using two levels only for true computation/derivation items and recording any such rationale in notes.
3. Run the required subsection/category hint checks and broader content checks; record review notes and final evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented B-007 hint files for all 87 active questions (B-007-001: 10, B-007-002 through B-007-008: 11 each). Two-level method files: B-007-003-006: learner must compute/derive skip-distance direction from fixed-height launch-angle geometry; the hint never states decrease/closer. B-007-003-010: learner must compute/derive farthest first-return point from same-height angle sketch; the hint never states smallest angle/longest distance. B-007-003-011: learner must compute/derive skip-distance direction from same-angle layer-height geometry; the hint never states increase/farther. B-007-006-005: learner must compute/derive approximate band name from 28 MHz using 300/f and match same-band evidence; the hint never states 10 metres or beacon as the answer property. Manual option self-test/read-through: checked EN/FR options against each hint level; single-level reasons used where any second hint would identify a path, layer, time, season, mode, value, or effect. Review notes: avoided copying reference-sheet prose; only B-007-006-005 uses referenceSheetSection wavelength-dipole-length and formula wording, with no copied option text. Unit/numeric check: no hint states the correct numeric hop values (4 000 km/2 000 km), cycle length (11 years), normal VHF range (800 km), meteor range (30-100 MHz), or distractor numeric values; B-007-006-005 uses 28 MHz from the question and leaves the 300/f result unstated.

Validation passed: per-subsection pnpm check:hints -- --subsection B-007-001 through B-007-008 --require-complete before each subsection commit; final pnpm check:hints -- --category B-007 --require-complete; pnpm check:hints:self-test; pnpm check:schemas; pnpm --filter @canadian-ham/content-tools check:explanations; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all; pnpm typecheck; pnpm test. Content reviewer AC #2 remains pending for the parent review gate.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented original EN/FR hints for all 87 active B-007 propagation questions with four two-level method ladders and singleLevelReason on every one-level file; automated hint/schema/explanation/originality/typecheck/test checks pass. Pending independent content reviewer check for AC #2.
<!-- SECTION:FINAL_SUMMARY:END -->
