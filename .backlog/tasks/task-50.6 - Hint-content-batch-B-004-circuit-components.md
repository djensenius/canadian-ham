---
id: TASK-50.6
title: 'Hint content batch: B-004 circuit components'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 15:39'
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
- [x] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [x] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [x] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [x] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [x] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [x] #6 All in-scope B-004 circuit components active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect B-004 active questions, lessons, explanations, reference-sheet sections, and merged hint examples for schema and tone.
2. Author one hand-written hint JSON file per active B-004 question, using single-level pointers for recall/definition/concept items and two-level method hints only for computations or derivations.
3. After each B-004 subsection, run the subsection hint checker with --require-complete, record any required two-level justifications in task notes, and commit that subsection.
4. Run the category hint checker, self-test, schema, explanations, originality, typecheck, and test commands; update task notes/final status and open the requested PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Two-level justifications for B-004-006:
B-004-006-004: learner must compute/derive the tolerance range around 100 ohms; the hint never states the range endpoints.
B-004-006-005: learner must compute/derive which value-band position changes between 33 ohms and 39 ohms; the hint never states the band ordinal.
B-004-006-010: learner must compute/derive which band changes the multiplier scale between 120 ohms and 1200 ohms; the hint never states the band ordinal.
B-004-006-011: learner must compute/derive the resistor value from colour digits and multiplier; the hint never states the final resistance value.

Validation passed after implementation:
- pnpm check:hints -- --category B-004 --require-complete (63/63 active B-004 hints)
- pnpm check:hints:self-test
- pnpm check:schemas
- pnpm --filter @canadian-ham/content-tools check:explanations
- pnpm --filter @canadian-ham/content-tools check:lesson-originality:all
- pnpm typecheck
- pnpm test
Manual self-review: applied EN/FR literal-option self-test, checked hint prose avoids reference-sheet pointer text/copying, and checked the four two-level numeric/method hints do not state final answer values or band ordinals. Content-review acceptance criteria remain for reviewer.

Review fix round for PR #271 (batch review r271): addressed all listed B-004 findings across 33 hint files. Reworked 006-005/006-010/006-011 two-level colour-code hints so Hint 2 sets up the table/method without naming matching digits, multiplier band, or final value; 006-005 resolves orange-orange-black vs orange-white-black (second band), 006-010 resolves brown-red-brown vs brown-red-red (third band), and 006-011 leaves 27 + four zeros -> 270 kΩ for the learner. Rewrote answer-bearing single-level pointers to neutral section-level topics in EN/FR, applied the literal option self-test in both languages, fixed FR terminology/calques, and updated 005-003 lesson link to triode-vacuum-tubes. Counts remain 63/63 B-004 hints: 59 single-level and 4 two-level. Validation passed: pnpm check:hints -- --category B-004 --require-complete; pnpm check:hints:self-test; pnpm check:schemas; pnpm --filter @canadian-ham/content-tools check:explanations; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all; pnpm typecheck; pnpm test.

Coordinator closeout 2026-10-16: batch content review completed (review files ~/.cache/canadian-ham-reviews/r271*.md), all findings fixed and coordinator spot-checked against ISED options; merged in PR #271.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Hand-written EN/FR hints for every active question in this category, reviewed (no answer leakage, no elimination, neutral section-level pointers, verified method hints), merged in PR #271.
<!-- SECTION:FINAL_SUMMARY:END -->
