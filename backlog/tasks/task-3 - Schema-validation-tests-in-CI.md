---
id: TASK-3
title: Schema validation tests in CI
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
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
Validate the real generated data and small synthetic fixtures against the JSON Schemas, with zero runtime dependencies (Node test runner), and run them in CI. Legacy: T-004.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Valid and invalid synthetic fixtures are tested
- [ ] #2 The committed generated bank, explanations and lesson front matter validate
- [ ] #3 The tests run in the GitHub Actions CI workflow
<!-- AC:END -->
