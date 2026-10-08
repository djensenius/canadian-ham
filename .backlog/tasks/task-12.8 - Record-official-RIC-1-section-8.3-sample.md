---
id: TASK-12.8
title: Record official RIC-1 section 8.3 sample
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 13:58'
updated_date: '2026-10-08 12:09'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 54000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Task-12.2 uses a synthetic stand-in to exercise RIC-1 section 8.3 weighted-character counting because the official sample text was not recorded in the repo. Future Morse grading and exam work should pin the official sample so fixtures match the source regulation instead of an invented sentence.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The official RIC-1 section 8.3 sample text and source citation are recorded in the repository
- [ ] #2 The synthetic stand-in weighting fixture is replaced or supplemented by an official-sample fixture with the expected weighted count
- [ ] #3 TypeScript and Swift Morse tests pass against the official-sample fixture
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an official RIC-1/CIR-1 §8.3 Morse sample fixture with source citations exactly as audited, keeping official text separate from original content.\n2. Wire the fixture into TypeScript and Swift Morse fixture tests and assert the audited weighted count.\n3. Run targeted Morse package tests, then finalize the task with file:line evidence and audited source notes.
<!-- SECTION:PLAN:END -->
