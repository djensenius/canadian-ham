---
id: TASK-50.3
title: 'Hint content batch: B-001 remaining regulation subsections'
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 12:40'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Before writing this batch: fix the checker's shared-option exemption to count each candidate phrase's containment across all tokenized options, not only options that generated it. Copilot PR #259 thread PRRT_kwDOUxZq_M6tNLSW: B-001-003-003 'fine' appears in three options, but only 'A fine of $10 000' generates it, so 'Consider fine before choosing.' is wrongly rejected. Safe false positive; add a regression self-test.
<!-- SECTION:NOTES:END -->
