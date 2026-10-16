---
id: TASK-50.2
title: Pilot hints for B-001 subsection 001
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 12:08'
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
- [ ] #1 Every B-001-001 question has approved EN/FR hint content following the recall-ladder ruling: two levels where useful, or one level with singleLevelReason where Hint 2 would leak.
- [ ] #2 Hints avoid copying question text, correct answers, option text, and reference-sheet content; the hint checker and originality/explanation checks pass.
- [ ] #3 At least five representative EN/FR hint pairs, or all pilot pairs when fewer than five files exist, are listed in implementation notes or the PR body for owner tone review.
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

Owner recall-ladder ruling applied in review follow-up. Final B-001-001 pilot uses two levels for all four questions, with lessonLink `{ lessonId: "L-001-01", sectionAnchor: "how-these-rules-fit-together" }`:

- B-001-001-001 L1 EN: "Start with the source of legal power before looking at the more detailed radio rules that flow from it." FR: "Commencez par la source du pouvoir juridique avant d'examiner les règles de radiocommunication plus détaillées qui en découlent." L2 EN: "The framework has layers: an Act gives legal authority; regulations are binding rules made under that authority; departmental standards are technical operating documents; the department administers the system." FR: "Le cadre s'organise en niveaux : une loi confère l'autorité juridique; les règlements sont des règles obligatoires prises sous cette autorité; les normes ministérielles sont des documents techniques d'exploitation; le ministère administre l'ensemble."
- B-001-001-002 L1 EN: "Focus on the authority behind a technical operating document, not on the document's title." FR: "Concentrez-vous sur l'autorité qui permet d'établir une norme technique d'exploitation, et non sur son titre." L2 same distinctions text and lesson link as above.
- B-001-001-003 L1 EN: "Classify the role first: this asks for the civilian federal organization that runs the radio-rule framework." FR: "Classez d'abord le rôle : on cherche l'organisation fédérale civile qui administre le cadre des règles radio." L2 same distinctions text and lesson link as above.
- B-001-001-004 L1 EN: "Sort the fact by function: legal authority, binding categories, technical operating instructions, or the administering organization." FR: "Pour les définitions précises, triez le fait selon sa fonction : autorité juridique, catégories obligatoires, consignes techniques d'exploitation ou organisation responsable de l'administration." L2 same distinctions text and lesson link as above.

Validation after rewrite: pnpm typecheck; pnpm test; pnpm check:hints:self-test; pnpm check:hints -- --subsection B-001-001 --require-complete; pnpm check:schemas; pnpm import:check; pnpm --filter @canadian-ham/content-tools check:lesson-originality; pnpm --filter @canadian-ham/content-tools check:lesson-originality:all.

Superseded note: the earlier note saying the owner was still deciding recall-question ladders is obsolete. The owner ruling of 2026-10-16 now applies: A+C by default, with B single-level allowed when a second level would leak the answer. The current pilot uses two levels for B-001-001-001/002 and one level with singleLevelReason for B-001-001-003/004.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote and review-updated the B-001-001 pilot hint files, EN and FR, under the 2026-10-16 owner recall-ladder ruling. The final pilot uses two-level ladders that teach Act/regulation/departmental-standard/department distinctions without option elimination, adds lessonLink to L-001-01#how-these-rules-fit-together, and verifies with hint, schema, import, originality, typecheck, and test checks.
<!-- SECTION:FINAL_SUMMARY:END -->
