---
id: TASK-12.17
title: Run Morse course accessibility audits on the real layout
status: To Do
assignee: []
created_date: '2026-10-04 13:22'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The current Morse course accessibility audit path uses the -CanadianHamMorseCourseAuditOnly launch argument to trim the Morse screen to course content. That kept the audit focused while the course shipped, but it means course audits do not exercise the real Morse section layout and surrounding content.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Morse course path, lesson, and summary accessibility audits launch the normal Morse section layout without -CanadianHamMorseCourseAuditOnly
- [ ] #2 The audits still reach the course path, first lesson, and summary deterministically in light and dark without handlers or audit filters
- [ ] #3 Regression tests or UI-test helpers are updated so the real-layout course audit remains stable
<!-- AC:END -->
