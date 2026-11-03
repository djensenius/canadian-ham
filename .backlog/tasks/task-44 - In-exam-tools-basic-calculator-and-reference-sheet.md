---
id: TASK-44
title: 'In-exam tools: basic calculator and reference sheet'
status: Done
assignee: []
created_date: 2026-10-12 14:38
updated_date: '2026-10-26T13:26:00Z'
labels:
  - web
  - apple
dependencies: []
priority: medium
ordinal: 93000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-10-12: mock exams and practice offer a basic calculator (no formula or text storage, like the exam allows) and the reference sheet, while the question and answers stay visible and usable on every device: iPhone bottom sheet with detents and background interaction; iPad and Mac side panel (inspector), falling back to a sheet in compact width; web side panel on wide screens and a bottom drawer on narrow ones, non-modal with no focus trap. Mock exam timer keeps running. tvOS/visionOS excluded (no mock exams).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All subtasks Done
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Task-43 review follow-up: when the in-app exam tools ship, update the L-001-01 app-practice wording and the Learn Exam day copy so they describe the new calculator/reference-sheet tools accurately instead of only physical/practice conditions.

All subtasks Done: 44.1 calculator engine, 44.2 web tools, 44.3 Apple tools (#2xx), 44.4 official sheet in internal builds (#331), 44.5 official sheet in Apple mock exams (#1019). The iPad mock audit limitation is tracked separately in TASK-74.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
In-exam tools ship on web and Apple: a basic calculator with a shared TS/Swift engine and fixtures, and a reference sheet. The official ISED sheet is internal-build only until permission. The iPad mock-exam audit follow-up is TASK-74.
<!-- SECTION:FINAL_SUMMARY:END -->
