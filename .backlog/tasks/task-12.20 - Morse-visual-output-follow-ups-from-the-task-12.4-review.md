---
id: TASK-12.20
title: 'Morse visual output: follow-ups from the task-12.4 review'
status: To Do
assignee: []
created_date: '2026-10-07 12:14'
labels: []
dependencies:
  - TASK-12.4
parent_task_id: TASK-12
priority: low
ordinal: 70000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-12.4's final review (~/.cache/canadian-ham-reviews/t124-r3.md) approved with notes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 After the UI-test scroll-settling helper runs, each lower-half audit asserts its target (sending feedback, Morse settings, last course unit) is still visible below the bar
- [ ] #2 Remove the unreachable luminance-too-high reason (TS and Swift) or document it; add a Swift test at exactly the area cap
- [ ] #3 Safety-note areas say square points / px² with grouped digits; the web unlit lamp sits on paper (not paper-inset) like Apple
<!-- AC:END -->
