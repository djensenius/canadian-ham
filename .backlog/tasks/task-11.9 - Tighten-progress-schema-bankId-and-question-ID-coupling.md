---
id: TASK-11.9
title: Tighten progress schema bankId and question-ID coupling
status: To Do
assignee: []
created_date: '2026-10-02 14:00'
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
- [ ] #1 Progress/common schema validation rejects mismatched bankId and question-ID prefixes, or documents and enforces an equivalent per-bank schema split.
- [ ] #2 Valid Basic legacy exports without bankId still validate and import after the schema tightening.
- [ ] #3 Schema fixtures include both valid per-bank exports and invalid mixed-prefix examples.
<!-- AC:END -->
