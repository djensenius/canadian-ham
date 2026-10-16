---
id: TASK-50.2
title: Pilot hints for B-001 subsection 001
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 12:18'
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
- [x] #1 Every B-001-001 question has approved EN/FR hint content following the recall-ladder ruling: two levels where useful, or one level with singleLevelReason where Hint 2 would leak.
- [x] #2 Hints avoid copying question text, correct answers, option text, and reference-sheet content; the hint checker and originality/explanation checks pass.
- [x] #3 At least five representative EN/FR hint pairs, or all pilot pairs when fewer than five files exist, are listed in implementation notes or the PR body for owner tone review.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect B-001-001 generated EN/FR questions plus related lessons/explanations for the tested concepts.
2. Write one content/hints/b-001/<questionId>.json per B-001-001 question with two original EN/FR hint levels and no embedded reference-sheet pointer text.
3. Run check:hints with --subsection B-001-001 --require-complete plus schema, explanations, originality, import, typecheck, and tests; record sample hint pairs for owner tone review.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented pilot hints for all 4 B-001-001 questions in content/hints/b-001. The pilot now follows the owner recall-ladder ruling from 2026-10-16: A+C by default, with one-level B files allowed when a non-giveaway Hint 2 is impossible. No referenceSheetSection applies.

Current pilot hint set:

- B-001-001-001 uses two levels and links to L-001-01#how-these-rules-fit-together. L1 EN: "Start with the source of legal power before looking at the more detailed radio rules that flow from it." FR: "Commencez par la source du pouvoir juridique avant d'examiner les règles de radiocommunication plus détaillées qui en découlent." L2 EN: "An Act grants legal powers. Under those powers, regulations set binding rules and the department issues technical operating standards; the department also administers the Act." FR: "Une loi confère des pouvoirs juridiques. En vertu de ces pouvoirs, les règlements fixent des règles obligatoires et le ministère publie des normes techniques d'exploitation ; le ministère applique aussi la loi."
- B-001-001-002 uses two levels and links to L-001-01#reference-facts-authority-and-source-roles. L1 EN: "Focus on the authority behind a technical operating document, not on the document's title." FR: "Concentrez-vous sur l'autorité qui permet d'établir une norme technique d'exploitation, et non sur son titre." L2 is the same Act/regulations/department standards distinction used by 001.
- B-001-001-003 is single-level and links to L-001-01#how-these-rules-fit-together. L1 EN: "Classify the role first by asking who administers the radio-rule framework." FR: "Classez d'abord le rôle en vous demandant qui administre le cadre des règles de radiocommunication." singleLevelReason: "Distinguishing the departments by mandate would identify ISED or eliminate the others."
- B-001-001-004 is single-level and links to L-001-01#how-these-rules-fit-together. L1 EN: "First ask what type of legal text sets a formal definition." FR: "Demandez-vous d'abord quel type de texte juridique fixe une définition officielle." singleLevelReason: "Any Hint 2 explaining where legal definitions of radio services live identifies the Regulations."

Validation passed for task-50.2: pnpm check:hints -- --subsection B-001-001 --require-complete; pnpm check:hints; pnpm check:schemas; pnpm --dir packages/content-tools check:explanations; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm import:check; pnpm install --frozen-lockfile; pnpm typecheck; pnpm test; pnpm check:hints:self-test. Initial pnpm typecheck failed before workspace dev dependencies were installed (tsc not found), then passed after pnpm install --frozen-lockfile. Review follow-up validation also passed: pnpm typecheck; pnpm test; pnpm check:hints:self-test; pnpm check:hints -- --subsection B-001-001 --require-complete; pnpm check:schemas; pnpm import:check; pnpm --filter @canadian-ham/content-tools check:lesson-originality; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote and review-updated the B-001-001 pilot hint files, EN and FR, under the 2026-10-16 owner recall-ladder ruling. The final pilot uses two-level ladders for B-001-001-001/002, one-level hints with singleLevelReason for B-001-001-003/004, points B-001-001-002 at L-001-01#reference-facts-authority-and-source-roles, and verifies with hint, schema, import, originality, typecheck, and test checks.
<!-- SECTION:FINAL_SUMMARY:END -->
