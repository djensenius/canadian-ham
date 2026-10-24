---
id: TASK-46.7
title: Interleaved review items in lesson quizzes
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-24 22:36'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect recommended order, quiz session/rounds and attempt import/sync/migration seams; preserve mock exams and existing audit helpers. 2. Implement pure deterministic earlier-lesson review selection in TS/Swift with shared parity fixtures. 3. Add optional validated reviewQuestionIds to web/Apple attempts, schema, sync/import and lesson-ID migration with backward compatibility. 4. Integrate accessible EN/FR review headers, source-lesson hints, scoring/progress and final M1 Review round on web and Apple. 5. Add engine, schema, web axe/round/resume and targeted Apple unit/UI regression coverage; obtain audit composite scope approval before new calls. 6. Commit before nohup checks; poll grep logs for requested iPhone/iPad targeted tests, full macOS units, parity, web/schema/import/localization/text/test guard checks; record evidence and finalize/push without PR.
<!-- SECTION:PLAN:END -->
