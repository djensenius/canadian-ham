---
id: TASK-3
title: Schema validation tests in CI
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 22:24'
labels:
  - content
  - ci
  - 'legacy:T-004'
milestone: m-0
dependencies:
  - TASK-2
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Schemas only protect us if something runs them. Validating the committed generated bank, explanations, lesson front matter and progress-export samples on every push catches drift before it reaches either app, and synthetic invalid fixtures prove the schemas actually reject bad data. Legacy: T-004.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Valid and invalid synthetic fixtures are tested
- [x] #2 The committed generated bank, explanations and lesson front matter validate
- [x] #3 The tests run in the GitHub Actions CI workflow
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add @canadian-ham/schemas as a workspace package with a schema validation/test script and root helper. 2. Add small valid/invalid schema fixture coverage under packages/schemas/test/fixtures plus node:test checks, including generated-bank tightened-rule negatives and progress export produced by ProgressStore.exportData. 3. Tighten generated-bank schemas to match the Basic importer output contract where expressible by the local validator. 4. Add schema checks to the CI full-check path while preserving the .backlog-only fast path. 5. Run the requested install, typecheck, tests, schema check, link check, and actionlint validations before finalizing task-3.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented @canadian-ham/schemas workspace tests with small valid/invalid fixtures for shared/common definitions and every data schema; tightened Basic generated-bank schemas for active-bank IDs, manifest constants/counts, category counts, question answer/sourceOrder contracts, and subsection importer-only fields. Validation evidence: pnpm check:schemas passed with 32 schema tests and reported Schema validation passed: 1042 validation target(s); pnpm install --frozen-lockfile, pnpm typecheck, pnpm test, pnpm check:links, and go run github.com/rhysd/actionlint/cmd/actionlint@latest all passed.

Addressed Copilot PR #62 comments 4161106062 and 4161106116: generated-bank categories now validate the importer-sorted B-001 through B-008 order with prefixItems/items:false, duplicate/reordered category fixtures were added, and the schema README now documents all supported keywords plus CI job/step coverage. Validation: pnpm check:schemas, pnpm test, pnpm typecheck, pnpm check:links, and git diff --check passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added schema fixture tests and CI wiring for packages/schemas, tightened generated-bank schemas against the Basic importer output contract, and verified committed generated content plus progress exports with pnpm check:schemas (32 tests, 1042 validation targets), pnpm typecheck, pnpm test, pnpm check:links, and actionlint.
<!-- SECTION:FINAL_SUMMARY:END -->
