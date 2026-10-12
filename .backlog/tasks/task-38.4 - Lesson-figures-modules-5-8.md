---
id: TASK-38.4
title: 'Lesson figures: modules 5-8'
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
ordinal: 82000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Draw the remaining Illustration brief figures for lessons in m5-basic-electronics, m6-feedlines-antennas, m7-propagation and m8-interference-suppression (except those covered by task-38.1/38.2).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every brief in modules 5-8 not covered by task-38.1/38.2 has a drawn figure referenced from its lesson
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add one original SVG and ::figure reference for each in-scope module 5-8 illustration brief, leaving excluded task-38.1/38.2 lessons untouched.\n2. Verify figure labels, clearances, and technical values against lesson text and content/generated/basic-2025-07-15/questions.json.\n3. Regenerate Apple figure assets/metadata with pnpm check:figures:fix, render every SVG with qlmanage into docs/evidence/task-38.4/, inspect thumbnails, then run figure, content, web, and content-swift checks.\n4. Record per-figure notes and leave Apple xbuild validation acceptance unchecked per lane instructions.
<!-- SECTION:PLAN:END -->
