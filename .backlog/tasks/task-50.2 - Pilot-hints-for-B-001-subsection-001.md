---
id: TASK-50.2
title: Pilot hints for B-001 subsection 001
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 08:30'
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
- [x] #1 Every B-001-001 question has exactly two EN hints and two FR hints following the approved nudge-then-setup ladder.
- [x] #2 Hints avoid copying question text, correct answers, option text, and reference-sheet content; the hint checker and originality/explanation checks pass.
- [x] #3 At least five representative EN/FR hint pairs are listed in implementation notes or the PR body for owner tone review.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect B-001-001 generated EN/FR questions plus related lessons/explanations for the tested concepts.
2. Write one content/hints/b-001/<questionId>.json per B-001-001 question with two original EN/FR hint levels and no embedded reference-sheet pointer text.
3. Run check:hints with --subsection B-001-001 --require-complete plus schema, explanations, originality, import, typecheck, and tests; record sample hint pairs for owner tone review.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented pilot hints for all 4 B-001-001 questions in content/hints/b-001. Each file has two EN/FR levels; no referenceSheetSection applies. Also made check-hints tolerate the standard pnpm bare -- argument separator used by root scripts.

The original owner-tone sample pairs that used option elimination were superseded during review. Current pilot wording follows the no-elimination style, but B-001-001 is a pure-recall hierarchy subsection and the owner is deciding how recall-question ladders should work before these pairs are treated as final.

Review follow-up: the pilot was rewritten for no-elimination style; the final pairs come after the owner's recall-ladder ruling.

Validation passed for task-50.2: pnpm check:hints -- --subsection B-001-001 --require-complete; pnpm check:hints; pnpm check:schemas; pnpm --dir packages/content-tools check:explanations; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm import:check; pnpm install --frozen-lockfile; pnpm typecheck; pnpm test; pnpm check:hints:self-test. Initial pnpm typecheck failed before workspace dev dependencies were installed (tsc not found), then passed after pnpm install --frozen-lockfile.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote the B-001-001 pilot hint files, EN and FR, using the two-step nudge/setup ladder and no embedded reference-sheet pointer text. Review rewrote the pilot away from option-elimination style; the final recall-question pairs remain pending the owner's recall-ladder ruling. Verified pilot completeness and leakage with the hint checker, and reran schema, import, explanation, originality, typecheck, and test suites.
<!-- SECTION:FINAL_SUMMARY:END -->
