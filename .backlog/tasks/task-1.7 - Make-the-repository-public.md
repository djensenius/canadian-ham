---
id: TASK-1.7
title: Make the repository public
status: To Do
assignee: []
created_date: 2026-10-01 02:27
updated_date: '2026-11-03T02:54:00Z'
labels:
  - release
  - legacy:T-009
  - owner-gate
milestone: m-0
dependencies:
  - TASK-1.1
  - TASK-1.6
  - TASK-1.8
parent_task_id: TASK-1
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Only after the ISED permission is recorded and the release candidate pass is complete, make djensenius/canadian-ham public. Legacy: T-009.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The ISED permission is recorded
- [ ] #2 The release candidate pass is Done
- [ ] #3 The owner has approved making the repository public
- [ ] #4 The repository visibility is public
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator 2026-11-03 (TASK-83 tracking pass): GitHub already reports djensenius/canadian-ham as public (isPrivate false), but TASK-1.1 still records the ISED permission as pending and TASK-1.8 (history purge) is not done. The owner needs to reconcile this: either record the permission and the decision to publish early, or return the repository to private until the gates pass. Agents must not change visibility.

TASK-87 2026-11-03: owner steps and evidence format for this task are indexed in docs/release/owner-gates.md (Sitting 1: owner decisions; repository already public while TASK-1.1 is pending). The guide restates and links these criteria without changing them.
<!-- SECTION:NOTES:END -->
