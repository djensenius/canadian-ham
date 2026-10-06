---
id: TASK-11.14
title: >-
  Course-switch warning: regression tests for answered practice and review
  sessions
status: To Do
assignee: []
created_date: '2026-10-06 03:22'
labels: []
dependencies:
  - TASK-11.13
parent_task_id: TASK-11
priority: low
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: PR #142 (task-11.13) tests the course-switch warning for mock exams and unanswered practice only. Copilot asked for coverage of the answered-practice paths on web and Apple.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web tests: partially answered immediate practice and fully answered but unsubmitted review-later practice both prompt; Cancel keeps the answers; Confirm discards the session; a submitted review session does not prompt
- [ ] #2 Apple UI tests cover the same cases on iOS (targeted runs plus the policy's full runs)
<!-- AC:END -->
