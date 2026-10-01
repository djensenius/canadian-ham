---
id: TASK-2
title: JSON Schemas for content and progress types
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - content
  - 'legacy:T-003'
milestone: m-0
dependencies: []
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Define initial JSON Schemas for Question, Category, Subsection, Lesson front matter, Explanation, ExamAttempt, QuestionProgress and EngineFixture, matching the generated data and the TypeScript types. Put them in packages/schemas. Legacy: T-003.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Schemas exist in packages/schemas for every listed type
- [ ] #2 The schemas match the current generated bank JSON, the lesson front matter, the explanation JSON and the progress export format
- [ ] #3 The schemas are documented in packages/schemas/README.md
<!-- AC:END -->
