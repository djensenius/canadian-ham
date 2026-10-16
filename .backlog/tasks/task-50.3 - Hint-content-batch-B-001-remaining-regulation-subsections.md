---
id: TASK-50.3
title: 'Hint content batch: B-001 remaining regulation subsections'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 13:06'
labels:
  - content
dependencies:
  - TASK-50.2
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-001
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: medium
type: task
ordinal: 117000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write and review original EN/FR hint content for B-001 after the B-001-001 pilot, covering every remaining question in the category.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hints follow the approved ladder, use original wording, and do not leak answers, options, question phrasing, or copied reference-sheet content.
- [ ] #2 A content reviewer checks the batch for accuracy and tone; review notes and sample corrections are recorded.
- [ ] #3 The hint checker, schema check, explanations checker, and originality checker pass after the batch.
- [ ] #4 Batch review explicitly checks that hints do not copy reference-sheet content; review notes record any findings or corrections.
- [ ] #5 Batch review explicitly checks equivalent unit conversions (for example 1.5 MHz for 1 500 kHz) and distractor numeric values listed as eliminations; review notes record any findings or corrections.
- [ ] #6 All in-scope B-001 remaining regulation active Basic questions have one or two EN/FR hint levels; files with only Hint 1 include singleLevelReason.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix the hint checker shared-option exemption and add the B-001-003-003 regression self-test, then run its focused validation.\n2. For each remaining B-001 subsection, read the lesson/explanation/question source for that subsection, author original EN/FR hint files with real lesson anchors, run the subsection completion check, commit/push, and append a task-note progress line.\n3. After all B-001 subsections pass, run the category and repository checks, record counts/samples in task notes, finalize task criteria, and open the PR with Copilot requested.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Before writing this batch: fix the checker's shared-option exemption to count each candidate phrase's containment across all tokenized options, not only options that generated it. Copilot PR #259 thread PRRT_kwDOUxZq_M6tNLSW: B-001-003-003 'fine' appears in three options, but only 'A fine of $10 000' generates it, so 'Consider fine before choosing.' is wrongly rejected. Safe false positive; add a regression self-test.

B-001-002 done: 9 hints (8 two-level, 1 single-level B: B-001-002-002). Validation: pnpm check:hints -- --subsection B-001-002 --require-complete passed.

