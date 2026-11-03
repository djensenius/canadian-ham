---
id: TASK-50.8
title: 'Hint content batch: B-006 feeders and antennas'
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
- [x] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [x] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [x] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [x] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [x] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [x] #6 All in-scope B-006 feeders and antennas active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the approved hint examples, M6 lessons, B-006 explanations, question options, and reference-sheet sections before drafting.\n2. Draft B-006 hint JSON by subsection, using single-level topic pointers except where a real calculation or derivation method is needed.\n3. After each subsection, run pnpm check:hints -- --subsection B-006-0NN --require-complete, record any two-level justification notes, and commit that focused slice.\n4. Run the full B-006 hint, self-test, schema, explanation/originality, typecheck, and test commands; record review handoff notes and final evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Two-level justifications: B-006-006-011: learner must compute/derive impedance transformation ratio from 300/50; the hint never states 6:1. B-006-008-003: learner must compute/derive wavelength from 300/25; the hint never states 12 metres. B-006-008-011: learner must compute/derive wavelength from 300/2; the hint never states 150 metres. B-006-009-011: learner must compute/derive dBd gain by subtracting the dipole reference offset; the hint never states 2.0 dB. B-006-010-002: learner must compute/derive quarter-wave length from 71.3/21.125; the hint never states 3.37 metres. B-006-010-003: learner must compute/derive VHF half-wave length from 150/223 and convert to centimetres; the hint never states 67 cm. B-006-011-002: learner must compute/derive driven-element length from 143/14.0; the hint never states 10.21 metres. B-006-011-003: learner must compute/derive director length from 143/21.1 x 0.95; the hint never states 6.44 metres. B-006-011-004: learner must compute/derive reflector length from 143/28.1 x 1.05; the hint never states 5.34 metres. B-006-011-011: learner must compute/derive stacked gain by adding about 3 dB to 10 dBi; the hint never states 13 dBi. B-006-012-001: learner must compute/derive half-wave dipole length from 143/28.150; the hint never states 5.08 metres. B-006-012-009: learner must compute/derive half-wave dipole length from 143/3.75; the hint never states 38.13 metres. B-006-013-003: learner must compute/derive full-wave loop length from 306/21.4; the hint never states 14.30 metres. B-006-013-004: learner must compute/derive full-wave loop length from 306/14.3; the hint never states 21.40 metres. B-006-013-005: learner must compute/derive delta-loop length from 306/28.7; the hint never states 10.66 metres. B-006-013-009: learner must compute/derive horizontal-loop length from 306/7.15; the hint never states 42.80 metres.

Implementation handoff: drafted 140/140 active B-006 hint files under content/hints/b-006 with lessonLink metadata and referenceSheetSection where formulas apply. Subsection checks passed for B-006-001 through B-006-013 with --require-complete; full B-006 check, hint self-test, schemas, explanations, lesson originality, typecheck, and test all passed locally. Content review is still required for AC #2/#4/#5 before finalizing the task.

Review fix pass for PR #270 (batch review r270.md): neutralized every flagged single-level pointer and FR terminology issue, added README examples of narrowing pointers, kept the original 16 reviewed calculation ladders with only the requested wording/anchor notes, and upgraded four reviewer-proposed real calculations: B-006-004-009 (40/20 => 100% added loss), B-006-008-001 (143/3.9 vs 143/3.6 => longer), B-006-008-002 (143/3.6 vs 143/3.9 => shorter), and B-006-008-004 (300/f speed conversion => 300 000 km/s). Counts now: 140 B-006 files, 120 one-level, 20 two-level, reference pointers 16 wavelength/dipole + 1 decibel + 123 null. Validation passed: pnpm check:hints -- --category B-006 --require-complete; pnpm check:hints:self-test; pnpm check:schemas; pnpm --filter @canadian-ham/content-tools check:explanations; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all; pnpm typecheck; pnpm test.

Coordinator closeout 2026-10-16: batch content review completed (review files ~/.cache/canadian-ham-reviews/r270*.md), all findings fixed and coordinator spot-checked against ISED options; merged in PR #270.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Hand-written EN/FR hints for every active question in this category, reviewed (no answer leakage, no elimination, neutral section-level pointers, verified method hints), merged in PR #270.
<!-- SECTION:FINAL_SUMMARY:END -->
