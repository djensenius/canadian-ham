---
id: TASK-50.1
title: 'Hint content schema, loader and checker'
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
labels:
  - content
dependencies: []
references:
  - content/explanations
  - packages/content-tools/src/check-explanations.ts
  - packages/schemas/explanation.schema.json
documentation:
  - docs/teaching-guide.md
  - docs/content-licensing.md
parent_task_id: TASK-50
priority: high
type: task
ordinal: 115000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Define the durable content contract for per-question Basic hints before large-scale hint writing. The checker must enforce original EN/FR two-step hints, answer-leak prevention, reference-sheet pointer handling, and completeness rules while fitting the existing schema/content-tools/CI patterns used by explanations.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A JSON schema and schema fixtures validate hint files with id, questionId, bankId, status, exactly two localized hint levels, optional referenceSheetSection, and licenseClass original.
- [ ] #2 A TypeScript loader exposes hint records from content/hints with stable sorting and question-id lookup for apps/tools.
- [ ] #3 A content-tools checker validates structure, active Basic question references, EN/FR completeness, no answer/option/question leakage with normalized matching, reference-sheet pointer rules, and original-content separation.
- [ ] #4 The checker includes a self-test covering valid hints, leakage failures, missing EN/FR, invalid reference pointers, and n-gram false-positive tuning for common numbers/units.
- [ ] #5 The new checker is wired into package scripts and CI alongside explanations and schema checks.
<!-- AC:END -->
