---
id: TASK-3
title: Schema validation tests in CI
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 21:58'
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
