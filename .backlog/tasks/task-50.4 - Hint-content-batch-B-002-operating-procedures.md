---
id: TASK-50.4
title: 'Hint content batch: B-002 operating procedures'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 14:19'
labels:
  - content
dependencies:
  - TASK-50.2
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-002
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 118000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-002 operating procedure questions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-002 operating procedures active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read hint rules, teaching guide, B-001 examples, M2 lessons, B-002 explanations, and question metadata before writing.\n2. Implement B-002 one subsection at a time by hand, choosing two-level hints where reasoning is possible and single-level topic pointers for pure recall.\n3. After each subsection, run pnpm check:hints for that subsection with --require-complete, commit, push, and append progress notes.\n4. Stop after the first two subsections with six EN/FR calibration samples including questions, options, and correct answers before continuing.\n5. After approval, finish remaining subsections and run the full required validation suite before PR handoff.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Completed B-002-001 repeater procedure hints: 10 two-level, 1 single-level recall. Validation: pnpm check:hints -- --subsection B-002-001 --require-complete passed. Commit: e329dfe5a406ad4f20e980f17dcd62ed6a53cf6e.

Completed B-002-002 phonetic alphabet hints: 0 two-level, 11 single-level recall. Validation: pnpm check:hints -- --subsection B-002-002 --require-complete passed. Commit: 41811b2e7127bac3941007c17149bdb22b1f61a5. Calibration stop reached after first two subsections.

Applied calibration fixes: converted B-002-001-003 to a one-level definition pointer, rewrote B-002-001-005 H2 to teach CTCSS use/context instead of paraphrasing the definition, softened B-002-002-001 and -002 voice-spelling pointers, and recorded the definition-question rule in content/hints/README.md. Validation: pnpm check:hints -- --subsection B-002-001 --require-complete and --subsection B-002-002 --require-complete passed. Commit: 83fe19e5b8019df6e592711c7495b0bed343a1d0.
<!-- SECTION:NOTES:END -->
