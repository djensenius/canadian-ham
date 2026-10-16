---
id: TASK-50.1
title: 'Hint content schema, loader and checker'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 11:50'
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
- [x] #1 A JSON schema and schema fixtures validate hint files with id, questionId, bankId, status, exactly two localized hint levels, optional referenceSheetSection, and licenseClass original.
- [x] #2 A TypeScript loader exposes hint records from content/hints with stable sorting and question-id lookup for apps/tools.
- [x] #3 A content-tools checker validates structure, active Basic question references, EN/FR completeness, no answer/option/question leakage with normalized matching, reference-sheet pointer rules, and original-content separation.
- [x] #4 The checker includes a self-test covering valid hints, leakage failures, missing EN/FR, invalid reference pointers, and n-gram false-positive tuning for common numbers/units.
- [x] #5 The new checker is wired into package scripts and CI alongside explanations and schema checks.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror explanations with content/hints/<category>/<questionId>.json and add hint.schema.json plus valid/invalid fixtures/schema validation wiring.
2. Add a shared TypeScript hint loader under packages/content-tools/src with stable ordering and lookup helpers over content/hints.
3. Add check-hints.ts with structure, active Basic references, EN/FR completeness, reference-section allowlist, normalized answer/option/question-fragment leakage checks, and a --self-test.
4. Wire check:hints into package scripts and CI, then validate with focused tests/checks before writing pilot content.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented content/hints layout and README, hint.schema.json with fixtures/schema validation, packages/content-tools/src/hints.ts loader, check-hints.ts with --self-test, and CI/package script wiring. Leakage tuning uses exact meaningful answer/option phrase matching plus six-token significant question n-grams after dropping low-information numbers/units to reduce false positives.

Validation passed for task-50.1: pnpm --filter @canadian-ham/content-tools typecheck; pnpm --filter @canadian-ham/content-tools test (125 tests); pnpm check:hints:self-test; pnpm check:hints; pnpm check:schemas.

Review follow-up after the 2026-10-16 recall-ladder ruling: hint.schema.json, the TypeScript loader, and check-hints now allow one or two hint levels; one-level files require singleLevelReason; every hint file requires lessonLink; check-hints validates the lesson ID and optional sectionAnchor against content/lessons heading anchors.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented and review-updated the Basic question-hint content contract: schema/fixtures, TypeScript loader, check-hints checker/self-test with leakage, reference pointer, one-or-two-level, singleLevelReason, and lessonLink validation, plus CI/script wiring. Verified with content-tools tests/typecheck, hint self-test/checker, schema tests, import checks, and lesson originality checks.
<!-- SECTION:FINAL_SUMMARY:END -->
