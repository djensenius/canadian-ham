---
id: TASK-46.11
title: 'Decision: declare cross-module prerequisites in lesson front matter'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-12 22:23'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: low
ordinal: 109000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Owner decision recorded
- [ ] #2 Every lesson lists its real cross-module prerequisites; the apps show them; a checker validates they exist
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory existing lesson front matter and parser/checker/web paths.
2. Add prerequisite metadata to lessons only where needed, preserving recommended order and no Apple app edits.
3. Extend content tooling/tests to validate prerequisite existence, acyclicity, and ordering.
4. Render prerequisites on the web lesson page with localized EN/FR accessible links.
5. Update lesson README and teaching guide rules, run requested checks, record reasoning/results in Backlog, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Declare cross-module prerequisites in lesson front matter (teaching-guide front-matter freeze lifted for this field).
<!-- SECTION:NOTES:END -->
