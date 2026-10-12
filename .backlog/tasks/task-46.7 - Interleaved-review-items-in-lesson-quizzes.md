---
id: TASK-46.7
title: Interleaved review items in lesson quizzes
status: To Do
assignee: []
created_date: '2026-10-12 14:57'
labels:
  - web
  - apple
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 105000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Lesson quizzes reuse no earlier material. Add 1-2 review items per lesson quiz drawn from earlier lessons in the recommended order (data-driven, in both the web and Swift engines, with shared fixtures), clearly marked as review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each lesson quiz after the first includes 1-2 review items from earlier lessons, deterministic per attempt seed
- [ ] #2 TS and Swift engines agree on shared fixtures; the UI marks review items accessibly
<!-- AC:END -->
