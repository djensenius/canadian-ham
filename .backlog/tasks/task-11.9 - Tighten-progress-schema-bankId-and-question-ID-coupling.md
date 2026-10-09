---
id: TASK-11.9
title: Tighten progress schema bankId and question-ID coupling
status: Done
assignee:
  - '@worker'
created_date: '2026-10-02 14:00'
updated_date: '2026-10-09 06:00'
labels:
  - schemas
  - content
  - web
  - apple
milestone: m-1
dependencies: []
parent_task_id: TASK-11
type: task
ordinal: 55000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Review note 7 from task-11.3 found that common/progress schemas now accept Basic and Advanced bank IDs side by side, so a Basic bankId with A-prefixed question IDs can pass schema validation even though app import validation catches it. This is acceptable for task-11.3 but should be tightened when multi-bank schemas mature.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Progress/common schema validation rejects mismatched bankId and question-ID prefixes, or documents and enforces an equivalent per-bank schema split.
- [x] #2 Valid Basic legacy exports without bankId still validate and import after the schema tightening.
- [x] #3 Schema fixtures include both valid per-bank exports and invalid mixed-prefix examples.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Tighten progress/common JSON schemas with per-bank question-id coupling while preserving legacy Basic exports without bankId.\n2. Add valid Basic/Advanced and invalid mixed-prefix fixtures plus import/normalization coverage.\n3. Run schema/import checks and record evidence before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Tightened schema bank/question coupling with per-bank defs in packages/schemas/common.schema.json:15 and progress export oneOf branches in packages/schemas/progress-export-v1.schema.json:32. Added valid Advanced fixture packages/schemas/test/fixtures/valid/progress-export-v1-advanced.json and invalid mixed-prefix fixtures packages/schemas/test/fixtures/invalid/progress-export-v1-mixed-basic-bank-advanced-question.json plus progress-export-v1-mixed-advanced-bank-basic-exam.json. Regression tests live in packages/schemas/validate-fixtures.test.mjs:67 and packages/schemas/validate-negative.test.mjs:38. Legacy Basic import normalization remains covered in apps/web/src/lib/progressStore.test.ts:364. Validation: pnpm --filter @canadian-ham/schemas test; pnpm --filter @canadian-ham/web test -- src/lib/progressStore.test.ts --runInBand; pnpm typecheck; pnpm test; pnpm import:check; pnpm build:web; URL/CSP audit.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added per-bank JSON schema branches for progress exports/records/attempts so Basic/Advanced question prefixes cannot mix, while preserving legacy Basic exports without bankId. Added valid Advanced and invalid mixed-prefix fixtures and verified schemas plus web import normalization.
<!-- SECTION:FINAL_SUMMARY:END -->
