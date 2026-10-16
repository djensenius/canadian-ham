---
id: TASK-50.2
title: Pilot hints for B-001 subsection 001
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 08:04'
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

Sample EN/FR hint pairs for owner tone review:
1. B-001-001-001 L1 EN: Think about the highest legal layer. A federal statute gives Canada the authority to create detailed radio rules. / FR: Pensez au niveau juridique le plus élevé. Une loi fédérale donne au Canada le pouvoir de créer des règles radio détaillées.
2. B-001-001-001 L2 EN: Set aside broadcasting, international coordination, and day-to-day amateur station operation. Choose the broad Canadian law those lower rules sit under. / FR: Écartez la radiodiffusion, la coordination internationale et l'exploitation quotidienne des stations radioamateurs. Cherchez la grande loi canadienne placée au-dessus de ces règles.
3. B-001-001-002 L1 EN: Use the same hierarchy as for making radio rules. Operating standards can be published because a higher federal statute delegates that power. / FR: Utilisez la même hiérarchie que pour établir des règles radio. Les normes d'exploitation peuvent être publiées parce qu'une loi fédérale supérieure délègue ce pouvoir.
4. B-001-001-003 L1 EN: Think of the civilian spectrum manager: the federal department that handles radio licensing, call signs, and compliance. / FR: Pensez au gestionnaire civil du spectre : le ministère fédéral qui s'occupe des licences radio, des indicatifs d'appel et de la conformité.
5. B-001-001-004 L2 EN: Set aside the enabling law, station-operation standards, and policy documents. The definition comes from the detailed rulebook for Canadian radio services. / FR: Écartez la loi habilitante, les normes d'exploitation des stations et les documents de politique. La définition vient du recueil de règles détaillées pour les services radio canadiens.

Validation passed for task-50.2: pnpm check:hints -- --subsection B-001-001 --require-complete; pnpm check:hints; pnpm check:schemas; pnpm --dir packages/content-tools check:explanations; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm import:check; pnpm install --frozen-lockfile; pnpm typecheck; pnpm test; pnpm check:hints:self-test. Initial pnpm typecheck failed before workspace dev dependencies were installed (tsc not found), then passed after pnpm install --frozen-lockfile.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote the B-001-001 pilot hint files, EN and FR, using the two-step nudge/setup ladder and no embedded answer/option/reference-sheet text. Verified pilot completeness and leakage with the hint checker, and reran schema, import, explanation, originality, typecheck, and test suites.
<!-- SECTION:FINAL_SUMMARY:END -->
