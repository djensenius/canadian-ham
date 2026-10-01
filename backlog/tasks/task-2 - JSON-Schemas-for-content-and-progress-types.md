---
id: TASK-2
title: JSON Schemas for content and progress types
status: In Progress
assignee:
  - '@pi-coordinator'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 02:31'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory the existing TS types and generated JSON shapes (questions, categories, subsections, lessons front matter, explanations, progress export, engine fixtures).
2. Write JSON Schema (draft 2020-12) files in packages/schemas/.
3. Validate the real data against them with a zero-dependency check (follow-up task-3 adds CI tests).
4. Document in packages/schemas/README.md.
<!-- SECTION:PLAN:END -->
