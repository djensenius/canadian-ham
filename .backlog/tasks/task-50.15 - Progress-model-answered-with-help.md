---
id: TASK-50.15
title: 'Progress model: answered with help'
status: To Do
assignee: []
created_date: '2026-10-16 08:12'
updated_date: '2026-10-16 08:30'
labels:
  - engine
dependencies: []
parent_task_id: TASK-50
priority: high
type: task
ordinal: 129000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Question hints need a durable progress state before UI work records hinted answers. The model must represent answered-with-help consistently across TypeScript and Swift engines, parity fixtures, progress/export schemas, sync device rows, and import compatibility so web and Apple UI tasks do not each invent separate semantics.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 engine-ts and engine-swift store answered with help as a flag alongside correct/incorrect outcomes, preserving accuracy stats while withholding mastery credit and weak-area clearing
- [ ] #2 Shared parity fixtures cover hinted-answer scheduling and sooner spaced-review return behaviour
- [ ] #3 common progress schema, progress export schema, sync device rows, and import compatibility accept and preserve the answered-with-help state
- [ ] #4 Migration/backward-compatibility tests cover older progress exports or device rows that do not contain the new state
<!-- AC:END -->
