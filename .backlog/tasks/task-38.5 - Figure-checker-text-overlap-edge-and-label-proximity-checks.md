---
id: TASK-38.5
title: 'Figure checker: text overlap, edge and label-proximity checks'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 15:42'
updated_date: '2026-10-12 15:42'
labels:
  - content
dependencies: []
parent_task_id: TASK-38
priority: high
ordinal: 91000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two drawing lanes repeatedly shipped figures with overlapping labels, labels running into strokes, or text past the viewBox edge, because scripts/check-figures.mjs only checks text size and stroke-touching-text. Add conservative checks so these are caught mechanically.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 check-figures fails on text-text bbox overlap or a gap under a threshold, using a conservative width estimate (CoreSVG uses a wider proportional font)
- [ ] #2 check-figures fails on text extending past the viewBox and reports text whose bbox intersects any stroke segment
- [ ] #3 Self-test covers each new rule; all figures on main and task-38.1 pass or the failures are listed
<!-- AC:END -->
