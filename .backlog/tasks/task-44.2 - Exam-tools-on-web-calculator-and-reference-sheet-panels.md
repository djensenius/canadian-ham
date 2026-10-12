---
id: TASK-44.2
title: Exam tools on web (calculator and reference sheet panels)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:39'
updated_date: '2026-10-12 15:48'
labels:
  - web
dependencies:
  - TASK-44.1
parent_task_id: TASK-44
priority: medium
ordinal: 95000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Web UI for the calculator and reference sheet in practice and mock exams: a side panel on wide screens, a bottom drawer on narrow ones; non-modal, so the question and answer choices stay visible and operable; keyboard input for the calculator; screen-reader labels and a live-region result; EN/FR. The reference sheet source (official ISED sheet or the original study sheet) is pluggable per the owner's decision on licensing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Question and answers remain visible and operable with either tool open at 320 px, tablet and desktop widths (tests)
- [ ] #2 Calculator fully keyboard-operable with screen-reader announcements; axe passes with the panels open in light and dark
- [ ] #3 The mock exam timer is unaffected; tools are available in practice and mock exams
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator: this lane owns content/reference-sheet/ (an original interim formula sheet, swappable for the official ISED sheet once the owner decides on licensing).
<!-- SECTION:NOTES:END -->
