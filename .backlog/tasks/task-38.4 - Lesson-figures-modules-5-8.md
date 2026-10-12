---
id: TASK-38.4
title: 'Lesson figures: modules 5-8'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:34'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Figures added in first slice: L-005-05 transformer-resonance-meters shows primary/secondary transformer flux coupling, parallel LC high impedance at resonance, voltmeter across load and ammeter in series; verified against B-005-011-001..011, B-005-012-001..011, B-005-013-001..010 and lesson values 240 V/360 W/1.5 A, 240 V x 0.3 A = 72 W, 36 V secondary, 300 mA step-up example. L-006-01 feedline-types-balun shows coax shield/centre conductor as unbalanced, window/open-wire balanced lines, and balun at dipole feed point; verified against B-006-001-001..011, B-006-002-001..011, B-006-003-001..011 including 50-ohm amateur coax and 75-ohm TV coax lesson contrast. L-006-02 swr-loss-matching shows forward/reflected waves, line loss reducing returned reflection, and feed-point matching; verified against B-006-004-001..010, B-006-005-001..011, B-006-006-001..011 including SWR estimates 1.5:1=4%, 2:1≈11%, 3:1=25% and 240/60=4:1 lesson example.
<!-- SECTION:NOTES:END -->
