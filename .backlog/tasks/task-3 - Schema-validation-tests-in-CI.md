---
id: TASK-3
title: Schema validation tests in CI
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 21:59'
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
- [ ] #1 Valid and invalid synthetic fixtures are tested
- [ ] #2 The committed generated bank, explanations and lesson front matter validate
- [ ] #3 The tests run in the GitHub Actions CI workflow
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add @canadian-ham/schemas as a workspace package with a schema validation/test script and root helper. 2. Add small valid/invalid schema fixture coverage under packages/schemas/test/fixtures plus node:test checks, including generated-bank tightened-rule negatives and progress export produced by ProgressStore.exportData. 3. Tighten generated-bank schemas to match the Basic importer output contract where expressible by the local validator. 4. Add schema checks to the CI full-check path while preserving the .backlog-only fast path. 5. Run the requested install, typecheck, tests, schema check, link check, and actionlint validations before finalizing task-3.
<!-- SECTION:PLAN:END -->
