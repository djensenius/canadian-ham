---
id: TASK-38.3
title: 'Lesson figures: modules 1-4'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:31'
labels:
  - content
  - apple
  - web
dependencies:
  - TASK-38.1
parent_task_id: TASK-38
priority: low
ordinal: 81000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Draw the remaining Illustration brief figures for lessons in m1-regulations-policies, m2-operating-procedures, m3-station-practice-safety and m4-circuit-components (except those covered by task-38.2), following each brief's alt text and description.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every brief in modules 1-4 not covered by task-38.2 has a drawn figure referenced from its lesson
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory module 1-4 illustration briefs and choose one stable figure id per lesson, excluding L-004-03.\n2. Draw simple original currentColor SVGs with generous text clearance, add matching ::figure directives and text equivalents where dense.\n3. Regenerate figure assets/metadata with pnpm check:figures:fix, render every figure with qlmanage into docs/evidence/task-38.3/, inspect previews, and iterate.\n4. Run figure/content/web/Swift content checks; record per-figure evidence and leave Apple app xbuild validation unchecked for the later integration lane.
<!-- SECTION:PLAN:END -->