B-001-003 done: 8 hints (8 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-003 --require-complete passed.

B-001-004 done: 7 hints (6 two-level, 1 single-level B: B-001-004-001). Validation: pnpm check:hints -- --subsection B-001-004 --require-complete passed.

B-001-005 done: 6 hints (6 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-005 --require-complete passed.

B-001-006 done: 6 hints (6 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-006 --require-complete passed.

B-001-007 done: 11 hints (11 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-007 --require-complete passed.

B-001-008 done: 8 hints (8 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-008 --require-complete passed.

B-001-009 done: 9 hints (9 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-009 --require-complete passed.

B-001-010 done: 10 hints (10 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-010 --require-complete passed.

B-001-011 done: 10 hints (10 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-011 --require-complete passed.

B-001-012 done: 4 hints (4 two-level, 0 single-level B). Validation: pnpm check:hints -- --subsection B-001-012 --require-complete passed.

Steering cleanup: removed already-pushed template hints for B-001-006 through B-001-012 pending manual rewrite; discarded untracked generated B-001-013 through B-001-025 files and removed the temporary generator script. Rewriting B-001-002 through B-001-005 next for sample review.

Rewrote B-001-002 by hand after quality steering: 9 hints (4 two-level, 5 single-level B: B-001-002-002, -004, -005, -006, -008, -009? correction: 6 single-level). Validation: pnpm check:hints -- --subsection B-001-002 --require-complete passed.

Rewrote B-001-003 by hand after quality steering: 8 hints (5 two-level, 3 single-level B: B-001-003-002, B-001-003-004, B-001-003-005, B-001-003-007? correction: 4 single-level). Validation: pnpm check:hints -- --subsection B-001-003 --require-complete passed.

Rewrote B-001-004 by hand after quality steering: 7 hints (0 two-level, 7 single-level B). Validation: pnpm check:hints -- --subsection B-001-004 --require-complete passed.

Rewrote B-001-005 by hand after quality steering: 6 hints (5 two-level, 1 single-level B: B-001-005-004). Validation: pnpm check:hints -- --subsection B-001-005 --require-complete passed. Pausing for sample review before continuing B-001-006 onward.

Corrected rewritten sample counts for review: B-001-002 has 3 two-level and 6 single-level B; B-001-003 has 4 two-level and 4 single-level B; B-001-004 has 0 two-level and 7 single-level B; B-001-005 has 5 two-level and 1 single-level B. B-001-006 onward currently has no hint files on this branch pending review and manual rewrite.

Re-audited B-001-002 through B-001-005 after sample review using the no-decisive-fact self-test. Updated README with the self-test and examples. Current sample counts: B-001-002 0 two-level / 9 single-level B; B-001-003 1 two-level / 7 single-level B; B-001-004 0 two-level / 7 single-level B; B-001-005 0 two-level / 6 single-level B. Validation: subsection checks for B-001-002, -003, -004, -005 all passed with --require-complete.

B-001-006 manually written after calibration: 6 hints (0 two-level, 6 single-level B). Validation: pnpm check:hints -- --subsection B-001-006 --require-complete passed.

B-001-007 manually written after calibration: 11 hints (0 two-level, 11 single-level B). Validation: pnpm check:hints -- --subsection B-001-007 --require-complete passed.

B-001-008 manually written after calibration: 8 hints (0 two-level, 8 single-level B). Validation: pnpm check:hints -- --subsection B-001-008 --require-complete passed.

B-001-009 manually written after calibration: 9 hints (0 two-level, 9 single-level B). Validation: pnpm check:hints -- --subsection B-001-009 --require-complete passed.

B-001-010 manually written after calibration: 10 hints (0 two-level, 10 single-level B). Validation: pnpm check:hints -- --subsection B-001-010 --require-complete passed. Pausing per steering for six-sample review before B-001-011 onward.

Re-audited B-001-002 through B-001-010 using the literal option self-test. Converted all in-scope files in those subsections to single-level B topic pointers and added the B-001 topic-pointer rule/examples to README. Validation: subsection checks for B-001-002 through B-001-010 all passed with --require-complete.

B-001-011 manually written as calibrated topic-pointer B hints: 10 hints (0 two-level, 10 single-level B). Validation: pnpm check:hints -- --subsection B-001-011 --require-complete passed.

B-001-012 manually written as calibrated topic-pointer B hints: 4 hints (0 two-level, 4 single-level B). Validation: pnpm check:hints -- --subsection B-001-012 --require-complete passed.

B-001-013 manually written as calibrated topic-pointer B hints: 11 hints (0 two-level, 11 single-level B). Validation: pnpm check:hints -- --subsection B-001-013 --require-complete passed.

B-001-014 manually written as calibrated topic-pointer B hints: 11 hints (0 two-level, 11 single-level B). Validation: pnpm check:hints -- --subsection B-001-014 --require-complete passed.

B-001-015 manually written as calibrated topic-pointer B hints: 11 hints (0 two-level, 11 single-level B). Validation: pnpm check:hints -- --subsection B-001-015 --require-complete passed.

Softened several B-001-011 and B-001-014 topic pointers before the B-001-015 review stop to avoid implying distress/visitor answer options. Validation: subsection checks for B-001-011 through B-001-015 all passed again.

Updated README with method-hint rule and upgraded B-001-015 HF band-range recall to two-level wavelength-method hints (B-001-015-005 through -010). Validation: pnpm check:hints -- --subsection B-001-015 --require-complete passed.

B-001-016 manually written as calibrated topic-pointer B hints: 11 hints (0 two-level, 11 single-level B). Validation: pnpm check:hints -- --subsection B-001-016 --require-complete passed.

B-001-017 manually written as calibrated topic-pointer B hints: 10 hints (0 two-level, 10 single-level B). Validation: pnpm check:hints -- --subsection B-001-017 --require-complete passed.

B-001-018 manually written as calibrated topic-pointer B hints: 4 hints (0 two-level, 4 single-level B). Validation: pnpm check:hints -- --subsection B-001-018 --require-complete passed.

B-001-019 manually written as calibrated topic-pointer B hints: 6 hints (0 two-level, 6 single-level B). Validation: pnpm check:hints -- --subsection B-001-019 --require-complete passed.

B-001-020 manually written as calibrated topic-pointer B hints: 5 hints (0 two-level, 5 single-level B). Validation: pnpm check:hints -- --subsection B-001-020 --require-complete passed.

B-001-021 manually written as calibrated topic-pointer B hints: 9 hints (0 two-level, 9 single-level B). Validation: pnpm check:hints -- --subsection B-001-021 --require-complete passed.

B-001-022 manually written as calibrated topic-pointer B hints: 5 hints (0 two-level, 5 single-level B). Validation: pnpm check:hints -- --subsection B-001-022 --require-complete passed.

B-001-023 manually written as calibrated topic-pointer B hints: 10 hints (0 two-level, 10 single-level B). Validation: pnpm check:hints -- --subsection B-001-023 --require-complete passed.

B-001-024 manually written as calibrated topic-pointer B hints: 10 hints (0 two-level, 10 single-level B). Validation: pnpm check:hints -- --subsection B-001-024 --require-complete passed.

B-001-025 manually written as calibrated topic-pointer B hints: 4 hints (0 two-level, 4 single-level B). Validation: pnpm check:hints -- --subsection B-001-025 --require-complete passed.
<!-- SECTION:NOTES:END -->
