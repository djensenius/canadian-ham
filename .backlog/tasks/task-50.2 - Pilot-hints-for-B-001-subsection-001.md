---
id: TASK-50.2
title: Pilot hints for B-001 subsection 001
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 08:02'
labels:
  - content
dependencies:
  - TASK-50.1
references:
  - content/generated/basic-2025-07-15/questions.json
  - content/explanations/b-001
  - content/lessons
documentation:
  - docs/teaching-guide.md
parent_task_id: TASK-50
priority: high
type: task
ordinal: 116000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write the first production hint batch for all active Basic questions in subsection B-001-001, EN and FR, to validate the schema, checker, tone, and review workflow before scaling to the rest of the bank. Base the hints on existing lessons and explanations while avoiding official question and answer wording.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every B-001-001 question has exactly two EN hints and two FR hints following the approved nudge-then-setup ladder.
- [ ] #2 Hints avoid copying question text, correct answers, option text, and reference-sheet content; the hint checker and originality/explanation checks pass.
- [ ] #3 At least five representative EN/FR hint pairs are listed in implementation notes or the PR body for owner tone review.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect B-001-001 generated EN/FR questions plus related lessons/explanations for the tested concepts.
2. Write one content/hints/b-001/<questionId>.json per B-001-001 question with two original EN/FR hint levels and no embedded reference-sheet pointer text.
3. Run check:hints with --subsection B-001-001 --require-complete plus schema, explanations, originality, import, typecheck, and tests; record sample hint pairs for owner tone review.
<!-- SECTION:PLAN:END -->
