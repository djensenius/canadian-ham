---
id: TASK-2
title: JSON Schemas for content and progress types
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 16:55'
labels:
  - content
  - 'legacy:T-003'
milestone: m-0
dependencies: []
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Content and progress data cross several boundaries: the ISED importer writes generated JSON, lessons and explanations are hand-written, and the web and Apple apps exchange progress through a shared export format. Today only scattered TypeScript types and ad-hoc checks guard those shapes, so a drifting field (e.g. an importer change or an export change on one platform) can break the other side silently. Explicit JSON Schemas give one contract that both platforms and the content tools can validate against. Legacy: T-003.
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
