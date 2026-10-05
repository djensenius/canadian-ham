---
id: TASK-11.12
title: 'Apple import: restoring the same export again works'
status: To Do
assignee: []
created_date: '2026-10-05 13:33'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: medium
ordinal: 65000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: ProgressModels marks questionId and attempt id as @Attribute(.unique). Since task-11.5, Apple import deletes the imported bank's records and reinserts them in one save. Re-importing the same export (the usual 'restore backup' case) has no test and could hit a uniqueness conflict. Found in the task-11.5 review (~/.cache/canadian-ham-reviews/t115-r2.md).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A unit test exports progress, then imports that same file twice; progress, exam attempts and lesson data are identical afterwards
- [ ] #2 Any uniqueness conflict found is fixed; the macOS and iOS suites pass
<!-- AC:END -->
