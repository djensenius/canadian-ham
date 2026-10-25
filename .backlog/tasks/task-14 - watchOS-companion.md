---
id: TASK-14
title: watchOS companion
status: In Progress
assignee:
  - '@worker'
created_date: 2026-10-01 02:27
updated_date: '2026-10-25T16:58:00Z'
labels:
  - apple
  - legacy:T-703
milestone: m-1
dependencies: []
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Investigate a watchOS companion only after the Apple v1 privacy posture is stable. Legacy: T-703.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A short proposal covers the use cases, the data model and how the companion stays offline and data-free
- [ ] #2 The owner has decided whether to build it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Apple targets, practice/Morse code, package manifests, content sizes, release configuration, and installed watchOS simulator runtime.
2. Write the scoped offline watchOS proposal and create six dependent implementation subtasks through Backlog.
3. Validate the proposal and task graph, record the owner decision and AC evidence, complete TASK-14, commit and push this branch without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-25: yes, build the watchOS companion ("go ahead and get started on watch"). This lane completes the proposal and implementation-task breakdown only; the app itself will be built in the subtasks.
<!-- SECTION:NOTES:END -->
