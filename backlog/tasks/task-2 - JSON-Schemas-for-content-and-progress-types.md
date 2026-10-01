---
id: TASK-2
title: JSON Schemas for content and progress types
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 02:34'
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
